#!/bin/sh
# scripts/dedupe.sh
# Simple user-facing wrapper to call scripts/deduper.sh
# Usage: dedupe.sh input.csv out.csv [--append-history]

set -eu

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 input.csv out.csv [--append-history]" >&2
  exit 2
fi

IN="$1"
OUT="$2"
shift 2
APPEND=""
if [ "$#" -gt 0 ]; then
  case "$1" in
    --append-history)
      APPEND="--append-history";;
    *) ;;
  esac
fi

sh scripts/deduper.sh --in "$IN" --out "$OUT" $APPEND
