#!/bin/sh
# scripts/lib/validate_env.sh
# Validate required environment variables for Elvis init
# Usage: . scripts/lib/validate_env.sh

set -eu

# List required variables (update as needed)
REQUIRED_VARS="SEEDS_FILE OUTPUT_DIR HISTORY_FILE LOG_FILE SEEK_PAGINATION_CONFIG"

missing=0
for var in $REQUIRED_VARS; do
  eval val="\${$var:-}"
  if [ -z "$val" ]; then
    echo "Error: Required environment variable '$var' is not set or empty." >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi
