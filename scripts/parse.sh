#!/bin/sh
# scripts/parse.sh
# Minimal parser that extracts job card fields from saved HTML pages and emits CSV
# Usage: parse.sh input.htmls --out output.csv

set -eu
# Load environment and config if available (non-fatal)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$(dirname "$0")/lib/load_env.sh" ]; then . "$(dirname "$0")/lib/load_env.sh" "$REPO_ROOT/.env"; fi
if [ -f "$(dirname "$0")/lib/load_config.sh" ]; then sh "$(dirname "$0")/lib/load_config.sh" "$REPO_ROOT/project.conf"; fi

INPUT="$1"
OUT=""
shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out)
      shift; OUT="$1";;
    *) ;;
  esac
  shift || true
done

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "ERROR: input file missing" >&2
  exit 2
fi
if [ -z "$OUT" ]; then
  echo "ERROR: --out required" >&2
  exit 2
fi

# Write header (only company_name and location)
printf 'company_name,location\n' > "$OUT"


# Run JSON extractor and emit company,location rows (filter classification-only rows)
json_tmp="${OUT}.json.tmp"
rm -f "$json_tmp"
if awk -f "$(dirname "$0")/lib/parse_seek_json3.awk" "$INPUT" > "$json_tmp" 2>/dev/null; then
  if [ -s "$json_tmp" ]; then
    # Filter out classification-only lines and dedupe exact lines (preserve first occurrence)
    awk '!/^subClassification:/{ if (!seen[$0]++) print }' "$json_tmp" >> "$OUT"
    rm -f "$json_tmp"
  else
    rm -f "$json_tmp"
    # Fallback: use legacy HTML parser and extract company & location (fields 1 & 6)
    awk -f "$(dirname "$0")/lib/parser.awk" "$INPUT" > "${OUT}.awk_full.tmp" || true
    tail -n +2 "${OUT}.awk_full.tmp" | awk -F',' '{print $1","$6}' | awk '!seen[$0]++' >> "$OUT" || true
    rm -f "${OUT}.awk_full.tmp"
  fi
else
  # AWK extractor failed; try Python fallback (if available)
  if command -v python3 >/dev/null 2>&1; then
    python3 "$(dirname "$0")/lib/parse_seek_json.py" "$INPUT" | awk -F',' '{print $1","$6}' >> "$OUT" || true
  else
    echo "WARN: JSON extractor not available (no AWK or Python)" >&2
  fi
fi

echo "Parsed -> $OUT"
exit 0
