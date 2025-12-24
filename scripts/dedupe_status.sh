#!/bin/sh
# scripts/dedupe_status.sh
# Deduplicate by company_name (case-insensitive) against companies_history.txt
# Usage: dedupe_status.sh input.csv --out deduped.csv [--append-history]

set -eu

INPUT="$1"
OUT=""
APPEND_HISTORY=false

shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out)
      shift; OUT="$1";;
    --append-history)
      APPEND_HISTORY=true;;
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

HISTORY="companies_history.txt"

# Build history set (lowercased)
awk 'BEGIN{IGNORECASE=1} NR>0{print tolower($0)}' "$HISTORY" 2>/dev/null | sort -u > /tmp/.elvis_hist.tmp || true

# First line is header
head -n1 "$INPUT" > "$OUT"
# Iterate rows and emit only those not in history and dedupe within file
awk -F, 'NR==1{next} {
  comp=$1; gsub(/^ +| +$/,"",comp); l=tolower(comp);
  if (l=="") {next}
  if (seen[l]) next
  # check history
  cmd="grep -Fxq " l " /tmp/.elvis_hist.tmp"
  # use system("grep -Fxq '" l "' /tmp/.elvis_hist.tmp") may be simpler but ensure escaping
  # We'll check in awk using getline
  # For portability: call out to shell
  ret=system("grep -Fxq '\"" l "\'' /tmp/.elvis_hist.tmp")
  if (ret==0) { next }
  seen[l]=1
  print $0
}' "$INPUT" >> "$OUT"

# Append new companies to history if requested
if [ "$APPEND_HISTORY" = true ]; then
  tail -n +2 "$OUT" | awk -F, '{comp=$1; gsub(/^ +| +$/,"",comp); if (comp!="") print comp}' | awk '{print}' >> "$HISTORY"
fi

rm -f /tmp/.elvis_hist.tmp

echo "Deduplication complete: output -> $OUT"
exit 0
