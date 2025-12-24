#!/bin/sh
# tests/run-tests.sh
# Test runner for Elvis init workflow and modular scripts

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail=0

# Test: load_env.sh (should not fail if .env missing)
if ! sh "$REPO_ROOT/scripts/lib/load_env.sh"; then
  echo "FAIL: load_env.sh failed with missing .env" >&2
  fail=1
fi

# Test: load_config.sh (should fail if config missing)
if sh "$REPO_ROOT/scripts/lib/load_config.sh" not_a_real_file.conf 2>/dev/null; then
  echo "FAIL: load_config.sh did not fail on missing file" >&2
  fail=1
fi

# Test: load_seek_pagination.sh (should fail if config missing)
if sh "$REPO_ROOT/scripts/lib/load_seek_pagination.sh" not_a_real_file.ini 2>/dev/null; then
  echo "FAIL: load_seek_pagination.sh did not fail on missing file" >&2
  fail=1
fi

# Test: validate_env.sh (should fail if required vars missing)
unset SEEDS_FILE OUTPUT_DIR HISTORY_FILE LOG_FILE SEEK_PAGINATION_CONFIG || true
if sh "$REPO_ROOT/scripts/lib/validate_env.sh" 2>/dev/null; then
  echo "FAIL: validate_env.sh did not fail with missing vars" >&2
  fail=1
fi

# Test: prepare_log.sh (should create logs/log.txt)
rm -rf "$REPO_ROOT/logs"
sh "$REPO_ROOT/scripts/lib/prepare_log.sh" "$REPO_ROOT/logs/log.txt"
if [ ! -f "$REPO_ROOT/logs/log.txt" ]; then
  echo "FAIL: prepare_log.sh did not create log file" >&2
  fail=1
fi

# Test: bin/elvis-run init (should complete without error)
if ! sh "$REPO_ROOT/bin/elvis-run" init; then
  echo "FAIL: bin/elvis-run init failed" >&2
  fail=1
fi

# Additional tests for get transaction data workflow

tmp=tmp/test
mkdir -p "$tmp"

echo "[TEST] normalize.awk: trims and cleans CSV"
printf 'seed_id,location,base_url\nfoo , Perth , https://x\n' | awk -f scripts/lib/normalize.awk > "$tmp/norm.csv"
grep -q 'foo,Perth,https://x' "$tmp/norm.csv" || { echo "FAIL: normalize.awk"; fail=1; }

echo "[TEST] split_records.sh: splits to .txt files"
sh scripts/lib/split_records.sh "$tmp/norm.csv" "$tmp/records" || { echo "FAIL: split_records.sh error"; fail=1; }
[ -f "$tmp/records/seed_1.txt" ] || { echo "FAIL: split_records.sh output"; fail=1; }
grep -q 'seed_id=foo' "$tmp/records/seed_1.txt" || { echo "FAIL: split_records.sh content"; fail=1; }

echo "[TEST] pick_pagination.sh: detects PAG_START"
out=$(sh scripts/lib/pick_pagination.sh 'https://seek.com.au/jobs?foo')
[ "$out" = "PAG_START" ] || { echo "FAIL: pick_pagination.sh"; fail=1; }

echo "[TEST] fetch.sh: fails on bad URL"
if sh scripts/fetch.sh 'http://127.0.0.1:9999/404' 1 2 > /dev/null 2>&1; then
  echo "FAIL: fetch.sh should fail"; fail=1
else
  echo "PASS: fetch.sh error handling"
fi

echo "[TEST] paginate.sh: paginates and stops (mock)"
cat > "$tmp/mock.html" <<EOF
<html><body>page1<span data-automation=\"page-next\"></span></body></html>
EOF
# Create a temporary mock fetch script (POSIX-friendly)
cat > "$tmp/mock_fetch.sh" <<SH
#!/bin/sh
# Mock fetch: output the mock html file and then remove it to simulate page change
cat "$tmp/mock.html"
rm -f "$tmp/mock.html"
SH
chmod +x "$tmp/mock_fetch.sh"
cp scripts/lib/paginate.sh "$tmp/paginate.sh"
# Run paginate with FETCH_SCRIPT pointing to the mock script and capture output
FETCH_SCRIPT="$tmp/mock_fetch.sh" sh "$tmp/paginate.sh" 'http://x' 'PAG_START' > "$tmp/paginate.out" || true
if [ -f "$tmp/paginate.out" ]; then
  out=$(cat "$tmp/paginate.out")
else
  echo "FAIL: paginate.sh did not produce output"; fail=1
  out=""
fi

echo "$out" | grep -q 'page1' || { echo "FAIL: paginate.sh page1"; fail=1; }

# -----------------------------------------------------------------------------
# Tests for set-status workflow (enrichment -> validate -> dedupe -> logging)
# -----------------------------------------------------------------------------

echo "[TEST] set-status: full workflow (non-interactive)"
# Prepare test data
rm -rf "$tmp/calllists" "$tmp/logs"
mkdir -p "$tmp/calllists"
cat > "$tmp/results.csv" <<CSV
company_name,prospect_name,title,phone,email,location
Acme Pty Ltd,John Smith,MD,,john@example.com,Sydney, NSW
DupCo Ltd,Jane Doe,Owner,, ,Melbourne, VIC
CSV
# Prepare enriched file where second record gets a phone
cp "$tmp/results.csv" "$tmp/enriched.csv"
# Add phone for DupCo
awk -F, 'BEGIN{OFS=FS} NR==1{print} NR==2{print} NR==3{$4="0412345678"; $5=""; print}' "$tmp/enriched.csv" > "$tmp/enriched.tmp" && mv "$tmp/enriched.tmp" "$tmp/enriched.csv"

# Backup history and audit
HIST_BACKUP="$tmp/companies_history.bak"
cp -f companies_history.txt "$HIST_BACKUP"
AUDIT_BACKUP="$tmp/audit.bak"
cp -f audit.txt "$AUDIT_BACKUP" 2>/dev/null || true

# Run set-status with commit to append history
sh "$REPO_ROOT/scripts/set_status.sh" --input "$tmp/results.csv" --enriched "$tmp/enriched.csv" --out-dir "$tmp/calllists" --commit-history || { echo "FAIL: set_status.sh failed"; fail=1; }

# Check calllist exists
CALLFILE=$(ls -1 "$tmp/calllists" | grep calllist_ || true)
if [ -z "$CALLFILE" ]; then
  echo "FAIL: calllist not produced"; fail=1
else
  echo "Produced calllist: $CALLFILE"
  grep -q 'Acme Pty Ltd' "$tmp/calllists/$CALLFILE" || { echo "FAIL: Acme not in calllist"; fail=1; }
  grep -q 'DupCo Ltd' "$tmp/calllists/$CALLFILE" || { echo "FAIL: DupCo not in calllist"; fail=1; }
fi

# Check companies_history was appended (case-insensitive match)
tail -n 5 companies_history.txt | tr '[:upper:]' '[:lower:]' | grep -q 'acme pty ltd' || { echo "FAIL: history not appended for Acme"; fail=1; }

# Check audit.txt has an entry
grep -q 'set-status run' audit.txt || { echo "FAIL: audit entry missing"; fail=1; }

# Restore backups
mv "$HIST_BACKUP" companies_history.txt
mv "$AUDIT_BACKUP" audit.txt 2>/dev/null || true

if [ "$fail" -eq 0 ]; then
  echo "All tests passed."
else
  echo "Some tests failed." >&2
fi
exit "$fail"
