#!/bin/sh
# tests/integration_set_status.sh
# Integration: run set_status.sh end-to-end on a small fixture

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t setstatus)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/results.csv" <<CSV
company_name,prospect_name,title,phone,email,location
TestCo Pty Ltd,John Doe,Manager,0412345678,john@testco.com.au,"Perth, WA"
DupCo,Jane,Owner,, ,Melbourne, VIC
CSV
cp "$tmp/results.csv" "$tmp/enriched.csv"

# add phone to second row
awk -F, 'BEGIN{OFS=FS} NR==1{print} NR==2{print} NR==3{$4="0412345678"; $5=""; print}' "$tmp/enriched.csv" > "$tmp/enriched2.csv"

sh "$REPO_ROOT/scripts/set_status.sh" --input "$tmp/results.csv" --enriched "$tmp/enriched2.csv" --out-dir "$tmp" --commit-history || { echo "FAIL: set_status.sh failed" >&2; exit 1; }
# find calllist
callfile=$(ls "$tmp"/calllist_* 2>/dev/null | head -n1 || true)
if [ -z "$callfile" ]; then echo "FAIL: calllist not produced" >&2; exit 1; fi
grep -q 'TestCo Pty Ltd' "$callfile" || { echo "FAIL: TestCo missing" >&2; exit 1; }
grep -q 'DupCo' "$callfile" || { echo "FAIL: DupCo missing" >&2; exit 1; }

echo "PASS: integration_set_status"
exit 0
