#!/usr/bin/env bash
# Start the NearPay stack (Docker Compose, defined in nearpay-deploy). Usage: scripts/up.sh [local] [--no-build]
# Delegates to ../nearpay-deploy/scripts/up.sh, which seeds local test keys, publishes the contract and
# kit packages to the local registry, and starts the platform plus every service that is built.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
deploy="$(dirname "$here")/nearpay-deploy"
[ -x "$deploy/scripts/up.sh" ] || { echo "nearpay-deploy not found next to this repo; run scripts/bootstrap.sh first" >&2; exit 1; }
exec "$deploy/scripts/up.sh" "$@"
