#!/bin/sh
# shellcheck disable=SC2046


# Main orchestrator for elvis scraper
# - Sources etc/elvisrc for configuration
# - Iterates seed URLs and feeds them through the fetch -> parse -> process pipeline
# - Logs activity to var/log/elvis.log and rotates logs weekly

set -eu

# Resolve project root reliably (dir containing bin/)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ELVISRC="$ROOT/etc/elvisrc"
if [ -f "$ELVISRC" ]; then
  # shellcheck source=/dev/null
  . "$ELVISRC"
else
  echo "Configuration file $ELVISRC not found" >&2
  exit 1
fi

# Ensure directories exist
mkdir -p "$ROOT/$LOG_DIR" "$ROOT/$SRC_DIR" "$ROOT/$SPOOL_DIR" "$ROOT/$TMP_DIR" "$ROOT/home"

# Logging helpers
log() {
  ts="$(date +"$LOG_TIME_FORMAT")"
  printf "%s %s\n" "$ts" "$*" >> "$ROOT/$LOG_FILE"
}


rotate_logs_if_needed() {
  # Simple weekly rotation based on file age
  if [ -f "$ROOT/$LOG_FILE" ]; then
    # age in days
    age=$(( $(date +%s) - $(stat -c %Y "$ROOT/$LOG_FILE") ))
    age_days=$(( age / 86400 ))
    if [ "$age_days" -ge "$LOG_ROTATE_DAYS" ]; then
      mv "$ROOT/$LOG_FILE" "$ROOT/$LOG_FILE.$(date +%Y%m%d)"
      touch "$ROOT/$LOG_FILE"
      log "INFO" "Log rotated; previous archived"
    fi
  else
    touch "$ROOT/$LOG_FILE"
  fi
}

usage() {
  cat <<EOF
Usage: $0 [--append-history]
  --append-history    Append newly-found companies to $HISTORY_FILE
EOF
  exit 1
}

APPEND_HISTORY="$APPEND_HISTORY_DEFAULT"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --append-history) APPEND_HISTORY="true" ; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2 ; usage ;;
  esac
done

rotate_logs_if_needed
log "INFO" "Run started"

# NB: pipeline: for each URL, fetch pages (data_input.sh) -> parse/emit rows -> processor.sh collects unique rows

if [ ! -s "$ROOT/$URLS_FILE" ]; then
  log "WARN" "No seed URLs found in $URLS_FILE"
  echo "No seed URLs found; exiting" >&2
  exit 0
fi

# Temp aggregate spool file for rows (company_name|location)
AGG="$ROOT/$SPOOL_DIR/aggregated_rows.txt"
: > "$AGG"

while IFS= read -r url; do
  [ -z "$url" ] && continue
  log "INFO" "Processing seed $url"
  # data_input.sh writes stable company|location lines to stdout
  if "$ROOT/lib/data_input.sh" "$url" >> "$AGG"; then
    log "INFO" "data_input.sh succeeded for $url"
  else
    log "WARN" "data_input.sh exited non-zero for $url"
  fi
  # Serialisation: respect daylight, small randomized pause between seeds
  # Use standalone AWK script for random delay (migrated inline AWK -> lib/random_delay.awk)
  sleep_time=$(awk -v min="$DELAY_MIN" -v max="$DELAY_MAX" -f "$ROOT/lib/random_delay.awk")
  log "INFO" "Sleeping ${sleep_time}s between seeds"
  sleep "$sleep_time"

done < "$ROOT/$URLS_FILE"

# Pass aggregated rows to processor
if [ -s "$AGG" ]; then
  # run processor to validate, dedupe, and write $CALLLIST_FILE
  "$ROOT/lib/processor.sh" --input "$AGG" $( [ "$APPEND_HISTORY" = "true" ] && printf -- "--append-history" )
  rc=$?
  if [ $rc -ne 0 ]; then
    log "ERROR" "processor.sh failed with code $rc"
    "$ROOT/lib/default_handler.sh" --note "processor_failed"
  else
    # Validate the produced calllist to ensure it meets format and uniqueness rules
    # On validation failure, invoke default handler and exit with non-zero to signal failure
    if sh "$ROOT/lib/validate_calllist.sh" >/dev/null 2>&1; then
      log "INFO" "calllist validation passed for $CALLLIST_FILE"
    else
      log "ERROR" "calllist validation failed for $CALLLIST_FILE; invoking default handler"
      "$ROOT/lib/default_handler.sh" --note "validation_failed"
      exit 2
    fi
  fi
else
  log "WARN" "No candidate rows were produced; invoking default handler"
  "$ROOT/lib/default_handler.sh" --note "no_matches"
fi

# Final summary
count=$(awk -f "$ROOT/lib/count_rows.awk" "$AGG")
log "INFO" "Run completed; rows_aggregated=$count"

exit 0
