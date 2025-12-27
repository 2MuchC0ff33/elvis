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

# Write header (add summary and job_id fields)
printf 'company_name,prospect_name,title,phone,email,location,summary,job_id\n' > "$OUT"

# Use external AWK parser for extraction
awk -f "$(dirname "$0")/lib/parser.awk" "$INPUT" >> "$OUT"

# Always run JSON extractor as well to handle modern site structures; merge and dedupe by job_id
json_tmp="${OUT}.json.tmp"
merged_tmp="${OUT}.merged.tmp"
rm -f "$json_tmp" "$merged_tmp"
if awk -f "$(dirname "$0")/lib/parse_seek_json3.awk" "$INPUT" > "$json_tmp" 2>/dev/null; then
  if [ -s "$json_tmp" ]; then
    # Merge: preserve header, then unique by last field (job_id)
    tail -n +2 "$OUT" > "${OUT}.awkrows.tmp" || true
    tail -n +1 "$json_tmp" > "${OUT}.jsonrows.tmp" || true
    # Combine and unique by job_id (last comma-separated field), prefer JSON extractor (jsonrows first)
    # Prefer rows where company_name does NOT start with "subClassification:" and where title is present
    (cat "${OUT}.jsonrows.tmp" "${OUT}.awkrows.tmp" | \
      awk '
        {
          line = $0
          # extract job_id as trailing numeric field (handles commas inside quoted fields)
          if (match(line, /,([0-9]+)[[:space:]]*$/, m)) {
            id = m[1]
          } else {
            next
          }
          if (!seen[id]++) {
            order[++n]=id
            best[id]=line
            has_sub[id]=(line ~ /^subClassification:/)
            # extract title field (3rd field) naive: allow for quoted fields by taking between first two commas and the third comma
            title=""
            if (match(line, /^[^,]*,[^,]*,(("[^"]*"|[^,]*)).*/, t)) {
              title = t[1]
            }
            has_title[id] = (title != "")
          } else {
            # if existing is subClassification and this one is better, replace
            if (has_sub[id] && (line !~ /^subClassification:/)) {
              best[id]=line; has_sub[id]=0
              if (!has_title[id] && match(line, /^[^,]*,[^,]*,(("[^"]*"|[^,]*)).*/, t2)) { if (t2[1]!="") has_title[id]=1 }
            } else if (!has_sub[id] && !has_title[id] && match(line, /^[^,]*,[^,]*,(("[^"]*"|[^,]*)).*/, t3)) {
              if (t3[1] != "") { best[id]=line; has_title[id]=1 }
            }
          }
        }
        END { for (i=1;i<=n;i++) print best[order[i]] }
      '
    ) > "$merged_tmp" || true
    # Write header and merged unique rows
    printf 'company_name,prospect_name,title,phone,email,location,summary,job_id
' > "$OUT"
    cat "$merged_tmp" >> "$OUT" || true
    rm -f "${OUT}.awkrows.tmp" "${OUT}.jsonrows.tmp" "$json_tmp" "$merged_tmp"
  else
    rm -f "$json_tmp"
  fi
else
  # If AWK extractor failed, fall back to Python if available
  if command -v python3 >/dev/null 2>&1; then
    python3 "$(dirname "$0")/lib/parse_seek_json.py" "$INPUT" >> "$OUT" || true
  else
    echo "WARN: JSON extractor not available (no AWK or Python)" >&2
  fi
fi

echo "Parsed -> $OUT"
exit 0
