# NEAR Hackathon submission notes

| Item | Value |
|---|---|
| Event | NEAR Hackathon, 2026-11-01 → 2026-11-14 23:59 UTC (rules: https://nearhackathon.com/HACKATHON.md) |
| Tracks | `realworld` (Real-World Money), `agents` (Agent Economy) |
| Submitted repo | this repository (`nearpay`); all other repos are linked from `repos.json` |
| Work window | All NearPay work started after the 2026-10-19 announcement; the full git history of every repo is in scope |
| Status | v1 built (Stages 1–4, each exited on test-mode E2E); vault mainnet deployment and the recorded mainnet demo are human steps (`README.md` → Mainnet demo) |
| What is judged | v1: hosted checkout (any chain → merchant's asset via NEAR Intents 1Click) with sentinel co-signing and on-chain settlement evidence, signed webhooks, x402 agent payments settled with signed NEAR Intents transfers, refunds, payment links, reconciliation, invoices, subscriptions, CLI, MCP server for agents, auto-debit mandates on a NEAR vault contract, Solana and Bitcoin payers |
| Track fit | `realworld`: merchant payments, refunds, invoices, subscriptions, auto-debit; `agents`: x402 facilitator, agent-signed Intents transfers, MCP server paying sessions, invoices and x402 resources within limits |
| Demo | One human-run v1 mainnet demo on the local stack (reproducible from `README.md`), recorded as the video in the X post; a hosted deployment follows in Stage 5 (post-v1) |
| AI usage | Code and docs are AI-assisted (Claude) under human direction and review |
| Libraries | Listed in each repo's README "Built with" section |
| Other projects by the team | None |

## Actions that only a human performs

Providing credentials and accounts, signing mainnet transactions, spending funds, mainnet deployment (including the vault contract), running the v1 mainnet demo, the first push of `main` to a new repository, making repositories public, posting on X and submitting the form. AI agents push feature branches and open pull requests (`nearpay-brain/decisions/ADR-0017-git-workflow.md`); merging them is delegated to the lead agent with required green checks (`nearpay-brain/decisions/ADR-0020-v1-delivery-and-vendor-scope.md`). The submission payload is never committed to any repository.
