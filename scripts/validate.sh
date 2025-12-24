#!/bin/sh
# scripts/validate.sh
# Validate and normalise a CSV of records.
# Usage: validate.sh input.csv --out validated.csv

set -eu

INPUT="${1:-}"
OUT=""

EMAIL_REGEX='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}'

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "Usage: $0 <input.csv> --out <validated.csv>" >&2
  exit 2
fi

# parse --out
shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out)
      shift
      OUT="$1"
      ;;
    *)
      ;;
  esac
  shift || true
done

if [ -z "$OUT" ]; then
  echo "ERROR: --out <file> required" >&2
  exit 2
fi

# Ensure header contains required fields
header=$(head -n1 "$INPUT" | tr -d '\r')
# Check required columns exist (POSIX sh compatible)
for col in company_name prospect_name title phone email location; do
  echo "$header" | grep -q "$col" || { echo "ERROR: missing column: $col" >&2; exit 2; }
done

# Process rows: normalise phone, validate fields, emit to OUT only valid rows
awk -v email_re="$EMAIL_REGEX" -f scripts/lib/validator.awk "$INPUT" > "$OUT" || {
  echo "ERROR: validation failed; see stderr for details" >&2
  exit 3
}

echo "Validation succeeded: output -> $OUT"
exit 0
