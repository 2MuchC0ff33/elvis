#!/bin/sh
# scripts/parse.sh
# Minimal parser that extracts job card fields from saved HTML pages and emits CSV
# Usage: parse.sh input.htmls --out output.csv

set -eu

INPUT="$1"
OUT=""
shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out)
      shift; OUT="$1";;
    *) ;;
  esac
  shift || true
done

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "ERROR: input file missing" >&2
  exit 2
fi
if [ -z "$OUT" ]; then
  echo "ERROR: --out required" >&2
  exit 2
fi

# Write header (add summary and job_id fields)
printf 'company_name,prospect_name,title,phone,email,location,summary,job_id\n' > "$OUT"

# Use external AWK parser for extraction
awk -f "$(dirname "$0")/lib/parser.awk" "$INPUT" >> "$OUT"

echo "Parsed -> $OUT"
exit 0
