#!/bin/sh
# tests/unit_fetch_ua_403.sh
# Tests fetch UA rotation/cleaning and 403-retry behaviour (mocked curl)

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t fetchtmp)"
trap 'rm -rf "$tmp"' EXIT

# mock curl to echo User-Agent header and a body
cat > "$tmp/mock_curl.sh" <<'SH'
#!/bin/sh
ua=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -H)
      shift; if echo "$1" | grep -qi 'User-Agent:'; then ua="$1"; fi;;
    --max-time) shift;;
    -s|-S|-sS) ;;
    *) url="$1";;
  esac
  shift || true
done
printf '%s\n' "$ua"
printf 'OK'
SH
chmod +x "$tmp/mock_curl.sh"
printf 'UA-One\nUA-Two\n' > "$tmp/uas.txt"
# preserve env
old_CURL_CMD="${CURL_CMD:-}"
old_UA_ROTATE="${UA_ROTATE:-}"
old_UA_LIST_PATH="${UA_LIST_PATH:-}"
# set minimal fetch-related env so fetch.sh won't error
export BACKOFF_SEQUENCE='5,20,60'
export CURL_CMD="$tmp/mock_curl.sh"
export UA_ROTATE=true
export UA_LIST_PATH="$tmp/uas.txt"
export RETRY_ON_403=true
export EXTRA_403_RETRIES=1
export ACCEPT_HEADER='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
export ACCEPT_LANGUAGE='en-AU,en;q=0.9'
export NETWORK_LOG="$tmp/network.log"
export CAPTCHA_PATTERNS='captcha|recaptcha|g-recaptcha'
out=$(sh "$REPO_ROOT/scripts/fetch.sh" 'http://example/' 1 2 2>/dev/null || true)
if echo "$out" | grep -q -E 'User-Agent:.*UA-(One|Two)'; then
  echo "PASS: fetch UA rotation"
else
  echo "FAIL: fetch UA rotation missing" >&2; exit 1
fi

# 403-retry behaviour: script returns 403 first, then 200
cat > "$tmp/mock_curl_403.sh" <<'SH'
#!/bin/sh
FLAG="$tmp/mock_curl_403.state"
count=0
if [ -f "$FLAG" ]; then count=$(cat "$FLAG") fi
count=$((count+1))
printf '%d' "$count" > "$FLAG"
if [ "$count" -eq 1 ]; then
  printf 'BODY\n---HTTP-STATUS:403\n'
  exit 0
else
  printf 'BODY\n---HTTP-STATUS:200\n'
  exit 0
fi
SH
chmod +x "$tmp/mock_curl_403.sh"
export CURL_CMD="$tmp/mock_curl_403.sh"
export RETRY_ON_403=true
export EXTRA_403_RETRIES=1
mkdir -p logs
rm -f logs/network.log
out3=$(sh "$REPO_ROOT/scripts/fetch.sh" 'http://example/' 1 2 2>/dev/null || true)
if echo "$out3" | grep -q 'BODY'; then
  echo "PASS: fetch recovered after 403"
else
  echo "FAIL: fetch did not recover from 403" >&2; exit 1
fi
if grep -q '403-retry' logs/network.log 2>/dev/null; then
  echo "PASS: fetch logged 403-retry"
else
  echo "FAIL: missing 403-retry in network log" >&2; exit 1
fi

# restore env
CURL_CMD="$old_CURL_CMD" || unset CURL_CMD || true
UA_ROTATE="$old_UA_ROTATE" || unset UA_ROTATE || true
UA_LIST_PATH="$old_UA_LIST_PATH" || unset UA_LIST_PATH || true

exit 0
