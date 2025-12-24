#!/bin/sh
# scripts/lib/pick_pagination.sh
# Detect pagination model for a given seed URL
# Usage: pick_pagination.sh <url>
# Echoes PAG_START or PAG_PAGE

set -eu
url="${1:-}"
if [ -z "$url" ]; then
  echo "PAG_START"
  exit 0
fi
case "$url" in
  *'/jobs?'*|*'/jobs&'*) echo "PAG_START" ;;
  *'-jobs/in-'*) echo "PAG_PAGE" ;;
  *) echo "PAG_START" ;;
esac
