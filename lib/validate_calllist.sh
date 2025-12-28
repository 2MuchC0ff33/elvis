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
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CALLLIST="$ROOT/home/calllist.txt"
HISTORY="$ROOT/srv/company_history.txt"

if [ ! -s "$CALLLIST" ]; then
  echo "FAIL: $CALLLIST does not exist or is empty" >&2
  exit 2
fi

# Check format and cleanliness
bad_lines=$(awk -F"|" 'NF<2 {print NR":"$0}' "$CALLLIST" | wc -l | tr -d ' ')
if [ "$bad_lines" != "0" ]; then
  echo "FAIL: $bad_lines malformed lines in $CALLLIST" >&2
  awk -F"|" 'NF<2 {print NR":"$0}' "$CALLLIST" >&2
  exit 3
fi

# ensure companies and locations are non-empty and clean
awk -F"|" '{gsub(/^[ \t]+|[ \t]+$/,"",$1); gsub(/^[ \t]+|[ \t]+$/,"",$2); if($1==""||$2=="") {print NR":"$0}}' "$CALLLIST" | if read x; then
  echo "FAIL: empty company or location on lines:" >&2
  awk -F"|" '{gsub(/^[ \t]+|[ \t]+$/,"",$1); gsub(/^[ \t]+|[ \t]+$/,"",$2); if($1==""||$2=="") print NR":"$0}' "$CALLLIST" >&2
  exit 4
fi

# check for trailing angle brackets or control chars
awk -F"|" '{c=$1; gsub(/[[:cntrl:]<>]+$/,"",c); if(c!=$1) print NR":"$0}' "$CALLLIST" | if read x; then
  echo "FAIL: trailing control chars or angle brackets present" >&2
  awk -F"|" '{c=$1; gsub(/[[:cntrl:]<>]+$/,"",c); if(c!=$1) print NR":"$0}' "$CALLLIST" >&2
  exit 5
fi

# uniqueness check (case-insensitive)
uniq_count=$(awk -F"|" '{print tolower($1)}' "$CALLLIST" | sort -u | wc -l | tr -d ' ')
line_count=$(wc -l < "$CALLLIST" | tr -d ' ')

if [ "$uniq_count" -lt 5 ] || [ "$line_count" -lt 5 ]; then
  echo "FAIL: expected at least 5 unique companies; got $uniq_count unique / $line_count lines" >&2
  exit 6
fi

# All good
echo "PASS: $CALLLIST contains $line_count lines with $uniq_count unique companies"
exit 0
