# NearPay

Non-custodial, chain-abstracted merchant payments on NEAR Intents. A merchant prices in USD (or any asset); the payer pays with any token on any supported chain; the merchant receives the asset it chose, on the chain it chose. AI agents pay per request over x402. NearPay never holds the funds.

This repository is the **entry point**: it explains the product, lists every repository, and runs the whole system. It contains no product source code.

## Problem

- Merchants who accept crypto must pick chains, run wallets per chain, watch each chain and reconcile by hand — and still lose payers who hold the "wrong" token.
- Payers must already hold the exact token on the exact chain, or bridge and swap first.
- Developers lack payment primitives they expect: idempotent API, signed webhooks, test mode, refunds, invoices, subscriptions.
- AI agents need to pay per call in seconds for cents; card rails cannot do that.

## How NEAR is used

| NEAR component | Role in NearPay |
|---|---|
| NEAR Intents **1Click API** | Any-token, any-chain payment → exact amount of the merchant's chosen asset (`EXACT_OUTPUT` quotes, deposit addresses, status); NearPay's fee via `appFees` |
| NEAR Intents **Verifier** (`intents.near`) | Settlement ledger; payer- and agent-signed `transfer` intents settle in ~1.2 s; merchants can settle into their Intents account |
| NEAR mainnet (600 ms blocks, ~1.2 s finality) | Evidence of settlement via our own indexer; function-call keys limit what NearPay's relayer can do (gas only) |
| x402 v2 | HTTP-native agent payments; NearPay is the facilitator for an `exact` scheme settled through NEAR Intents |
| NEAR contract `v1.vault.nearpay.near` (`nearpay-contracts`) | Auto-debit: the payer funds a mandate from their own account and can cancel it any time and withdraw the rest; collection is permissionless and pays the merchant's NEAR or Intents account |

## Status

v1 (Stages 1–4) is built: hosted checkout from any supported chain (EVM, NEAR, Solana, Bitcoin), x402 agent payments, refunds, payment links, reconciliation, invoices, subscriptions, the CLI, the MCP server and auto-debit mandates. Each stage exits on its test-mode E2E suites in `nearpay-testbed`; in test mode `nearpay-sandbox` simulates 1Click, the origin chains and the vault. Still to do, by a human: deploy the vault contract on mainnet and record the v1 mainnet demo.

## Try it (v1, test mode)

Prerequisites: Docker 24+ with Compose 2.30+, git, Python 3, Node 22 with pnpm (`corepack enable`), Google Chrome (browser suites), and [mkcert](https://github.com/FiloSottile/mkcert) for trusted local HTTPS (passkeys need it; without it the stack uses a self-signed certificate). Test mode needs no funds and no keys of yours.

1. Clone every repo next to this one — run `scripts/bootstrap.sh` → see 25 sibling folders (`nearpay-*`).
2. Start — run `scripts/up.sh local` → see "NearPay is up" with the local URLs; `curl https://api.nearpay.localhost/healthz` returns `OK`. Dashboard: `https://dashboard.nearpay.localhost`; Mailpit (magic links, receipts): `https://mail.nearpay.localhost`; ops console: `https://ops.nearpay.localhost`. The first run creates test-mode keys in `../nearpay-deploy/.secrets/` and `../nearpay-deploy/compose/env/local.env` (never committed). Stop with `scripts/down.sh`.
3. Seed demo data — run `../nearpay-deploy/scripts/seed.sh data` → see "demo merchant ready (test mode)": demo merchant and keys (`../nearpay-deploy/.secrets/demo.json`), the merchant-demo webhook endpoint, the demo agent funded in the sandbox, a billing catalogue (`../nearpay-deploy/.secrets/demo-billing.json`).
4. Prepare the testbed — every command below runs in `../nearpay-testbed`:

   ```sh
   cd ../nearpay-testbed
   pnpm run setup                                                   # @nearpay/* from the stack's local registry
   export NODE_EXTRA_CA_CERTS=../nearpay-deploy/.secrets/tls/ca.pem # Node trusts the local CA
   ```

   "Verified by" names the E2E suite that checks a capability end to end: `pnpm test:e2e <path>` runs one suite, `NP_E2E=1 pnpm test:pw <file>` one browser suite (suite table: `../nearpay-testbed/README.md#e2e-step-14`). Dashboard steps need a test-mode account: sign up at the dashboard (magic link from Mailpit, then a passkey) and keep the **Test** switch on.

5. Pay from any chain — run `pnpm demo:checkout` → see a checkout URL, the scripted payer checking sentinel's attestation and simulating the deposit, then `payment_intent.succeeded` verified by merchant-demo. Open the URL to pay by hand: choose a token and chain, then simulate the deposit. `pnpm demo:checkout --amount 205` → sandbox scenario 05 (`requires_review`). Verified by `e2e/api/checkout`, `e2e/api/scenarios`, `e2e/checkout/hosted.pw.ts`.
6. Agent pays a 402 API — run `pnpm demo:agent` → see `402`, a signed NEAR Intents transfer, `200` with a `PAYMENT-RESPONSE` header, then `agent_payment.settled`. Verified by `e2e/agent/x402` (cross-chain x402: `e2e/stage3/agents`).
7. Payment link, refund, reconciliation — in the dashboard, **Payment links** → create a link → open its `https://pay.nearpay.localhost/l/…` page and pay → see the link's uses go up by one and the payment in **Payments**. Open that payment → **Refund** → see `refund.succeeded` and a receipt in Mailpit. Reconciliation runs in the console: `pnpm ops operator-add ops@example.test ops_admin` → open the enrolment link from Mailpit → re-run a completed day → see `ok`, `diff_count 0`. Verified by `e2e/stage2` (payment links, refunds, reconciliation, console).
8. Invoice and subscription — in the dashboard, **Billing** → **Invoices** → create a draft, **Finalize**, **Send** → see `Invoice … [test]` in Mailpit; its hosted link `/i/…` pays from Base or Solana → `invoice.paid`, PDF stamped `PAID`. Renewals use the subscription test clock (API: `/v1/test_helpers/subscriptions/*`): run `pnpm test:e2e e2e/stage3/subscriptions` → first invoice → `active` → `renewal_upcoming` → renewal invoice paid from Solana → unpaid renewal → `past_due` → paid → `active`. Verified by `e2e/stage3/invoices`, `e2e/stage3/subscriptions`, `e2e/stage3/hosted-invoice.pw.ts`.
9. CLI login, listen, trigger — build it once, then run it against the local stack:

   ```sh
   pnpm -C ../nearpay-cli install && pnpm -C ../nearpay-cli build
   export NEARPAY_API_BASE=https://api.nearpay.localhost
   node ../nearpay-cli/dist/cli.js login                                   # approve the pairing code in the dashboard
   node ../nearpay-cli/dist/cli.js listen                                  # terminal 1
   node ../nearpay-cli/dist/cli.js trigger payment_intent.succeeded        # terminal 2
   ```

   → `login` prints `Done! Logged in to … in test mode.`; `listen` prints `--> payment_intent.succeeded [evt_…] pi_…`; `trigger` prints each API call, then `✓ payment_intent.succeeded evt_…`. Without a dashboard user, pass the demo `sk_test_` key from `../nearpay-deploy/.secrets/demo.json` with `--api-key`. Verified by `e2e/stage3/cli.pw.ts`.
10. MCP agent pays an invoice — run `pnpm test:e2e e2e/stage3/agents` → `@nearpay/mcp` over stdio pays a checkout session and a hosted invoice, refuses over-budget and non-allow-listed payments, and pays a cross-chain x402 resource; reconciliation stays `ok`. To drive it yourself: `../nearpay-agentkit/examples/mcp-agent/agent.ts` (environment in its header).
11. Auto-debit mandate (simulated vault) — in the dashboard, **Billing** → **Subscriptions** → create one with a monthly price in USD or USDC and collection method auto-debit → the auto-debit panel shows the funding details; fund it with the test-mode simulated funding → **Billing** → **Auto-debit** → the mandate shows its balance, periods left and collections with NEAR evidence; the test-mode payer helpers cancel and withdraw. Run `pnpm test:e2e e2e/stage4/mandates` → fund 3 periods → `mandate.activated` → keeper collects period 1 → invoice paid by `mandate_collection` → renewal collected → withdraw while active refused → payer cancel refunds the rest (`mandate.canceled`); insufficient funds fall back to the hosted invoice. Edge cases: `e2e/stage4/vault-scenarios`.
12. Solana payer — on a hosted checkout or invoice page choose Solana (USDC or SOL) → see a sentinel-attested deposit address, no memo, a Solana Pay QR; simulate → paid. Verified by `e2e/stage4/chains` (also a Bitcoin P2WPKH payer).
13. Everything — run `pnpm test:e2e` and `NP_E2E=1 pnpm test:pw` → every suite above.

## Mainnet demo (v1, human-run)

Live mode runs the same local stack with your own accounts and credentials; you sign every transaction, and nothing in NearPay holds a payer's or merchant's keys. Setup (`seed.sh live`, `live-setup.mjs`) and the merchant onboarding (`pnpm onboard:live`): `../nearpay-testbed/README.md#mainnet-demo`. Auto-debit on mainnet needs the vault `v1.vault.nearpay.near`, which only the owner deploys (`nearpay-brain/lld/contracts-vault.md` §6); until then it is shown in test mode.

## Repositories

`repos.json` is the machine-readable list. Architecture and the role of each repo: `nearpay-brain/architecture/repositories.md`.

| Group | Repos |
|---|---|
| Knowledge | `nearpay-brain` |
| Contracts & shared | `nearpay-spec`, `nearpay-kit` |
| Services | `nearpay-identity`, `nearpay-payments`, `nearpay-billing`, `nearpay-rails`, `nearpay-agentpay`, `nearpay-compliance`, `nearpay-webhooks`, `nearpay-notify`, `nearpay-sandbox`, `nearpay-sentinel` |
| Frontends | `nearpay-checkout`, `nearpay-js`, `nearpay-dashboard`, `nearpay-console`, `nearpay-site` |
| SDKs & tools | `nearpay-node`, `nearpay-agentkit`, `nearpay-cli` |
| On-chain | `nearpay-contracts` |
| Platform | `nearpay-infra`, `nearpay-deploy`, `nearpay-testbed` |

## Built with

Libraries and services are listed per repo in each README's "Built with" section. Code and documentation in all NearPay repos are written with AI assistance (Claude) under human direction and review. NEAR Hackathon details and disclosures: `HACKATHON.md`.

## License

Apache-2.0 — see `LICENSE`.
