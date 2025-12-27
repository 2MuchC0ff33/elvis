#!/bin/sh
# tests/integration_get_transaction_data.sh
# Integration: run get_transaction_data.sh with a mock fetch script

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t gtd)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/seeds.csv" <<CSV
seed_id,location,base_url
test_seed,Test,https://example/jobs?keywords=test
CSV

cat > "$tmp/mock_fetch_gtd.sh" <<'SH'
#!/bin/sh
set -eu
COUNTER_FILE="$PWD/mock_fetch_gtd.counter"
count=1
if [ -f "$COUNTER_FILE" ]; then count=$(cat "$COUNTER_FILE" || echo 1); fi
if [ "$count" -eq 1 ]; then printf '<html><body>page1<span data-automation="page-next"></span></body></html>'
else printf '<html><body>page2</body></html>'
fi
count=$((count+1))
printf '%s' "$count" > "$COUNTER_FILE"
SH
chmod +x "$tmp/mock_fetch_gtd.sh"
export unit_tmp_gtd="$tmp"
export FETCH_SCRIPT="$tmp/mock_fetch_gtd.sh"
# Ensure counter starts
printf '1' > "$tmp/mock_fetch_gtd.counter"
# Run workflow
sh "$REPO_ROOT/scripts/get_transaction_data.sh" "$tmp/seeds.csv" || { echo "FAIL: get_transaction_data.sh failed" >&2; exit 1; }
outfile="tmp/test_seed.htmls"
if [ -f "$outfile" ]; then
  grep -q 'page1' "$outfile" || { echo "FAIL: page1 missing" >&2; exit 1; }
  grep -q 'page2' "$outfile" || { echo "FAIL: page2 missing" >&2; exit 1; }
  echo "PASS: integration_get_transaction_data"
else
  echo "FAIL: get_transaction_data did not produce $outfile" >&2; exit 1
fi

# cleanup env
unset FETCH_SCRIPT || true
exit 0
