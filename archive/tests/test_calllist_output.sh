#!/bin/sh
# tests/test_calllist_output.sh
# Integration-like unit test: run scripts/set_status.sh on a small fixture
# and verify a calllist CSV is produced in the specified out-dir.

set -eu

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t calllist_test)"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/results.csv" <<CSV
company_name,prospect_name,title,phone,email,location
TestCo Pty Ltd,John Doe,Manager,0412345678,john@testco.com.au,"Perth, WA"
CSV
# Use same file as enriched (no-op enrichment)
cp "$tmpdir/results.csv" "$tmpdir/enriched.csv"

# Run set_status with our tmp out-dir (do not commit history)
if ! sh "$(dirname "$0")/../scripts/set_status.sh" --input "$tmpdir/results.csv" --enriched "$tmpdir/enriched.csv" --out-dir "$tmpdir"; then
  echo "FAIL: set_status.sh failed" >&2
  exit 1
fi

# Expect a calllist file in out-dir with today's date
outfile="$tmpdir/calllist_$(date -u +%F).csv"
if [ ! -f "$outfile" ]; then
  echo "FAIL: expected calllist file not found: $outfile" >&2
  exit 1
fi

# Basic sanity checks: header present and our company row present
if ! head -n1 "$outfile" | grep -q "company_name.*phone.*email"; then
  echo "FAIL: calllist header missing or unexpected" >&2
  exit 1
fi
if ! grep -q "TestCo Pty Ltd" "$outfile"; then
  echo "FAIL: expected company row not present in calllist" >&2
  exit 1
fi

# All good
echo "PASS: set_status produced calllist at $outfile"
exit 0
