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

## Status

Design is complete and stress-tested (see `nearpay-brain`). Implementation proceeds in stages; **Stage 1** delivers the mainnet demo: hosted checkout with any-chain payment, on-chain verification and signed webhooks, plus an AI agent paying an x402-protected API. The run steps below become live at the end of Stage 1; until then `scripts/up.sh` reports that the stack is not built yet.

## Try it (end of Stage 1)

Prerequisites: Docker 24+ with Compose v2, git, Python 3, Node 22 (for the demo scripts).

1. Clone every repo next to this one — run `scripts/bootstrap.sh` → see 26 sibling folders (`nearpay-*`).
2. Configure — copy `../nearpay-deploy/compose/env/local.env.example` to `local.env` → see test-mode keys; live mode needs your own 1Click API key and NEAR accounts (never committed).
3. Start — run `scripts/up.sh local` → see `https://api.nearpay.localhost/healthz` return `ok` and the dashboard at `https://dashboard.nearpay.localhost`.
4. Pay in test mode — run `npm --prefix ../nearpay-testbed run demo:checkout` → see a checkout URL; open it, pay with the sandbox rail, see `payment_intent.succeeded` arrive at the demo merchant.
5. Agent payment — run `npm --prefix ../nearpay-testbed run demo:agent` → see an agent receive HTTP 402, sign a NEAR Intents transfer, and get the resource with a `PAYMENT-RESPONSE` header.
6. Live mode on mainnet — follow `../nearpay-testbed/README.md#mainnet-demo` (small amounts; you sign every transaction yourself).

## Repositories

`repos.json` is the machine-readable list. Architecture and the role of each repo: `nearpay-brain/architecture/repositories.md`.

| Group | Repos |
|---|---|
| Knowledge | `nearpay-brain` |
| Contracts & shared | `nearpay-spec`, `nearpay-kit` |
| Services | `nearpay-identity`, `nearpay-payments`, `nearpay-billing`, `nearpay-rails`, `nearpay-agentpay`, `nearpay-compliance`, `nearpay-webhooks`, `nearpay-notify`, `nearpay-sandbox`, `nearpay-sentinel` |
| Frontends | `nearpay-checkout`, `nearpay-js`, `nearpay-dashboard`, `nearpay-console`, `nearpay-docs`, `nearpay-web` |
| SDKs & tools | `nearpay-node`, `nearpay-agentkit`, `nearpay-cli` |
| On-chain | `nearpay-contracts` |
| Platform | `nearpay-infra`, `nearpay-deploy`, `nearpay-testbed` |

## Built with

Libraries and services are listed per repo in each README's "Built with" section. Code and documentation in all NearPay repos are written with AI assistance (Claude) under human direction and review. NEAR Hackathon details and disclosures: `HACKATHON.md`.

## License

Apache-2.0 — see `LICENSE`.
