#!/bin/sh
# scripts/get_transaction_data.sh
# Orchestrate the get transaction data workflow: normalise, split, load seeds, detect route, paginate, fetch

set -eu
SEEDS_FILE="${1:-data/seeds/seeds.csv}"
TMP_DIR="tmp"
NORM_FILE="$TMP_DIR/seeds.normalized.csv"
RECORDS_DIR="$TMP_DIR/records"
mkdir -p "$TMP_DIR"

# 1. Normalise seeds.csv
awk -f "$(dirname "$0")/lib/normalize.awk" "$SEEDS_FILE" > "$NORM_FILE"
echo "INFO: Normalised seeds to $NORM_FILE"

# 2. Split into per-record .txt files
sh "$(dirname "$0")/lib/split_records.sh" "$NORM_FILE" "$RECORDS_DIR"
echo "INFO: Split records to $RECORDS_DIR/"

# 3. Load seeds and process each (POSIX-friendly: read from load_seeds.sh stdout)
sh "$(dirname "$0")/lib/load_seeds.sh" "$NORM_FILE" | while IFS='|' read -r seed_id base_url; do
  [ -z "$seed_id" ] && continue
  model=$(sh "$(dirname "$0")/lib/pick_pagination.sh" "$base_url")
  echo "INFO: [$seed_id] Using model $model for $base_url"
  sh "$(dirname "$0")/lib/paginate.sh" "$base_url" "$model" > "$TMP_DIR/${seed_id}.htmls"
  echo "INFO: [$seed_id] Pages saved to $TMP_DIR/${seed_id}.htmls"
done
