#!/usr/bin/env bash
# Stop the NearPay stack. Usage: scripts/down.sh [--volumes]   (--volumes also deletes local data)
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
deploy="$(dirname "$here")/nearpay-deploy"
[ -x "$deploy/scripts/down.sh" ] || { echo "nearpay-deploy not found next to this repo; run scripts/bootstrap.sh first" >&2; exit 1; }
exec "$deploy/scripts/down.sh" "$@"
