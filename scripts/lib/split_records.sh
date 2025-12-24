#!/bin/sh
# scripts/lib/split_records.sh
# Split normalised CSV into per-record .txt files in a target dir
# Usage: split_records.sh <csv_file> <out_dir>

set -eu
csv_file="$1"
out_dir="$2"
[ -f "$csv_file" ] || { echo "Error: $csv_file not found" >&2; exit 1; }
mkdir -p "$out_dir"
first=1
rec=0
while IFS=, read -r seed_id location base_url; do
  if [ $first -eq 1 ]; then first=0; continue; fi
  rec=$((rec+1))
  fname="$out_dir/seed_${rec}.txt"
  printf 'seed_id=%s\nlocation=%s\nbase_url=%s\n' "$seed_id" "$location" "$base_url" > "$fname"
done < "$csv_file"
