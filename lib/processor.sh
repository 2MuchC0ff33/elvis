#!/bin/sh
# processor.sh - validate, deduplicate, and output calllist
# - Reads pipe-separated rows (Company Name | Location)
# - Validates required fields: company_name and location
# - Logs INVALID <line> <reason> to stderr for invalid rows
# - Deduplicates case-insensitively on company_name compared to srv/company_history.txt
# - If --append-history is supplied, append new companies to history
# - Writes up to OUTPUT_LIMIT unique Australian companies to home/calllist.txt

set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/etc/elvisrc"

INPUT=""
APPEND_HISTORY="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --input) INPUT="$2"; shift 2 ;;
    --append-history) APPEND_HISTORY="true" ; shift ;;
    -h|--help) echo "Usage: $0 --input <file> [--append-history]"; exit 1 ;;
    *) echo "Unknown arg $1" >&2; exit 2 ;;
  esac
done

if [ -z "$INPUT" ] || [ ! -s "$INPUT" ]; then
  echo "No input rows provided" >&2
  exit 0
fi

TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

# Normalize, validate and produce canonical rows: company|location
awk -F '|' '
function trim(s){gsub(/^\s+|\s+$/,"",s); return s}
{company=trim($1); location=trim($2); if(company=="" || location=="") {printf("INVALID %s %s\n", $0, (company==""?"missing_company":"missing_location")) > "/dev/stderr"; next} print tolower(company) "|" company "|" location }
' "$INPUT" > "$TMP_OUT"

# TMP_OUT format: lc_company|Company|Location

# Deduplicate case-insensitive, skip those in history
mkdir -p "$ROOT/$(dirname "$HISTORY_FILE")"
if [ ! -f "$ROOT/$HISTORY_FILE" ]; then
  touch "$ROOT/$HISTORY_FILE"
fi

# Prepare set of existing history (lowercased)
awk '{print tolower($0)}' "$ROOT/$HISTORY_FILE" | sort -u > "$TMP_OUT.history"

# Filter out those present in history
awk -F '|' 'BEGIN{OFS=FS} {if (!h[$1]++) {print}}' "$TMP_OUT" | awk -F '|' 'NR==FNR{h[$1]=1;next} !h[$1]{print $0}' "$TMP_OUT.history" - > "$TMP_OUT.new"

# Now de-dup in remaining rows by company name and pick first occurrences
awk -F '|' '!seen[$1]++ {print $2 " | " $3}' "$TMP_OUT.new" > "$TMP_OUT.final"

# Take up to OUTPUT_LIMIT rows
head -n "$OUTPUT_LIMIT" "$TMP_OUT.final" > "$ROOT/$CALLLIST_FILE"

# If no valid rows, invoke default handler
if [ ! -s "$ROOT/$CALLLIST_FILE" ]; then
  "$ROOT/lib/default_handler.sh" --note "no_valid_matches"
  exit 0
fi

# Append to history if requested
if [ "$APPEND_HISTORY" = "true" ]; then
  awk -F '|' '{print $1}' "$TMP_OUT.final" >> "$ROOT/$HISTORY_FILE"
  # Normalize history file: one per line, unique, case-preserving first occurrence
  awk '!seen[tolower($0)]++{print $0}' "$ROOT/$HISTORY_FILE" > "$ROOT/$HISTORY_FILE.tmp" && mv "$ROOT/$HISTORY_FILE.tmp" "$ROOT/$HISTORY_FILE"
fi

# Print summary to log
count=$(wc -l < "$ROOT/$CALLLIST_FILE" | tr -d ' ')
printf "WROTE %s entries to %s\n" "$count" "$ROOT/$CALLLIST_FILE"

exit 0
