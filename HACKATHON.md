# NEAR Hackathon submission notes

| Item | Value |
|---|---|
| Event | NEAR Hackathon, 2026-11-01 → 2026-11-14 23:59 UTC (rules: https://nearhackathon.com/HACKATHON.md) |
| Tracks | `realworld` (Real-World Money), `agents` (Agent Economy) |
| Submitted repo | this repository (`nearpay`); all other repos are linked from `repos.json` |
| Work window | All NearPay work started after the 2026-10-19 announcement; the full git history of every repo is in scope |
| What is judged | Stage 1: hosted checkout (any chain → merchant's asset via NEAR Intents 1Click), on-chain settlement verification, signed webhooks, x402 agent payments settled with signed NEAR Intents transfers |
| Demo | Local stack against NEAR mainnet (reproducible from this README) + video in the X post; hosted demo added in the final stage |
| AI usage | Code and docs are AI-assisted (Claude) under human direction and review |
| Libraries | Listed in each repo's README "Built with" section |
| Other projects by the team | None |

## Actions that only a human performs

Submitting the form, posting on X, making repositories public, merging pull requests into `main` (and the first push of `main` to each new repository), signing transactions, spending tokens and deploying to mainnet. The AI agent may push feature branches and open pull requests for review (owner decision, `nearpay-brain/decisions/ADR-0017-git-workflow.md`). The submission payload is never committed to any repository.
