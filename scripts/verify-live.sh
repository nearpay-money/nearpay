#!/usr/bin/env bash
# Verify the LIVE NearPay deployment and its published packages. Needs curl; no account, no keys, no funds.
#
#   scripts/verify-live.sh            public endpoints, npm packages, first integrator (about 20 s)
#   scripts/verify-live.sh --sdk      also installs @nearpay-money/node from npm into a temp folder and
#                                     runs it against the live API (needs Node 20+ and npm)
#
# Prints one line per claim:  PASS|FAIL|SKIP  <id>  <claim>  — <evidence>
# Ends with a JSON summary on the last line and exits 0 only when nothing FAILed.
# Every check is read-only. Nothing here sends a payment or creates anything on the server.
set -u

DOMAIN="${NEARPAY_DOMAIN:-nearpay.money}"
SITE="https://$DOMAIN"
API="https://api.$DOMAIN"
PAY="https://pay.$DOMAIN"
DOCS="https://docs.$DOMAIN"
DASH="https://dashboard.$DOMAIN"
JS="https://js.$DOMAIN"
INTEGRATOR_URL="${NEARPAY_INTEGRATOR_URL:-https://degenmarket.lol}"
# Optional: the id of a public TEST-mode payment link (no real funds) to check. README, Path C, shows how to
# create one and pay it in a browser.
JUDGE_LINK_ID="${NEARPAY_JUDGE_LINK_ID:-}"
PACKAGES="spec node js react cli x402 agent-signer mcp"

sdk=0
for a in "$@"; do
  case "$a" in
    --sdk) sdk=1 ;;
    -h | --help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 2; }

pass=0 fail=0 skip=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

report() { # status id claim evidence
  printf '%-4s  %-22s  %s — %s\n' "$1" "$2" "$3" "$4"
  case "$1" in PASS) pass=$((pass + 1)) ;; FAIL) fail=$((fail + 1)) ;; *) skip=$((skip + 1)) ;; esac
}

# fetch <url> : body to $tmp/body, status code on stdout ("000" when the host cannot be reached)
fetch() {
  curl -sS -L -m 20 -A "nearpay-verify-live/1" -o "$tmp/body" -w '%{http_code}' "$1" 2>"$tmp/err" || true
}

check() { # id claim url expected_status extended_regex
  local code
  code="$(fetch "$3")"
  [ -n "$code" ] || code=000
  if [ "$code" = "$4" ] && grep -Eq -- "$5" "$tmp/body" 2>/dev/null; then
    report PASS "$1" "$2" "GET $3 → $code"
  elif [ "$code" = 000 ]; then
    report FAIL "$1" "$2" "GET $3 → no answer ($(tr -d '\n' <"$tmp/err" | cut -c1-80))"
  else
    report FAIL "$1" "$2" "GET $3 → $code, expected $4 and /$5/"
  fi
}

echo "NearPay live verification — $(date -u '+%Y-%m-%dT%H:%M:%SZ') — domain $DOMAIN"
echo

check site "marketing site is up" "$SITE/" 200 'Accept crypto payments'
check docs "docs: first live payment guide" "$DOCS/get-started" 200 'Accept your first live payment'
check docs-ai "docs: copy-paste prompt for coding agents" "$DOCS/build-with-ai" 200 'Integrate NearPay'
check api-health "API answers" "$API/healthz" 200 '^ok'
check api-errors "API errors follow the documented envelope" "$API/v1/payment_intents" 401 '"code":"authentication_required".*"doc_url":"https://docs\.'
check checkout "hosted checkout is served" "$PAY/" 200 'NearPay Checkout'
check dashboard "merchant dashboard is served" "$DASH/signup" 200 '<div id="root"|<title>'
check js-loader "browser loader for embedded checkout" "$JS/v1/nearpay.js" 200 'nearpay|NearPay'
check x402 "x402 v2 facilitator settles on NEAR mainnet via Intents" "$API/x402/supported" 200 '"x402Version":2.*"scheme":"exact".*"network":"near:mainnet"'
check sentinel-keys "sentinel publishes its co-signing keys" "$API/v1/attestations/keys" 200 '"public_key":"'

# Supported assets: the live registry built from NEAR Intents 1Click (count them and their chains).
code="$(fetch "$API/v1/assets")"
if [ "$code" = 200 ]; then
  assets="$(grep -o '"asset_id":"' "$tmp/body" | wc -l | tr -d ' ')"
  chains="$(grep -o '"chain":"[^"]*"' "$tmp/body" | sort -u | wc -l | tr -d ' ')"
  if [ "$assets" -ge 20 ] && [ "$chains" -ge 5 ]; then
    report PASS assets "payers can use many tokens on many chains" "GET $API/v1/assets → $assets assets on $chains chains"
  else
    report FAIL assets "payers can use many tokens on many chains" "only $assets assets on $chains chains"
  fi
else
  report FAIL assets "payers can use many tokens on many chains" "GET $API/v1/assets → $code"
fi

# Published SDKs and tools.
for p in $PACKAGES; do
  code="$(fetch "https://registry.npmjs.org/@nearpay-money%2f$p/latest")"
  version="$(grep -o '"version":"[^"]*"' "$tmp/body" 2>/dev/null | head -1 | cut -d'"' -f4)"
  if [ "$code" = 200 ] && [ -n "$version" ]; then
    report PASS "npm-$p" "@nearpay-money/$p is on npm" "version $version"
  else
    report FAIL "npm-$p" "@nearpay-money/$p is on npm" "registry.npmjs.org → $code"
  fi
done

# First production integrator.
check integrator "a real site takes payments through NearPay" "$INTEGRATOR_URL/" 200 'NearPay'

# Public test-mode payment link, when one is named (pay it in a browser with "Simulate payment": README, Path C).
if [ -n "$JUDGE_LINK_ID" ]; then
  check judge-link "public test-mode payment link is active" "$PAY/api/v1/payment_links/$JUDGE_LINK_ID/public" 200 '"livemode":false'
fi

# Published SDK against the live API (optional: needs Node and npm).
if [ "$sdk" = 1 ]; then
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    mkdir -p "$tmp/sdk"
    cat >"$tmp/sdk/check.mjs" <<'EOF'
import { NearPay, NearPayAuthenticationError, NearPaySignatureVerificationError, webhooks } from "@nearpay-money/node";
const out = [];
const line = (s, id, claim, ev) => out.push(`${s}\t${id}\t${claim}\t${ev}`);
// 1. Webhook signatures: a signed delivery verifies, a tampered one is rejected.
const secret = "whsec_verify_live_example";
const payload = JSON.stringify({ id: "evt_example", object: "event", type: "payment_intent.succeeded" });
try {
  const header = webhooks.generateTestHeaderString({ payload, secret });
  const event = webhooks.constructEvent(payload, header, secret, { validation: "off" });
  let rejected = false;
  try {
    webhooks.constructEvent(`${payload} `, header, secret, { validation: "off" });
  } catch (e) {
    rejected = e instanceof NearPaySignatureVerificationError;
  }
  if (event.type === "payment_intent.succeeded" && rejected) {
    line("PASS", "sdk-webhooks", "SDK verifies webhook signatures", "signed payload accepted, tampered payload rejected");
  } else line("FAIL", "sdk-webhooks", "SDK verifies webhook signatures", `accepted=${event.type} rejected=${rejected}`);
} catch (e) {
  line("FAIL", "sdk-webhooks", "SDK verifies webhook signatures", String(e).slice(0, 120));
}
// 2. The published SDK talks to the live API: a made-up key gets the typed authentication error.
try {
  const nearpay = new NearPay("sk_test_verifyLiveNotARealKey0000000000", { baseUrl: process.env.NP_API });
  await nearpay.paymentIntents.list({ limit: 1 });
  line("FAIL", "sdk-live", "SDK reaches the live API", "a made-up key was accepted");
} catch (e) {
  if (e instanceof NearPayAuthenticationError) {
    line("PASS", "sdk-live", "SDK reaches the live API", `typed error ${e.constructor.name}, code ${e.code}`);
  } else line("FAIL", "sdk-live", "SDK reaches the live API", `${e?.constructor?.name}: ${String(e?.message).slice(0, 100)}`);
}
process.stdout.write(`${out.join("\n")}\n`);
EOF
    if (cd "$tmp/sdk" && npm init -y >/dev/null 2>&1 && npm install --silent --no-audit --no-fund @nearpay-money/node >"$tmp/npm.log" 2>&1); then
      (cd "$tmp/sdk" && NP_API="$API" node check.mjs >"$tmp/sdk.out" 2>"$tmp/sdk.err") || true
      if [ -s "$tmp/sdk.out" ]; then
        while IFS="$(printf '\t')" read -r s id claim ev; do report "$s" "$id" "$claim" "$ev"; done <"$tmp/sdk.out"
      else
        report FAIL sdk "published SDK runs" "$(tr -d '\n' <"$tmp/sdk.err" | cut -c1-120)"
      fi
    else
      report FAIL sdk "published SDK installs from npm" "$(tail -1 "$tmp/npm.log" | cut -c1-120)"
    fi
  else
    report SKIP sdk "published SDK against the live API" "Node and npm are not installed"
  fi
fi

echo
printf '{"suite":"nearpay-verify-live","domain":"%s","pass":%d,"fail":%d,"skip":%d,"ok":%s}\n' \
  "$DOMAIN" "$pass" "$fail" "$skip" "$([ "$fail" = 0 ] && echo true || echo false)"
[ "$fail" = 0 ]
