#!/bin/sh
# scripts/set_status.sh
# Orchestrate the set-status workflow: enrichment -> validation -> dedupe -> output -> logging
# Usage: set_status.sh [--input results.csv] [--enriched enriched.csv] [--out-dir data/calllists] [--dry-run] [--commit-history]

set -eu

INPUT="results.csv"
ENRICHED=""
OUT_DIR="data/calllists"
DRY_RUN=false
COMMIT_HISTORY=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      shift; INPUT="$1";;
    --enriched)
      shift; ENRICHED="$1";;
    --out-dir)
      shift; OUT_DIR="$1";;
    --dry-run)
      DRY_RUN=true;;
    --commit-history)
      COMMIT_HISTORY=true;;
    *) ;;
  esac
  shift || true
done

if [ ! -f "$INPUT" ]; then
  echo "ERROR: input file not found: $INPUT" >&2
  exit 2
fi

mkdir -p "$OUT_DIR" tmp

# Step 1: Enrichment
if [ -n "$ENRICHED" ]; then
  echo "Using provided enriched file: $ENRICHED"
  cp -f "$ENRICHED" tmp/enriched.csv
else
  # Prepare enrichment template and instruct admin to edit
  sh scripts/enrich_status.sh "$INPUT" tmp/enriched.csv --edit
  echo "Please run this command after enrichment completes: sh scripts/set_status.sh --input $INPUT --enriched tmp/enriched.csv [--commit-history]"
  [ "$DRY_RUN" = true ] && exit 0
fi

# Step 2: Validation
sh scripts/validate.sh tmp/enriched.csv --out tmp/validated.csv

# Step 3: Deduplication
if [ "$COMMIT_HISTORY" = true ]; then
  sh scripts/deduper.sh --in tmp/validated.csv --out tmp/deduped.csv --append-history
else
  sh scripts/deduper.sh --in tmp/validated.csv --out tmp/deduped.csv
fi

# Step 4: Produce daily CSV
ts=$(date -u +"%F")
OUTFILE="$OUT_DIR/calllist_$ts.csv"
cp tmp/deduped.csv "$OUTFILE"

echo "Produced calllist: $OUTFILE"

# Step 5: Logging & Audit
sh scripts/log_status.sh --input "$OUTFILE" --msg "set-status run" --audit-file audit.txt

exit 0
