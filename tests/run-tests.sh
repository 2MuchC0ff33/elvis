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

# Unit test: extract_seeds.awk
echo "[TEST] extract_seeds.awk: extracts seed_id and base_url"
unit_tmp_seeds="$tmp/seeds_test"
mkdir -p "$unit_tmp_seeds"
cat > "$unit_tmp_seeds/norm.csv" <<CSV
seed_id,location,base_url
seek_fifo_perth,Perth,https://www.seek.com.au/fifo-jobs/in-All-Perth-WA
foo,Bar,https://example.com/jobs
CSV

awk -F',' -f scripts/lib/extract_seeds.awk "$unit_tmp_seeds/norm.csv" > "$unit_tmp_seeds/out.txt" || { echo "FAIL: extract_seeds.awk failed"; fail=1; }
grep -q 'seek_fifo_perth|https://www.seek.com.au/fifo-jobs/in-All-Perth-WA' "$unit_tmp_seeds/out.txt" || { echo "FAIL: extract_seeds.awk missing seek_fifo_perth"; fail=1; }

rm -rf "$unit_tmp_seeds"

# Unit test: http_utils.sh (sourcing)
echo "[TEST] http_utils.sh: can be sourced and provides fetch_with_backoff"
. scripts/lib/http_utils.sh || { echo "FAIL: sourcing http_utils.sh"; fail=1; }
# function should exist
if ! command -v fetch_with_backoff >/dev/null 2>&1; then
  echo "FAIL: fetch_with_backoff not available"; fail=1
fi

# Unit test: parse.sh (minimal parse from mock HTML)
echo "[TEST] parse.sh: parse job cards from HTML"
unit_tmp_parse="$tmp/parse_test"
mkdir -p "$unit_tmp_parse"
cat > "$unit_tmp_parse/mock.htmls" <<HTML
<article data-automation="normalJob" data-job-id="job-123">
  <a data-automation="jobCompany">Example Pty Ltd</a>
  <a data-automation="jobTitle">Manager</a>
  <a data-automation="jobLocation">Perth, WA</a>
  <span data-automation="jobShortDescription">Summary text for example</span>
</article>

<article data-automation="normalJob" data-job-id="job-456">
  <a data-automation="jobCompany">Another Co</a>
  <a data-automation="jobTitle">Engineer</a>
  <a data-automation="jobLocation">Sydney, NSW</a>
  <span data-automation="jobShortDescription">Another summary</span>
</article>
HTML

sh scripts/parse.sh "$unit_tmp_parse/mock.htmls" --out "$unit_tmp_parse/out.csv" || { echo "FAIL: parse.sh failed"; fail=1; }
grep -q 'Example Pty Ltd' "$unit_tmp_parse/out.csv" || { echo "FAIL: Example Pty Ltd missing in parse output"; fail=1; }
# check job_id and summary present
grep -q 'job-123' "$unit_tmp_parse/out.csv" || { echo "FAIL: job-123 missing in parse output"; fail=1; }
grep -q 'Summary text for example' "$unit_tmp_parse/out.csv" || { echo "FAIL: summary missing in parse output"; fail=1; }

rm -rf "$unit_tmp_parse"

# Unit test: enrich.sh (wrapper to enrich_status.sh)
echo "[TEST] enrich.sh: wrapper to enrich_status.sh"
unit_tmp_enrich="$tmp/enrich_test"
mkdir -p "$unit_tmp_enrich"
cat > "$unit_tmp_enrich/in.csv" <<CSV
company_name,prospect_name,title,phone,email,location
A,Joe,MD,0411000000,joe@example.com,Perth,WA
CSV

sh scripts/enrich.sh "$unit_tmp_enrich/in.csv" "$unit_tmp_enrich/out.csv" || { echo "FAIL: enrich.sh failed"; fail=1; }
[ -f "$unit_tmp_enrich/out.csv" ] || { echo "FAIL: enrich.sh did not produce out file"; fail=1; }
rm -rf "$unit_tmp_enrich"

# Unit test: run.sh help
sh scripts/run.sh help >/dev/null || { echo "FAIL: run.sh help"; fail=1; }

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

# Unit test: validate.sh (unit)
echo "[TEST] validate.sh: validation & normalisation (unit test)"
unit_tmp_validate="$tmp/validate_test"
mkdir -p "$unit_tmp_validate"
cat > "$unit_tmp_validate/input.csv" <<CSV
company_name,prospect_name,title,phone,email,location
GoodCo,John,MD,+61410000000,john@good.co,Perth,WA
,,Owner,0412223333,owner@nocomp.com,Sydney,VIC
NoContact,Jane,HR,, ,Brisbane,QLD
BadEmail,Bob,CTO,,not-an-email,Melbourne,VIC
CommaLoc,Alan,CEO,0413444444,,Adelaide,SA
CSV

# Run validation
sh scripts/validate.sh "$unit_tmp_validate/input.csv" --out "$unit_tmp_validate/out.csv" || { echo "FAIL: validate.sh failed"; fail=1; }

# Check output contains only GoodCo and CommaLoc
grep -q 'GoodCo' "$unit_tmp_validate/out.csv" || { echo "FAIL: GoodCo missing in validate out"; fail=1; }
grep -q 'CommaLoc' "$unit_tmp_validate/out.csv" || { echo "FAIL: CommaLoc missing in validate out"; fail=1; }
# Ensure NoCompany, NoContact and BadEmail are excluded
grep -q 'NoCompany' "$unit_tmp_validate/out.csv" && { echo "FAIL: NoCompany should be excluded"; fail=1; }
grep -q 'NoContact' "$unit_tmp_validate/out.csv" && { echo "FAIL: NoContact should be excluded"; fail=1; }
grep -q 'BadEmail' "$unit_tmp_validate/out.csv" && { echo "FAIL: BadEmail should be excluded"; fail=1; }
# Check phone normalisation (+61 -> 0)
grep -q '0410000000' "$unit_tmp_validate/out.csv" || { echo "FAIL: phone normalisation failed"; fail=1; }

# Clean up
rm -rf "$unit_tmp_validate"

# Unit test: deduper.sh
echo "[TEST] deduper.sh: dedupe + append history (unit test)"
unit_tmp="$tmp/deduper_test"
mkdir -p "$unit_tmp"
cat > "$unit_tmp/input.csv" <<CSV
company_name,prospect_name,title,phone,email,location
Acme Pty Ltd,John Smith,MD,0411000000,john@example.com,Sydney
Acme Pty Ltd,Jane Doe,Owner,0411999999,jane@example.com,Sydney
NewCo,Alan,CEO,,alan@newco.com,Perth
CSV

# Prepare isolated history file
echo "OldCo Ltd" > "$unit_tmp/history.txt"

# Run deduper and append to our isolated history file
sh scripts/deduper.sh --in "$unit_tmp/input.csv" --out "$unit_tmp/out.csv" --history "$unit_tmp/history.txt" --append-history || { echo "FAIL: deduper.sh failed"; fail=1; }

# Validate output: should contain single Acme and NewCo
grep -q 'Acme Pty Ltd' "$unit_tmp/out.csv" || { echo "FAIL: Acme missing in deduper out"; fail=1; }
grep -q 'NewCo' "$unit_tmp/out.csv" || { echo "FAIL: NewCo missing in deduper out"; fail=1; }
# Ensure Acme appears only once
count=$(tail -n +2 "$unit_tmp/out.csv" | awk -F, '$1=="Acme Pty Ltd"{c++} END{print c+0}')
[ "$count" -eq 1 ] || { echo "FAIL: Acme dedup not working (count=$count)"; fail=1; }

# Check history appended
grep -q 'NewCo' "$unit_tmp/history.txt" || { echo "FAIL: NewCo not appended to history"; fail=1; }

# Clean up unit test temp
rm -rf "$unit_tmp"

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
