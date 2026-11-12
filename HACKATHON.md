# NEAR Hackathon submission notes

Everything a judge needs is in `README.md`. This file is the short, structured version of the disclosures.

| Item | Value |
|---|---|
| Event | NEAR Hackathon, 2026-11-01 → 2026-11-14 23:59 UTC (rules: https://nearhackathon.com/HACKATHON.md) |
| Tracks | `realworld` (Real-World Money), `agents` (Agent Economy) |
| Submitted repo | This repository (`nearpay`). The 25 source repositories are listed in `repos.json` |
| Hosted demo | https://nearpay.money (site), https://dashboard.nearpay.money (merchant dashboard, open sign-up), https://pay.nearpay.money (checkout), https://api.nearpay.money (API), https://docs.nearpay.money (docs). Live mode on NEAR mainnet |
| Real integration | https://degenmarket.lol takes its payments through NearPay (`README.md` → Path B) |
| Verify without installing | `scripts/verify-live.sh` (`README.md` → Path A) |
| Reproduce locally | `README.md` → Path D (Node only) and Path E (Docker, whole platform in test mode) |
| Work window | All NearPay code was written during the hackathon. The first commit in every repository is dated 2026-11-05; the full git history of every repository is in scope |
| What is judged | Hosted checkout (any token on any supported chain → the merchant's chosen token, through the NEAR Intents 1Click API), an independent checker that co-signs every deposit address, on-chain settlement evidence, signed webhooks, payment links, refunds, invoices, subscriptions, reconciliation, x402 agent payments settled as signed NEAR Intents transfers, an MCP server for agents, the CLI, the Node SDK, and an auto-debit vault contract for NEAR |
| Track fit | `realworld`: a business can sign up and take a real payment in minutes, with payment links, refunds, invoices and subscriptions. `agents`: x402 facilitator on `near:mainnet`, agent-signed Intents transfers, an MCP server that pays checkout sessions, invoices and x402 resources within spending limits |
| Not on mainnet | The auto-debit vault contract (`nearpay-contracts`) is built and tested but not deployed. Live subscriptions are billed by invoice; auto-debit runs in test mode against a simulated vault |
| AI usage | Code and docs in every repository are AI-assisted (Claude) under human direction and review |
| Libraries | Main ones in `README.md` → Hackathon notes; each repository's README lists its own under "Built with" |
| Other projects by the team | Degen Market (https://degenmarket.lol), a separate product by the same founder. It is NearPay's first live merchant and integrates through the public API only |
| Licence | Apache-2.0 in every repository |

## Actions that only a human performs

Providing credentials and accounts, signing mainnet transactions, spending funds, mainnet deployment (including the vault contract), operating the live deployment, the first push of `main` to a new repository, making repositories public, posting on X and submitting the form. AI agents push feature branches and open pull requests (`nearpay-brain/decisions/ADR-0017-git-workflow.md`); merging them is delegated to the lead agent with required checks (`nearpay-brain/decisions/ADR-0020-v1-delivery-and-vendor-scope.md`). The submission payload is never committed to any repository.
