#!/bin/sh
# scripts/dedupe_status.sh
# Compatibility wrapper that delegates to scripts/deduper.sh
# Usage preserved: dedupe_status.sh input.csv --out deduped.csv [--append-history]

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

# Delegate to new deduper
if [ "$APPEND_HISTORY" = true ]; then
  sh scripts/deduper.sh --in "$INPUT" --out "$OUT" --append-history
else
  sh scripts/deduper.sh --in "$INPUT" --out "$OUT"
fi

exit 0
