#!/bin/sh
# scripts/enrich_status.sh
# Prepare and (optionally) open results.csv for manual enrichment by an admin.
# Usage: enrich_status.sh [--input results.csv] [--out enriched.csv] [--edit]

set -eu

INPUT="${1:-results.csv}"
OUT="${2:-results.enriched.csv}"
EDIT=false

# Support flags style
for arg in "$@"; do
  case "$arg" in
    --input)
      ;;
    --out)
      ;;
    --edit)
      EDIT=true
      ;;
    *)
      ;;
  esac
done

if [ ! -f "$INPUT" ]; then
  echo "ERROR: input file not found: $INPUT" >&2
  exit 2
fi

# Copy to output for editing
cp -f "$INPUT" "$OUT"
chmod 644 "$OUT"

echo "Prepared enrichment file: $OUT"

if [ "$EDIT" = true ]; then
  # Open in editor for manual enrichment
  : "Opening $OUT in editor..."
  ${EDITOR:-vi} "$OUT"
  echo "Edit complete. Please re-run validation: scripts/validate.sh $OUT --out validated.csv"
fi

exit 0
