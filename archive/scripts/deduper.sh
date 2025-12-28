#!/bin/sh
# scripts/deduper.sh
# Thin wrapper and driver that invokes the AWK deduper to perform
# case-insensitive deduplication of CSV rows against a history file.
# Usage: deduper.sh --in input.csv --out out.csv [--history companies_history.txt] [--append-history]

set -eu

IN=""
OUT=""
HISTORY=""
APPEND_HISTORY=false
# Prefer explicit HISTORY, otherwise use HISTORY_FILE from project.conf/.env
HISTORY="${HISTORY:-${HISTORY_FILE:-}}"
if [ -z "${HISTORY:-}" ]; then
  echo "ERROR: HISTORY or HISTORY_FILE must be set (companies_history.txt)" >&2
  exit 2
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --in)
      shift; IN="$1";;
    --out)
      shift; OUT="$1";;
    --history)
      shift; HISTORY="$1";;
    --append-history)
      APPEND_HISTORY=true;;
    *) ;;
  esac
  shift || true
done

if [ -z "$IN" ] || [ ! -f "$IN" ]; then
  echo "ERROR: input file missing or not found: $IN" >&2
  exit 2
fi
if [ -z "$OUT" ]; then
  echo "ERROR: --out required" >&2
  exit 2
fi

# Prepare temp files
hist_tmp=$(mktemp /tmp/elvis_hist.XXXXXX)
new_tmp=$(mktemp /tmp/elvis_new.XXXXXX)
: > "$new_tmp"

# build lowercased history
if [ -f "$HISTORY" ]; then
  tr '[:upper:]' '[:lower:]' < "$HISTORY" | sed '/^$/d' | sort -u > "$hist_tmp"
else
  : > "$hist_tmp"
fi

# write header
head -n1 "$IN" > "$OUT"

# process rows with AWK (skip header)
# Pass HISTTMP and NEWFILE as AWK variables
TAIL_CMD="tail -n +2 '$IN'"
# Use awk script from scripts/lib/deduper.awk
sh -c "$TAIL_CMD" | awk -F, -v HISTTMP="$hist_tmp" -v NEWFILE="$new_tmp" -f scripts/lib/deduper.awk >> "$OUT"

# append new companies to history if requested
if [ "$APPEND_HISTORY" = true ]; then
  if [ -s "$new_tmp" ]; then
    # uniq and append
    sort -u "$new_tmp" >> "$HISTORY"
  fi
fi

# cleanup
rm -f "$hist_tmp" "$new_tmp"

echo "Deduplication complete: output -> $OUT"
exit 0
