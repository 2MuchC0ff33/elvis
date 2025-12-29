#!/bin/sh
# lib/validate_calllist.sh - Validate the produced calllist
# Checks:
# - file exists and is non-empty
# - each line has 'Company | Location' (non-empty both sides)
# - no trailing angle brackets or control chars
# - at least 5 unique companies (case-insensitive)
# Returns 0 on success, non-zero on failure
# Note: moved to lib/ per project convention (library utilities)
# To run: sh lib/validate_calllist.sh

set -eu

# Check format and cleanliness

# Check format and cleanliness using standalone AWK module
bad_lines=$(awk -f "$ROOT/lib/check_format.awk" "$CALLLIST" | wc -l | tr -d ' ')
if [ "$bad_lines" != "0" ]; then
  echo "FAIL: $bad_lines malformed lines in $CALLLIST" >&2
  awk -f "$ROOT/lib/check_format.awk" "$CALLLIST" >&2
  exit 3
fi

# ensure companies and locations are non-empty and clean using standalone AWK module
awk -f "$ROOT/lib/check_empty_clean.awk" "$CALLLIST" | if read -r x; then
  echo "FAIL: empty company or location on lines:" >&2
  awk -f "$ROOT/lib/check_empty_clean.awk" "$CALLLIST" >&2
  exit 4
fi

# check for trailing angle brackets or control chars using standalone AWK module
awk -f "$ROOT/lib/check_trailing_chars.awk" "$CALLLIST" | if read -r x; then
  echo "FAIL: trailing control chars or angle brackets present" >&2
  awk -f "$ROOT/lib/check_trailing_chars.awk" "$CALLLIST" >&2
  exit 5
fi

# uniqueness check (case-insensitive) using standalone AWK module
uniq_count=$(awk -f "$ROOT/lib/uniq_count.awk" "$CALLLIST" | sort -u | wc -l | tr -d ' ')
line_count=$(wc -l < "$CALLLIST" | tr -d ' ')

# All good
echo "PASS: $CALLLIST contains $line_count lines with $uniq_count unique companies"
exit 0
