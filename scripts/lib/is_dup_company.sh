#!/bin/sh
# scripts/lib/is_dup_company.sh
# Check if a company name exists in companies_history.txt (case-insensitive)
# Usage: is_dup_company.sh "Company Name" [history_file]

set -eu
COMPANY="${1:-}"
HISTORY_FILE="${2:-companies_history.txt}"

if [ -z "$COMPANY" ]; then
  echo "ERROR: company name required" >&2
  exit 2
fi
if [ ! -f "$HISTORY_FILE" ]; then
  echo "FALSE"
  exit 0
fi
lc_company=$(printf '%s' "$COMPANY" | tr '[:upper:]' '[:lower:]' | sed 's/^ *//;s/ *$//')
if grep -i -Fx -q "$COMPANY" "$HISTORY_FILE"; then
  echo "TRUE"
  exit 0
fi
if tr '[:upper:]' '[:lower:]' < "$HISTORY_FILE" | grep -Fx -q "$lc_company"; then
  echo "TRUE"
  exit 0
fi
echo "FALSE"
exit 0
