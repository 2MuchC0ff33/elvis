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
ELVISRC="$ROOT/etc/elvisrc"
if [ -f "$ELVISRC" ]; then
  # shellcheck source=/dev/null
  . "$ELVISRC"
else
  echo "Warning: $ELVISRC not found, continuing without sourcing." >&2
fi

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
awk -F '|' -f "$ROOT/lib/normalize.awk" "$INPUT" > "$TMP_OUT"

# TMP_OUT format: lc_company|Company|Location

# Deduplicate case-insensitive, skip those in history
mkdir -p "$ROOT/$(dirname "$HISTORY_FILE")"
if [ ! -f "$ROOT/$HISTORY_FILE" ]; then
  touch "$ROOT/$HISTORY_FILE"
fi

# Prepare set of existing history (lowercased)
awk -f "$ROOT/lib/history_lower.awk" "$ROOT/$HISTORY_FILE" | sort -u > "$TMP_OUT.history"

# Filter out those present in history and de-duplicate while preserving first occurrences
awk -F '|' -f "$ROOT/lib/filter_new.awk" "$TMP_OUT.history" "$TMP_OUT" > "$TMP_OUT.new"

# Format final rows as 'Company | Location' and de-duplicate by lc-company
awk -F '|' -f "$ROOT/lib/format_final.awk" "$TMP_OUT.new" > "$TMP_OUT.final"
# Take up to OUTPUT_LIMIT rows
if [ -n "${OUTPUT_LIMIT:-}" ]; then
  head -n "$OUTPUT_LIMIT" "$TMP_OUT.final" > "$ROOT/$CALLLIST_FILE"
else
  cp "$TMP_OUT.final" "$ROOT/$CALLLIST_FILE"
fi

# If no valid rows, invoke default handler
if [ ! -s "$ROOT/$CALLLIST_FILE" ]; then
  "$ROOT/lib/default_handler.sh" --note "no_valid_matches"
  exit 0
fi

# Append to history if requested
if [ "$APPEND_HISTORY" = "true" ]; then
  # Prepare trimmed list of new companies (left of the '|')
  awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/,"",$1); print $1}' "$TMP_OUT.final" > "$TMP_OUT.newcompanies"

  # Build candidate history by concatenating existing history and new companies, then normalize (trim, skip blanks/comments, unique, case-preserving first occurrence)
  cat "$ROOT/$HISTORY_FILE" "$TMP_OUT.newcompanies" | awk -f "$ROOT/lib/dedupe_history.awk" > "$ROOT/$HISTORY_FILE.tmp"

  # Ensure history file exists so cmp/diff behave predictably
  touch "$ROOT/$HISTORY_FILE"

  # Simple locking to avoid concurrent writers (mkdir-based lock)
  LOCKDIR="$ROOT/var/tmp/history.lock"
  # Acquire lock (spin until available); portable and simple
  while ! mkdir "$LOCKDIR" 2>/dev/null; do
    sleep 0.05
  done
  # Ensure lock is released on exit from this block (or script)
  trap 'rmdir "$LOCKDIR"' EXIT

  # If no change, remove temporary file; otherwise create a patch and atomically replace
  if cmp -s "$ROOT/$HISTORY_FILE" "$ROOT/$HISTORY_FILE.tmp"; then
    rm -f "$ROOT/$HISTORY_FILE.tmp"
    printf "%s %s\n" "INFO" "No changes to $HISTORY_FILE"
  else
    # Create a unified diff patch for auditability with timestamp
    PATCH_FILE="$ROOT/var/spool/company_history-$(date +%Y%m%dT%H%M%S).patch"
    diff -u "$ROOT/$HISTORY_FILE" "$ROOT/$HISTORY_FILE.tmp" > "$PATCH_FILE" || true
    # Atomic replace of history file
    mv "$ROOT/$HISTORY_FILE.tmp" "$ROOT/$HISTORY_FILE"
    printf "%s %s %s\n" "INFO" "Updated $HISTORY_FILE; patch written to" "$PATCH_FILE"
    # Also log to persistent log file for observability
    printf "%s %s %s %s\n" "$(date +"$LOG_TIME_FORMAT")" "INFO" "Updated $HISTORY_FILE; patch written to" "$PATCH_FILE" >> "$LOG_FILE" || :

    # Optional retention: remove patch files older than 30 days to avoid unbounded growth
    find "$ROOT/var/spool" -type f -name 'company_history-*.patch' -mtime +30 -exec rm -f {} \; || :
  fi

  # Release lock (trap will also remove on exit)
  rmdir "$LOCKDIR" 2>/dev/null || :
  trap - EXIT
fi

# Print summary to log
count=$(wc -l < "$ROOT/$CALLLIST_FILE" | tr -d ' ')
printf "WROTE %s entries to %s\n" "$count" "$ROOT/$CALLLIST_FILE"

exit 0
