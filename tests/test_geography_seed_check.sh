#!/bin/sh
# tests/test_geography_seed_check.sh
# Validate that each seed base_url in data/seeds/seeds.csv uses a .com.au domain

set -eu

seeds_file="data/seeds/seeds.csv"
if [ ! -f "$seeds_file" ]; then
  echo "SKIP: $seeds_file not found"; exit 0
fi

# Read CSV skipping header
line_no=0
while IFS= read -r line || [ -n "$line" ]; do
  line_no=$((line_no + 1))
  # skip header
  if [ "$line_no" -eq 1 ]; then
    continue
  fi
  # extract last comma-separated field (base_url). This is robust to commas in middle fields
  url=$(printf '%s' "$line" | sed 's/.*,//' | tr -d '[:space:]')
  [ -z "$url" ] && continue
  # check it contains .com.au (case-insensitive)
  if ! printf '%s' "$url" | grep -qi '\.com\.au\>' ; then
    echo "Invalid seed at line $line_no: not a .com.au domain: $url" >&2
    exit 1
  fi
done < "$seeds_file"

echo "PASS: all seeds use .com.au domains"
exit 0
