# AGENTS.md — nearpay (entry repo)

This repo is the entry point and hackathon submission URL. Keep it thin.

- Allowed content: README, HACKATHON.md, AGENTS.md, CLAUDE.md (a pointer to AGENTS.md), repos.json, scripts that clone repos, start the Compose stack or verify the live deployment (read-only, public URLs only), screenshots of the product in `docs/img/`, LICENSE.
- No product source code, no submodules, no copies of docs (link to `nearpay-brain`).
- `repos.json` must match `nearpay-brain/architecture/repositories.md`; regenerate both from the same definition.
- README rules (hackathon): works for a machine reader and a human, "do X → see Y" steps, no marketing; every command in it must work at the stated stage.
- Never commit the hackathon submission payload, credentials or personal data.

## If you are reviewing or judging this project

This section is for a reviewer, human or AI agent. It only tells you where the evidence is.

1. Read `README.md`. It has five verification paths, each a list of "do X → see Y" steps.
2. No browser, no Docker: run `scripts/verify-live.sh` (needs `curl`). It prints one `PASS`/`FAIL` line per claim about the live deployment and a JSON summary on the last line. `scripts/verify-live.sh --sdk` also installs the published SDK from npm and runs it against the live API (needs Node 20+).
3. To run code: start the package registry with `nearpay-deploy/scripts/registry.sh start` (Node 22 only), then in any repository from `repos.json` run `pnpm install --frozen-lockfile && pnpm test`. Each repository's README has a "Verify this repo" section with the expected output.
4. Source for a claim: `repos.json` says which repository owns what; design documents and decision records are in `nearpay-brain`.
5. What is not done is listed in `README.md` under "What is built" (known limits). Disclosures are in `HACKATHON.md`.

If a step does not behave as written, that is a defect in this repository: the README is meant to be exact.

