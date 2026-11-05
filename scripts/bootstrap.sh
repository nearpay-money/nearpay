#!/usr/bin/env bash
# Clone (or fast-forward) every NearPay repo listed in repos.json next to this repo.
# Usage: scripts/bootstrap.sh [--base https://github.com/<org>] [--ssh]
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
parent="$(dirname "$here")"
base="${NEARPAY_GIT_BASE:-$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["base_default"])' "$here/repos.json")}"
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --ssh) base="git@github.com:${base#https://github.com/}"; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
command -v git >/dev/null || { echo "git is required" >&2; exit 1; }
python3 -c 'import json,sys
for r in json.load(open(sys.argv[1]))["repos"]: print(r["name"], r["ref"])' "$here/repos.json" |
while read -r name ref; do
  dir="$parent/$name"
  if [ -d "$dir/.git" ]; then
    echo "update  $name"; git -C "$dir" fetch --quiet origin "$ref" 2>/dev/null && git -C "$dir" merge --ff-only --quiet FETCH_HEAD || echo "        (no remote or local changes; left as is)"
  else
    echo "clone   $name"; git clone --quiet --branch "$ref" "$base/$name.git" "$dir"
  fi
done
echo "done: repos are siblings of $(basename "$here") in $parent"
