#!/bin/sh
# scripts/get_transaction_data.sh
# Orchestrate the get transaction data workflow: normalise, split, load seeds, detect route, paginate, fetch
#
# Note: We intentionally use POSIX sh constructs only. Some static analysers
# (ShellCheck) may report false-positives about sourcing and arrays when
# tools cannot follow dynamically computed paths. Disable those specific
# warnings here to avoid noise while keeping the script portable.
# shellcheck disable=SC2240,SC3053,SC3055,SC3054,SC1091

set -eu
# Load environment and project config if available (non-fatal)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$(dirname "$0")/lib/load_env.sh" ]; then . "$(dirname "$0")/lib/load_env.sh" "$REPO_ROOT/.env"; fi
if [ -f "$(dirname "$0")/lib/load_config.sh" ]; then sh "$(dirname "$0")/lib/load_config.sh" "$REPO_ROOT/project.conf"; fi
if [ -f "$(dirname "$0")/lib/load_seek_pagination.sh" ]; then sh "$(dirname "$0")/lib/load_seek_pagination.sh" "$REPO_ROOT/configs/seek-pagination.ini"; fi

SEEDS_FILE="${1:-data/seeds/seeds.csv}"
TMP_DIR="tmp"
NORM_FILE="$TMP_DIR/seeds.normalized.csv"
RECORDS_DIR="$TMP_DIR/records"
mkdir -p "$TMP_DIR" "$RECORDS_DIR"

# 1. Normalise seeds.csv
awk -f "$(dirname "$0")/lib/normalize.awk" "$SEEDS_FILE" > "$NORM_FILE"
echo "INFO: Normalised seeds to $NORM_FILE"

# 2. Split into per-record .txt files
sh "$(dirname "$0")/lib/split_records.sh" "$NORM_FILE" "$RECORDS_DIR"
echo "INFO: Split records to $RECORDS_DIR/"

# 3. Load seeds and process each
# Validate the normalised seeds file and ensure there are seeds to process
if [ ! -r "$NORM_FILE" ]; then
  echo "ERROR: Normalised seeds file not found or unreadable: $NORM_FILE" >&2
  exit 1
fi

seed_count=$(awk -F',' 'NR>1 && $1!="" {c++} END{print c+0}' "$NORM_FILE")
if [ "$seed_count" -eq 0 ]; then
  echo "WARN: No seeds found in $NORM_FILE"
  exit 0
fi

# Extract seed_id and base_url and iterate in POSIX sh (no arrays, no indirect expansion)
awk -F',' -f "$(dirname "$0")/lib/extract_seeds.awk" "$NORM_FILE" | while IFS='|' read -r seed_id base_url; do
  model=$(sh "$(dirname "$0")/lib/pick_pagination.sh" "$base_url")
  echo "INFO: [$seed_id] Using model $model for $base_url"
  sh "$(dirname "$0")/lib/paginate.sh" "$base_url" "$model" > "$TMP_DIR/${seed_id}.htmls"
  echo "INFO: [$seed_id] Pages saved to $TMP_DIR/${seed_id}.htmls"
done
