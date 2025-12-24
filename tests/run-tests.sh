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
# PAG_PAGE detection
echo "[TEST] pick_pagination.sh: detects PAG_PAGE"
out2=$(sh scripts/lib/pick_pagination.sh 'https://seek.com.au/software-developer-jobs/in-Perth-WA')
[ "$out2" = "PAG_PAGE" ] || { echo "FAIL: pick_pagination.sh PAG_PAGE expected, got $out2"; fail=1; }

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
# shellcheck disable=SC1091
if ! . "$REPO_ROOT/scripts/lib/http_utils.sh"; then
  echo "FAIL: sourcing http_utils.sh"; fail=1
fi
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

# Unit test: fetch.sh UA rotation and CURL_CMD override
echo "[TEST] fetch.sh: UA rotation and CURL_CMD override"
unit_tmp_fetch="$tmp/fetch_test"
rm -rf "$unit_tmp_fetch"
mkdir -p "$unit_tmp_fetch"
# mock curl that prints received User-Agent header and a body
cat > "$unit_tmp_fetch/mock_curl.sh" <<'SH'
#!/bin/sh
# mock curl: find -H headers and print the User-Agent header then a body
ua=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -H)
      shift; if echo "$1" | grep -qi 'User-Agent:'; then ua="$1"; fi;;
    --max-time) shift; ;;
    -s|-S|-sS) ;;
    *) url="$1";;
  esac
  shift || true
done
# echo header and a body
printf '%s\n' "$ua"
printf 'OK'
SH
chmod +x "$unit_tmp_fetch/mock_curl.sh"
# create a UA list
printf 'UA-One\nUA-Two\n' > "$unit_tmp_fetch/uas.txt"
export CURL_CMD="$unit_tmp_fetch/mock_curl.sh"
export UA_ROTATE=true
export UA_LIST_PATH="$unit_tmp_fetch/uas.txt"
# call fetch.sh and capture output
out=$(sh scripts/fetch.sh 'http://example/' 1 2 2>/dev/null || true)
# expect one of UA-One or UA-Two in the header line
if echo "$out" | grep -q -E 'User-Agent:.*UA-(One|Two)'; then
  echo "PASS: fetch.sh UA rotation used";
else
  echo "FAIL: fetch.sh UA rotation didn't set header"; fail=1
fi

# Unit test: fetch.sh robots.txt blocking
echo "[TEST] fetch.sh: robots.txt block behaviour"
unit_tmp_robots="$tmp/robots_test"
rm -rf "$unit_tmp_robots"
mkdir -p "$unit_tmp_robots"
cat > "$unit_tmp_robots/mock_curl_robots.sh" <<'SH'
#!/bin/sh
# mock curl for robots: if URL ends with /robots.txt print Disallow: /jobs, else print page content
# portable last-arg capture
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
export CURL_CMD="$unit_tmp_robots/mock_curl_robots.sh"
export VERIFY_ROBOTS=true
# fetch a jobs URL - should be blocked (exit code 2)
if sh scripts/fetch.sh 'http://example/jobs' 1 2 > /dev/null 2>&1; then
  echo "FAIL: fetch.sh should have been blocked by robots.txt"; fail=1
else
  echo "PASS: fetch.sh honoured robots.txt and blocked the URL"
fi
# cleanup
unset CURL_CMD UA_ROTATE UA_LIST_PATH VERIFY_ROBOTS
rm -rf "$unit_tmp_fetch" "$unit_tmp_robots"

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

# Unit test: paginate.sh random delay and SLEEP_CMD override
echo "[TEST] paginate.sh: uses SLEEP_CMD and random delay range"
# Create a mock fetch that returns two pages with Next marker then a final page without it
cat > "$tmp/mock_fetch2.sh" <<'SH'
#!/bin/sh
# cycle through page responses stored in files; maintain a counter
COUNTER_FILE="$PWD/mock_fetch2.counter"
count=1
if [ -f "$COUNTER_FILE" ]; then
  count=$(cat "$COUNTER_FILE" | tr -d '[:space:]' || echo 1)
fi
if [ "$count" -eq 1 ]; then
  printf '<html><body>page1<span data-automation="page-next"></span></body></html>'
elif [ "$count" -eq 2 ]; then
  printf '<html><body>page2<span data-automation="page-next"></span></body></html>'
else
  printf '<html><body>page3</body></html>'
fi
count=$((count+1))
printf '%s' "$count" > "$COUNTER_FILE"
SH
chmod +x "$tmp/mock_fetch2.sh"
# Mock sleep command records the value
cat > "$tmp/mock_sleep.sh" <<'SH'
#!/bin/sh
printf '%s' "$1" > "$PWD/mock_sleep.called"
exit 0
SH
chmod +x "$tmp/mock_sleep.sh"
# Ensure deterministic delay by setting DELAY_MIN and DELAY_MAX the same
export DELAY_MIN=2
export DELAY_MAX=2
FETCH_SCRIPT="$tmp/mock_fetch2.sh" SLEEP_CMD="$tmp/mock_sleep.sh" sh "$tmp/paginate.sh" 'http://x' 'PAG_PAGE' > "$tmp/paginate2.out" || true
# check for any mock_sleep.called file (the mock writes to its $PWD)
sleep_file="$(find . -maxdepth 2 -name 'mock_sleep.called' -print -quit || true)"
if [ -n "$sleep_file" ]; then
  called=$(cat "$sleep_file")
  case "$called" in
    2|2.000|2.0000|2.0) echo "PASS: paginate used SLEEP_CMD with expected delay";;
    *) echo "FAIL: paginate sleep value unexpected: $called"; fail=1;;
  esac
else
  echo "FAIL: paginate did not call SLEEP_CMD"; fail=1
fi
rm -f "$tmp/mock_fetch2.counter" "$tmp/mock_sleep.called" || true
rm -f "$tmp/mock_fetch2.sh" "$tmp/mock_sleep.sh"

# Unit test: paginate honors custom PAGE_NEXT_MARKER env var
echo "[TEST] paginate.sh: custom PAGE_NEXT_MARKER is honoured"
cat > "$tmp/mock_fetch3.sh" <<'SH'
#!/bin/sh
# Return page with custom marker once then a page without (robust /tmp flag)
FLAGFILE="/tmp/mock_fetch3_called_$$"
if [ ! -f "$FLAGFILE" ]; then
  printf '<html><body>first <span data-automation="NEXT-MY"></span></body></html>'
  touch "$FLAGFILE"
else
  printf '<html><body>final</body></html>'
fi
SH
chmod +x "$tmp/mock_fetch3.sh"
PAGE_NEXT_MARKER='data-automation="NEXT-MY"'
FETCH_SCRIPT="$tmp/mock_fetch3.sh" sh "$tmp/paginate.sh" 'http://x' 'PAG_PAGE' > "$tmp/paginate3.out" || true
grep -q 'first' "$tmp/paginate3.out" || { echo "FAIL: paginate did not process custom marker"; fail=1; }
rm -f "$tmp/mock_fetch3.sh" "$tmp/paginate3.out" /tmp/mock_fetch3_called_* || true

# Unit test: archive_artifacts (archival)
echo "[TEST] archive_artifacts: creates snapshot, checksum and index"
unit_tmp_archive="$tmp/archive_test"
rm -rf "$unit_tmp_archive"
mkdir -p "$unit_tmp_archive/subdir"
# create sample files
printf 'hello' > "$unit_tmp_archive/file1.txt"
printf 'world' > "$unit_tmp_archive/subdir/file2.txt"
# Use an isolated snapshot dir
export SNAPSHOT_DIR="$unit_tmp_archive/snapshots"
# Run archive wrapper with explicit paths
sh "$REPO_ROOT/scripts/archive.sh" "$unit_tmp_archive/file1.txt" "$unit_tmp_archive/subdir" || { echo "FAIL: archive.sh failed"; fail=1; }
# Check snapshot created
snap_file=$(find "$unit_tmp_archive/snapshots" -maxdepth 1 -name 'snap-*' -type f -print0 -quit | xargs -0 basename 2>/dev/null || true)
if [ -z "$snap_file" ]; then
  echo "FAIL: no snapshot produced"; fail=1
else
  echo "Produced snapshot: $snap_file"
  # Check checksum exists
  if [ ! -f "$unit_tmp_archive/snapshots/checksums/${snap_file}.sha1" ]; then
    echo "FAIL: checksum missing for $snap_file"; fail=1
  fi
  # Check index contains entry
  grep -q "$snap_file" "$unit_tmp_archive/snapshots/index" || { echo "FAIL: index missing snapshot entry"; fail=1; }
  # Verify checksum if tool available
  if command -v sha1sum >/dev/null 2>&1; then
    (cd "$unit_tmp_archive/snapshots" && sha1sum -c "checksums/${snap_file}.sha1" >/dev/null 2>&1) || { echo "FAIL: sha1sum check failed"; fail=1; }
  else
    echo "WARN: sha1sum not available - skipping checksum verification"
  fi
fi
# Cleanup unit tmp
rm -rf "$unit_tmp_archive"

# Unit test: cleanup_tmp (garbage collection)
echo "[TEST] cleanup_tmp: removes contents of tmp path"
unit_tmp_clean="$tmp/cleanup_test"
rm -rf "$unit_tmp_clean"
mkdir -p "$unit_tmp_clean/subdir"
# create files
printf 'a' > "$unit_tmp_clean/fileA.tmp"
printf 'b' > "$unit_tmp_clean/subdir/fileB.tmp"
# Run cleanup (default behaviour: remove contents but keep dir)
sh "$REPO_ROOT/scripts/cleanup.sh" "$unit_tmp_clean" || { echo "FAIL: cleanup.sh failed"; fail=1; }
# Verify contents removed
if [ -n "$(find "$unit_tmp_clean" -mindepth 1 -print -quit)" ]; then
  echo "FAIL: cleanup did not remove contents of $unit_tmp_clean"; fail=1
fi
rm -rf "$unit_tmp_clean"

# Unit test: summarise (summary.txt generation)
echo "[TEST] generate_summary: writes summary.txt with expected fields"
unit_tmp_summ="$tmp/summarise_test"
rm -rf "$unit_tmp_summ"
mkdir -p "$unit_tmp_summ/snapshots"
# create a small archive
printf 'x' > "$unit_tmp_summ/fileA"
( cd "$unit_tmp_summ" && tar -czf snapshots/snap-test.tar.gz fileA )
# ensure logs and calllists
mkdir -p "$unit_tmp_summ/data/calllists"
printf 'company\n' > "$unit_tmp_summ/data/calllists/calllist_2025-12-24.csv"
mkdir -p "$unit_tmp_summ/logs"
printf 'WARN: something happened\nINFO: ok\n' > "$unit_tmp_summ/logs/log.txt"
export SNAPSHOT_DIR="$unit_tmp_summ/snapshots"
# point project dirs to our test directories for summarise to see
# copy calllists and logs into repo-relative locations
rm -rf data/calllists logs || true
cp -r "$unit_tmp_summ/data" .
cp -r "$unit_tmp_summ/logs" .
# run summarise
sh "$REPO_ROOT/scripts/summarise.sh" --out "$unit_tmp_summ/summary.txt" || { echo "FAIL: summarise.sh failed"; fail=1; }
# Check file exists and has expected fields
if [ ! -f "$unit_tmp_summ/summary.txt" ]; then
  echo "FAIL: summary.txt not created"; fail=1
else
  grep -q 'latest_snapshot' "$unit_tmp_summ/summary.txt" || { echo "FAIL: summary missing latest_snapshot"; fail=1; }
  grep -q 'archived_files_count' "$unit_tmp_summ/summary.txt" || { echo "FAIL: summary missing archived_files_count"; fail=1; }
  grep -q 'calllists_count' "$unit_tmp_summ/summary.txt" || { echo "FAIL: summary missing calllists_count"; fail=1; }
  grep -q 'log_warnings' "$unit_tmp_summ/summary.txt" || { echo "FAIL: summary missing log_warnings"; fail=1; }
fi

# Unit test: retry_with_backoff (retries + backoff)
echo "[TEST] retry_with_backoff: retries and succeeds after intermittent failures"
unit_retry="$tmp/retry_test"
rm -rf "$unit_retry"
mkdir -p "$unit_retry"
cat > "$unit_retry/failer.sh" <<'SH'
#!/bin/sh
# fails twice then succeeds
countfile="$PWD/failer.count"
count=0
if [ -f "$countfile" ]; then
  count=$(cat "$countfile" | tr -d '[:space:]' || echo 0)
fi
count=$((count + 1))
printf '%s' "$count" > "$countfile"
if [ "$count" -lt 3 ]; then
  echo "failing attempt $count" >&2
  exit 1
else
  echo "succeeding attempt $count"
  exit 0
fi
SH
chmod +x "$unit_retry/failer.sh"
# shellcheck disable=SC1091
. "$REPO_ROOT/scripts/lib/error.sh"
# run retry; 5 attempts should be enough
if ! retry_with_backoff 5 "$unit_retry/failer.sh"; then
  echo "FAIL: retry_with_backoff did not recover"; fail=1
else
  echo "PASS: retry_with_backoff recovered"
fi
rm -rf "$unit_retry"

# Unit test: healer preserve & restore
echo "[TEST] heal: preserve_failed_artifacts and restore_latest_snapshot"
unit_heal="$tmp/heal_test"
rm -rf "$unit_heal"
mkdir -p "$unit_heal/data"
printf 'hello' > "$unit_heal/data/seed.txt"
# create a snapshot where the heal functions will look for it
mkdir -p "$unit_heal/.snapshots"
( cd "$unit_heal" && tar -czf .snapshots/snap-test2.tar.gz data )
# ensure SNAPSHOT_DIR points to the test snapshots
# shellcheck disable=SC1091
# Ensure SNAPSHOT_DIR points to the test snapshots
export SNAPSHOT_DIR="$unit_heal/.snapshots"
. "$REPO_ROOT/scripts/lib/heal.sh"
# preserve artifacts
mkdir -p tmp
printf 'failed' > tmp/test.step.status
preserve_failed_artifacts test.step
if [ -z "$(find "$SNAPSHOT_DIR/failed" -name 'failed-test.step-*' -print -quit)" ]; then
  echo "FAIL: preserve_failed_artifacts did not create failed tarball"; fail=1
else
  echo "PASS: preserve_failed_artifacts created failed tarball"
fi
# restore snapshot
restore_dir=$(restore_latest_snapshot)
[ -d "$restore_dir" ] || { echo "FAIL: restore_latest_snapshot did not create dir"; fail=1; }
[ -f "$restore_dir/data/seed.txt" ] || { echo "FAIL: restore_latest_snapshot missing file"; fail=1; }
rm -rf "$unit_heal" "$SNAPSHOT_DIR" tmp

# Unit test: attempt_recover_step (re-run success)
echo "[TEST] attempt_recover_step: runs provided recovery command and logs success"
mkdir -p tmp
# shellcheck disable=SC1091
if ! . "$REPO_ROOT/scripts/lib/heal.sh"; then
  echo "FAIL: sourcing heal.sh"; fail=1
fi
# provide a simple success command
attempt_recover_step unitstep "sh -c 'printf recovered > tmp/heal_recovered.txt; exit 0'"
if [ ! -f tmp/heal_recovered.txt ]; then
  echo "FAIL: attempt_recover_step did not run recovery command"; fail=1
else
  grep -q 'HEAL: re-run succeeded' logs/log.txt || { echo "FAIL: heal log missing success entry"; fail=1; }
  echo "PASS: attempt_recover_step re-ran command and logged success"
fi
rm -rf tmp logs || true

# cleanup
rm -rf "$unit_tmp_summ" data logs

# Integration test: end-sequence orchestrator
echo "[TEST] end-sequence: full integration (archive, cleanup, summarise)"
unit_tmp_end="$tmp/endseq_test"
rm -rf "$unit_tmp_end"
mkdir -p "$unit_tmp_end"
# Backup existing data/calllists and logs if present
if [ -d data/calllists ]; then
  mv data/calllists "$unit_tmp_end/calllists.bak"
fi
if [ -d logs ]; then
  mv logs "$unit_tmp_end/logs.bak"
fi
# Prepare test data
mkdir -p data/calllists
mkdir -p logs
printf 'company\n' > data/calllists/calllist_test.csv
printf 'WARN: test warning\n' > logs/log.txt
# create tmp files to be cleaned
mkdir -p tmp
printf 'temp' > tmp/tempfile.txt
export SNAPSHOT_DIR="$REPO_ROOT/.snapshots_test"
# Run end-sequence via bin/elvis-run
sh "$REPO_ROOT/bin/elvis-run" end-sequence || { echo "FAIL: bin/elvis-run end-sequence failed"; fail=1; }
# Check snapshot created
snap_file=""
for file in "$SNAPSHOT_DIR"/snap-*; do
    if [ -f "$file" ]; then
        snap_file="${file##*/}"
        break
    fi
done
[ -n "$snap_file" ] || { echo "FAIL: end-sequence did not create snapshot"; fail=1; }
# Check tmp cleaned (ignore step status files created by safe_run)
non_status="$(find tmp -maxdepth 1 -mindepth 1 ! -name '*.status' -print -quit 2>/dev/null || true)"
if [ -n "$non_status" ]; then
  echo "FAIL: tmp not cleaned by end-sequence (remaining: $non_status)"; fail=1
fi
# Check summary.txt exists
[ -f summary.txt ] || { echo "FAIL: summary.txt not produced"; fail=1; }
# Check final log contains success message
grep -q 'END-SEQUENCE: completed successfully' logs/log.txt || { echo "FAIL: end-sequence success not logged"; fail=1; }
# Restore backups
rm -rf data/calllists logs || true
if [ -d "$unit_tmp_end/calllists.bak" ]; then
  mv "$unit_tmp_end/calllists.bak" data/calllists
fi
if [ -d "$unit_tmp_end/logs.bak" ]; then
  mv "$unit_tmp_end/logs.bak" logs
fi
# cleanup snapshot test dir
rm -rf "$unit_tmp_end" .snapshots_test
unit_tmp_validate="$tmp/validate_test"
mkdir -p "$unit_tmp_validate"
cat > "$unit_tmp_validate/input.csv" <<CSV
company_name,prospect_name,title,phone,email,location
GoodCo,John,MD,+61410000000,john@good.co,Perth,WA
,,Owner,0412223333,owner@nocomp.com,Sydney,VIC
NoContact,Jane,HR,, ,Brisbane,QLD
BadEmail,Bob,CTO,,not-an-email,Melbourne,VIC
CommaLoc,Alan,CEO,0413444444,,Adelaide,SA
MobilePlus61,Tim,Sales,+61 412 345 678,,Perth,WA
CSV

# Run validation
sh scripts/validate.sh "$unit_tmp_validate/input.csv" --out "$unit_tmp_validate/out.csv" || { echo "FAIL: validate.sh failed"; fail=1; }

# Check output contains only GoodCo and CommaLoc
grep -q 'GoodCo' "$unit_tmp_validate/out.csv" || { echo "FAIL: GoodCo missing in validate out"; fail=1; }
# Check mobile +61 normalisation (MobilePlus61 -> 0412345678)
grep -q '0412345678' "$unit_tmp_validate/out.csv" || { echo "FAIL: +61 mobile normalisation failed"; fail=1; }
grep -q 'CommaLoc' "$unit_tmp_validate/out.csv" || { echo "FAIL: CommaLoc missing in validate out"; fail=1; }
# Ensure NoCompany, NoContact and BadEmail are excluded
grep -q 'NoCompany' "$unit_tmp_validate/out.csv" && { echo "FAIL: NoCompany should be excluded"; fail=1; }
grep -q 'NoContact' "$unit_tmp_validate/out.csv" && { echo "FAIL: NoContact should be excluded"; fail=1; }
grep -q 'BadEmail' "$unit_tmp_validate/out.csv" && { echo "FAIL: BadEmail should be excluded"; fail=1; }
# Check phone normalisation (+61 -> 0)
grep -q '0410000000' "$unit_tmp_validate/out.csv" || { echo "FAIL: phone normalisation failed"; fail=1; }

# Clean up
rm -rf "$unit_tmp_validate"

# Unit test: is_dup_company.sh checks (history/dedupe)
echo "[TEST] is_dup_company.sh: case-insensitive history lookup"
unit_tmp_hist="$tmp/isdup_test"
rm -rf "$unit_tmp_hist"
mkdir -p "$unit_tmp_hist"
printf 'ACME Ltd\nSomeOtherCo\n' > "$unit_tmp_hist/history.txt"
# exact case-insensitive match
if sh scripts/lib/is_dup_company.sh 'acme ltd' "$unit_tmp_hist/history.txt" | grep -q TRUE; then
  echo "PASS: is_dup_company detected existing company (case-insensitive)"
else
  echo "FAIL: is_dup_company failed to detect company"; fail=1
fi
# non-existing company
if sh scripts/lib/is_dup_company.sh 'NewCo' "$unit_tmp_hist/history.txt" | grep -q FALSE; then
  echo "PASS: is_dup_company correctly reports missing company"
else
  echo "FAIL: is_dup_company false positive"; fail=1
fi
rm -rf "$unit_tmp_hist"

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
CALLFILE=""
for f in "$tmp/calllists"/calllist_*; do
  if [ -e "$f" ]; then
    CALLFILE="${f##*/}"
    break
  fi
done
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
