#!/bin/sh
# tests/test_fetch_behaviour.sh
# Focused tests for fetch.sh behaviours: robots.txt blocking (exit 2), 403-retry logging, CAPTCHA detection

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

echo "[TEST] fetch behaviour: robots.txt block"
unit_tmp_robots="$(mktemp -d)"
# mock curl for robots: prints Disallow for /robots.txt
cat > "$unit_tmp_robots/mock_curl_robots.sh" <<'SH'
#!/bin/sh
last=""
while [ "$#" -gt 0 ]; do
  last="$1"
  shift
done
url="$last"
if echo "$url" | grep -q '/robots.txt$'; then
  printf 'User-agent: *\nDisallow: /jobs\n'
else
  printf 'page content'
fi
SH
chmod +x "$unit_tmp_robots/mock_curl_robots.sh"
# save env
_old_CURL_CMD="${CURL_CMD:-}"
_old_VERIFY_ROBOTS="${VERIFY_ROBOTS:-}"
export BACKOFF_SEQUENCE='5,20,60'
export CURL_CMD="$unit_tmp_robots/mock_curl_robots.sh"
export UA_ROTATE=true
export UA_LIST_PATH="$unit_tmp_robots/uas.txt"
export RETRY_ON_403=true
export EXTRA_403_RETRIES=1
export ACCEPT_HEADER='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
export ACCEPT_LANGUAGE='en-AU,en;q=0.9'
export NETWORK_LOG="$REPO_ROOT/logs/network.log"
export CAPTCHA_PATTERNS='captcha|recaptcha|g-recaptcha'
export VERIFY_ROBOTS=true
# run and expect non-zero / blocked (exit code 2)
if sh "$REPO_ROOT/scripts/fetch.sh" 'http://example/jobs' 1 2 > /dev/null 2>&1; then
  echo "FAIL: fetch.sh should have been blocked by robots.txt"; fail=1
else
  echo "PASS: fetch.sh honoured robots.txt and blocked the URL"
fi
# check network log for ROBOTSBLOCK entry and the matching rule (same line)
if grep 'ROBOTSBLOCK' "$REPO_ROOT/logs/network.log" 2>/dev/null | grep -q '/jobs' 2>/dev/null; then
  echo "PASS: fetch.sh recorded ROBOTSBLOCK in NETWORK_LOG with matching Disallow"
else
  echo "FAIL: ROBOTSBLOCK not recorded (or missing disallow) in NETWORK_LOG"; fail=1
fi
# restore env
export CURL_CMD="${_old_CURL_CMD:-}"
export VERIFY_ROBOTS="${_old_VERIFY_ROBOTS:-}"
rm -rf "$unit_tmp_robots"

# clear network log before CAPTCHA tests to ensure isolation
rm -f "$REPO_ROOT/logs/network.log" || true

# 403 retry behaviour
echo "[TEST] fetch behaviour: 403 then recover with EXTRA_403_RETRIES and log 403-retry"
unit_tmp_403="$(mktemp -d)"
state_file="$unit_tmp_403/state"
cat > "$unit_tmp_403/mock_curl_403.sh" <<'SH'
#!/bin/sh
FLAG="$state_file"
count=0
if [ -f "$FLAG" ]; then
  count=$(cat "$FLAG")
fi
count=$((count+1))
printf '%d' "$count" > "$FLAG"
# simulate first attempt 403, subsequent attempts 200
if [ "$count" -eq 1 ]; then
  # print body and status-like marker used by fetch wrapper tests
  printf 'BODY---HTTP-STATUS:403'
  exit 0
else
  printf 'BODY---HTTP-STATUS:200'
  exit 0
fi
SH
chmod +x "$unit_tmp_403/mock_curl_403.sh"
_old_CURL_CMD="${CURL_CMD:-}"
_old_RETRY_ON_403="${RETRY_ON_403:-}"
_old_EXTRA_403_RETRIES="${EXTRA_403_RETRIES:-}"
export CURL_CMD="$unit_tmp_403/mock_curl_403.sh"
export RETRY_ON_403=true
export EXTRA_403_RETRIES=1
# clear network log
rm -f "$REPO_ROOT/logs/network.log" || true
# run fetch - should eventually succeed
if sh "$REPO_ROOT/scripts/fetch.sh" 'http://example/' 1 2 > /dev/null 2>&1; then
  echo "PASS: fetch.sh recovered after 403"
else
  echo "FAIL: fetch.sh did not recover from 403"; fail=1
fi
# check network log for 403-retry entry
if grep -q '403-retry' "$REPO_ROOT/logs/network.log" 2>/dev/null; then
  echo "PASS: fetch.sh logged 403-retry"
else
  echo "FAIL: fetch.sh did not log 403-retry"; fail=1
fi
# restore env
export CURL_CMD="${_old_CURL_CMD:-}"
export RETRY_ON_403="${_old_RETRY_ON_403:-}"
export EXTRA_403_RETRIES="${_old_EXTRA_403_RETRIES:-}"
rm -rf "$unit_tmp_403"

# CAPTCHA detection
echo "[TEST] fetch behaviour: CAPTCHA detection"
unit_tmp_captcha="$(mktemp -d)"
cat > "$unit_tmp_captcha/mock_curl_captcha.sh" <<'SH'
#!/bin/sh
printf '<html><body><div class="g-recaptcha">please solve</div></body></html>'
SH
chmod +x "$unit_tmp_captcha/mock_curl_captcha.sh"
_old_CURL_CMD="$CURL_CMD" || true
export CURL_CMD="$unit_tmp_captcha/mock_curl_captcha.sh"
# run fetch - expect it to fail and warn about CAPTCHA (non-zero exit)
out="$unit_tmp_captcha/out"
if sh "$REPO_ROOT/scripts/fetch.sh" 'http://example/' 1 2 > "$out" 2>&1; then
  echo "FAIL: fetch.sh should fail on CAPTCHA"; fail=1
else
  if grep -q -i 'captcha\|human check' "$out" 2>/dev/null; then
    echo "PASS: fetch.sh detected CAPTCHA and failed"
  else
    echo "FAIL: fetch.sh did not warn about CAPTCHA"; fail=1
  fi
fi
# custom CAPTCHA_PATTERNS test
echo "[TEST] fetch behaviour: custom CAPTCHA_PATTERNS"
unit_tmp_captcha2="$(mktemp -d)"
cat > "$unit_tmp_captcha2/mock_curl_captcha2.sh" <<'SH'
#!/bin/sh
printf 'humancheck marker present'
SH
chmod +x "$unit_tmp_captcha2/mock_curl_captcha2.sh"
_old_CURL_CMD2="$CURL_CMD" || true
export CURL_CMD="$unit_tmp_captcha2/mock_curl_captcha2.sh"
export CAPTCHA_PATTERNS='humancheck'
out2="$unit_tmp_captcha2/out"
if sh "$REPO_ROOT/scripts/fetch.sh" 'http://example/' 1 2 > "$out2" 2>&1; then
  echo "FAIL: fetch.sh should fail on custom CAPTCHA"; fail=1
else
  if grep -q -i 'humancheck' "$out2" 2>/dev/null; then
    echo "PASS: fetch.sh respected CAPTCHA_PATTERNS and detected custom pattern"
  else
    echo "FAIL: fetch.sh did not detect custom CAPTCHA pattern"; fail=1
  fi
  # check NETWORK_LOG for CAPTCHA entry and pattern snippet
  if grep -q 'CAPTCHA' "$REPO_ROOT/logs/network.log" 2>/dev/null | grep -q 'humancheck' 2>/dev/null; then
    echo "PASS: custom CAPTCHA pattern recorded in NETWORK_LOG"
  else
    echo "FAIL: custom CAPTCHA pattern not recorded in NETWORK_LOG"; fail=1
  fi
if [ "$fail" -ne 0 ]; then
  echo "Some fetch behaviour tests failed"; exit 1
fi

echo "All fetch behaviour tests passed"
exit 0
