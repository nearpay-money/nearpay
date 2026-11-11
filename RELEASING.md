# Releasing NearPay's public npm packages

NearPay's public SDK packages are published to the public npm registry under the scope **`@nearpay-money`**
(ADR-0025). The `@nearpay` scope on npm belongs to an unrelated company: never publish there.
Internal packages (`@nearpay-internal/*`) are never published to npm.

| Repository         | Packages (published in this order)                                          | First tag |
| ------------------ | --------------------------------------------------------------------------- | --------- |
| `nearpay-spec`     | `@nearpay-money/spec`                                                        | `v0.5.0`  |
| `nearpay-node`     | `@nearpay-money/node`                                                        | `v0.4.0`  |
| `nearpay-js`       | `@nearpay-money/js`, `@nearpay-money/react`                                  | `v0.2.0`  |
| `nearpay-agentkit` | `@nearpay-money/agent-signer`, `@nearpay-money/x402`, `@nearpay-money/mcp` (bin `nearpay-mcp`) | `v0.3.0`  |
| `nearpay-cli`      | `@nearpay-money/cli` (bin `nearpay`)                                         | `v0.2.0`  |

**Order matters:** every package depends on `@nearpay-money/spec`, so `nearpay-spec` goes first. `@nearpay-money/react`
depends on `@nearpay-money/js` and `@nearpay-money/mcp` / `x402` on `agent-signer`; each repository's workflow
publishes its own packages in that order. After spec, the order node → js → agentkit → cli is the safe default.

Each publishing repository has `.github/workflows/release.yml`. A release is one tag push: the workflow installs,
runs `pnpm verify`, then `scripts/publish-npm.sh` packs and publishes. It is idempotent (a version already on npm is
skipped), refuses anything that is not a non-private `@nearpay-money/*` package, checks that the tag equals the
package version, and adds npm provenance only when the repository is public (all are private today, so no provenance
yet; it switches on by itself when a repository is made public).

How CI installs dependencies: GitHub's runners cannot reach NearPay's private registry, so the workflow (except
spec's, which only needs public packages) checks out `nearpay-deploy`, starts a throwaway Verdaccio on
`127.0.0.1:4873` inside the job and seeds it byte for byte from `nearpay-deploy/registry-seed`. The repositories'
`.npmrc` already route `@nearpay-money/*` and `@nearpay-internal/*` there, and the lockfiles match the seed exactly.

## One-time setup (owner)

### 1. Create the npm organisation

1. Sign in at https://www.npmjs.com (enable two-factor authentication on the account if it is not on yet).
2. Avatar menu → **Add Organization** → name **`nearpay-money`** → plan **Unlimited public packages (free)** → Create.
   The scope `@nearpay-money` now belongs to you.

### 2. Create the npm token (granular, publish-only, limited to `@nearpay-money`)

1. Avatar menu → **Access Tokens** → **Generate New Token** → **Granular Access Token**.
2. Token name: `nearpay-money-github-release`; Expiration: your choice (e.g. 90 days; renew before it expires).
3. **Bypass two-factor authentication (2FA):** tick it (CI cannot enter a one-time code).
4. **Packages and scopes** → Permissions **Read and write** → **Only select packages and scopes** → select the scope
   **`@nearpay-money`**. (Selecting the scope covers new packages in it, so the first publish works.)
5. **Organizations:** No access. Allowed IP ranges: leave empty.
6. Generate and copy the token (`npm_…`). It is shown once.

### 3. Create a read-only GitHub token for the registry seed

The release jobs of nearpay-node, nearpay-js, nearpay-agentkit and nearpay-cli read `nearpay-deploy/registry-seed`
(a private repository), so they need one more secret.

1. GitHub → avatar → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** →
   **Generate new token**.
2. Name `nearpay-release-seed-read`; Resource owner **nearpay-money**; Expiration: your choice.
3. Repository access: **Only select repositories** → **nearpay-deploy**.
4. Permissions → Repository permissions → **Contents: Read-only** (Metadata: Read-only is added automatically).
5. Generate and copy the token (`github_pat_…`). If the organisation requires approval for fine-grained tokens,
   approve it under nearpay-money → Settings → Personal access tokens → Pending requests.

### 4. Add the secrets to the five repositories

With the GitHub CLI (each command prompts for the value; paste the token):

```sh
for r in nearpay-spec nearpay-node nearpay-js nearpay-agentkit nearpay-cli; do
  gh secret set NPM_TOKEN --repo "nearpay-money/$r"
done
for r in nearpay-node nearpay-js nearpay-agentkit nearpay-cli; do
  gh secret set NP_DEPLOY_READ_TOKEN --repo "nearpay-money/$r"
done
```

Or in the browser: each repository → Settings → Secrets and variables → Actions → **New repository secret**.
Organisation-level secrets (nearpay-money → Settings → Secrets and variables → Actions, "Selected repositories")
work too on a paid GitHub plan; on GitHub Free, organisation secrets are only available to public repositories, so
use the per-repository secrets above.

## Release (every time)

Prerequisites: the release changes are merged to `main` in every repository, and `nearpay-deploy/registry-seed`
on `main` contains the versions the lockfiles use (it does for this release).

Optional rehearsal without publishing (packs and runs `npm publish --dry-run`):

```sh
gh workflow run release.yml --repo nearpay-money/nearpay-spec -f dry_run=true
gh run watch --repo nearpay-money/nearpay-spec "$(gh run list --repo nearpay-money/nearpay-spec --workflow release.yml --limit 1 --json databaseId -q '.[0].databaseId')"
```

Publish, in order, waiting for each run to finish green before the next tag. Run this from any directory; it tags
`origin/main` of each repository through the GitHub API, so no local checkout is needed:

```sh
release() { # repo version
  local repo="nearpay-money/$1" tag="v$2" sha
  sha="$(gh api "repos/$repo/commits/main" -q .sha)"
  gh api "repos/$repo/git/refs" -f ref="refs/tags/$tag" -f sha="$sha" >/dev/null
  echo "tagged $repo $tag at $sha"
  local run=""
  for _ in $(seq 1 30); do # wait for the tag's run to appear
    run="$(gh run list --repo "$repo" --workflow release.yml --branch "$tag" --limit 1 --json databaseId -q '.[0].databaseId')"
    [ -n "$run" ] && break
    sleep 5
  done
  gh run watch --exit-status --repo "$repo" "$run"
}
release nearpay-spec 0.5.0 &&
release nearpay-node 0.4.0 &&
release nearpay-js 0.2.0 &&
release nearpay-agentkit 0.3.0 &&
release nearpay-cli 0.2.0
```

The same with git in local clones (equivalent; push one tag, wait for its run, then the next):

```sh
git -C nearpay-spec fetch origin && git -C nearpay-spec tag v0.5.0 origin/main && git -C nearpay-spec push origin v0.5.0
git -C nearpay-node fetch origin && git -C nearpay-node tag v0.4.0 origin/main && git -C nearpay-node push origin v0.4.0
git -C nearpay-js fetch origin && git -C nearpay-js tag v0.2.0 origin/main && git -C nearpay-js push origin v0.2.0
git -C nearpay-agentkit fetch origin && git -C nearpay-agentkit tag v0.3.0 origin/main && git -C nearpay-agentkit push origin v0.3.0
git -C nearpay-cli fetch origin && git -C nearpay-cli tag v0.2.0 origin/main && git -C nearpay-cli push origin v0.2.0
```

Check the result:

```sh
for p in spec node js react agent-signer x402 mcp cli; do npm view "@nearpay-money/$p" version; done
npx -y @nearpay-money/cli --help
npx -y @nearpay-money/mcp --help
```

A failed run can simply be re-run (Actions → the run → Re-run jobs): versions that already reached npm are skipped.

## Next releases

1. Bump the version in the package(s) and the version constant where one exists (`SPEC_VERSION` /
   `SPEC_INTERNAL_VERSION`, `SDK_VERSION`, `CLI_VERSION`, mcp `SERVER_VERSION`), update the CHANGELOG, merge.
2. If a consumer in the workspace needs the new version before it is on npm, publish it to the local registry
   (`pnpm release:local`) and add the tarball to `nearpay-deploy/registry-seed` as usual.
3. Push the tag `v<version>` in the repository (spec first if it changed).

Note: for `@nearpay-money/node` and the agentkit packages, the tarball CI publishes to npm is built with `pnpm pack`
and is not byte-identical to the local-registry tarball (`release:local` normalises the manifest), so a workspace
repository that later switches those packages from the local registry to npmjs needs a lockfile refresh
(`pnpm install`). spec, js, react and cli tarballs are identical.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `E404 Not Found - PUT https://registry.npmjs.org/@nearpay-money%2f…` | The `nearpay-money` org does not exist, or the token does not cover the scope (step 2). |
| `E403 … two-factor authentication` | The token was created without "Bypass two-factor authentication". |
| `NODE_AUTH_TOKEN is not set` | The `NPM_TOKEN` secret is missing in that repository (step 4). |
| Checkout of `nearpay-money/nearpay-deploy` fails | `NP_DEPLOY_READ_TOKEN` missing, expired or not approved (step 3). |
| `ERR_PNPM_NO_MATCHING_VERSION` / integrity errors during install | A version the lockfile uses is missing from `nearpay-deploy/registry-seed` on `main`. |
| `… is 0.x.y but the release tag is v…` | The tag does not match the package version; delete the tag and push the right one. |
