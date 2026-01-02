#!/bin/sh
# scripts/lib/load_seeds.sh
# Load and parse a normalised CSV and print records as pipe-separated lines:
# seed_id|base_url
# Usage: sh scripts/lib/load_seeds.sh [SEEDS_FILE]

set -eu
SEEDS_FILE="${1:-data/seeds/seeds.csv}"
if [ ! -f "$SEEDS_FILE" ]; then
  echo "Error: Seeds file '$SEEDS_FILE' not found." >&2
  exit 1
fi

first=1
# 'location' field in the CSV is intentionally ignored by the pipeline.
# Use '_' as a placeholder to make intent explicit and avoid ShellCheck SC2034.
while IFS=, read -r seed_id _ base_url; do
  if [ "$first" = 1 ]; then
    first=0
    continue
  fi
  [ -z "$seed_id" ] && continue
  printf '%s|%s\n' "$seed_id" "$base_url"
done < "$SEEDS_FILE"
