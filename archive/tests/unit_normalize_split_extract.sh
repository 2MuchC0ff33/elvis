#!/bin/sh
# tests/unit_normalize_split_extract.sh
# Tests normalize.awk, extract_seeds.awk and split_records.sh behaviour

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t normtest)"
trap 'rm -rf "$tmp"' EXIT

printf 'seed_id,location,base_url\nfoo , Perth , https://x\n' | awk -f "$REPO_ROOT/scripts/lib/normalize.awk" > "$tmp/norm.csv"
grep -q 'foo,Perth,https://x' "$tmp/norm.csv" || { echo "FAIL: normalize.awk basic" >&2; exit 1; }

# quoted location with comma
printf 'seed_id,location,base_url\nseedA,"Town, State",https://example.com/jobs\n' | awk -f "$REPO_ROOT/scripts/lib/normalize.awk" > "$tmp/norm_quoted.csv"
awk -f "$REPO_ROOT/scripts/lib/extract_seeds.awk" "$tmp/norm_quoted.csv" > "$tmp/norm_quoted.out"
grep -q 'seedA|https://example.com/jobs' "$tmp/norm_quoted.out" || { echo "FAIL: normalize.awk quoted location handling" >&2; exit 1; }

# split_records
sh "$REPO_ROOT/scripts/lib/split_records.sh" "$tmp/norm.csv" "$tmp/records" || { echo "FAIL: split_records.sh" >&2; exit 1; }
[ -f "$tmp/records/seed_1.txt" ] || { echo "FAIL: split_records.sh output missing" >&2; exit 1; }

echo "PASS: unit_normalize_split_extract"
exit 0
