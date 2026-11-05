#!/usr/bin/env bash
# Start the NearPay stack with Docker Compose (stack lives in nearpay-deploy/compose).
# Usage: scripts/up.sh [local|server] [--observability]
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
compose_dir="$(dirname "$here")/nearpay-deploy/compose"
profile="${1:-local}"; shift || true
[ -d "$compose_dir" ] || { echo "nearpay-deploy not found next to this repo; run scripts/bootstrap.sh first" >&2; exit 1; }
files=(-f "$compose_dir/compose.yaml" -f "$compose_dir/compose.$profile.yaml")
[ "${1:-}" = "--observability" ] && files+=(-f "$compose_dir/compose.observability.yaml")
exec docker compose "${files[@]}" --env-file "$compose_dir/env/$profile.env" up --build -d
