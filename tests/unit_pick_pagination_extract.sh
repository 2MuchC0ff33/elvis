#!/bin/sh
# tests/unit_pick_pagination_extract.sh
# Tests pick_pagination.sh and extract_seeds.awk

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

out=$(sh "$REPO_ROOT/scripts/lib/pick_pagination.sh" 'https://seek.com.au/jobs?foo')
[ "$out" = "PAG_START" ] || { echo "FAIL: pick_pagination PAG_START" >&2; exit 1; }

out2=$(sh "$REPO_ROOT/scripts/lib/pick_pagination.sh" 'https://seek.com.au/software-developer-jobs/in-Perth-WA')
[ "$out2" = "PAG_PAGE" ] || { echo "FAIL: pick_pagination PAG_PAGE got $out2" >&2; exit 1; }

# extract_seeds simple parse
unit_tmp="$(mktemp -d 2>/dev/null || mktemp -d -t seeds)"
cat > "$unit_tmp/norm.csv" <<CSV
seed_id,location,base_url
seek_fifo_perth,Perth,https://www.seek.com.au/fifo-jobs/in-All-Perth-WA
foo,Bar,https://example.com/jobs
CSV

awk -F',' -f "$REPO_ROOT/scripts/lib/extract_seeds.awk" "$unit_tmp/norm.csv" > "$unit_tmp/out.txt" || { echo "FAIL: extract_seeds.awk" >&2; exit 1; }
grep -q 'seek_fifo_perth|https://www.seek.com.au/fifo-jobs/in-All-Perth-WA' "$unit_tmp/out.txt" || { echo "FAIL: extract_seeds.awk missing seek_fifo_perth" >&2; exit 1; }

rm -rf "$unit_tmp"

echo "PASS: unit_pick_pagination_extract"
exit 0
