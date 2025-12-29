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




APPEND_HISTORY="true"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --append-history) APPEND_HISTORY="true" ; shift ;;
    -h|--help) "$ROOT/lib/usage.sh" ;;
    *) echo "Unknown arg: $1" >&2 ; "$ROOT/lib/usage.sh" ;;
  esac
done

# Rotate logs
"$ROOT/lib/rotate_logs.sh" "$ROOT" "$LOG_FILE" "$LOG_ROTATE_DAYS"
# Log run start
"$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "INFO Run started"

if [ ! -s "$ROOT/$URLS_FILE" ]; then
  "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "WARN No seed URLs found in $URLS_FILE"
  echo "No seed URLs found; exiting" >&2
  exit 0
fi

# Temp aggregate spool file for rows (company_name|location)
AGG="$ROOT/$SPOOL_DIR/aggregated_rows.txt"
: > "$AGG"


while IFS= read -r url; do
  [ -z "$url" ] && continue
  "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "INFO Processing seed $url"
  # Suppress direct output from data_input.sh
  if "$ROOT/lib/data_input.sh" "$url" >> "$AGG" 2>>"$ROOT/$LOG_FILE"; then
    "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "INFO data_input.sh succeeded for $url"
  else
    "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "WARN data_input.sh exited non-zero for $url"
  fi
  # Serialisation: respect daylight, small randomized pause between seeds
  sleep_time=$(awk -v min="$DELAY_MIN" -v max="$DELAY_MAX" -f "$ROOT/lib/random_delay.awk")
  "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "INFO Sleeping ${sleep_time}s between seeds"
  sleep "$sleep_time"
done < "$ROOT/$URLS_FILE"

# Pass aggregated rows to processor

if [ -s "$AGG" ]; then
  # Suppress processor.sh output except errors
  proc_output="$("$ROOT/lib/processor.sh" --input "$AGG" --append-history "$APPEND_HISTORY" 2>&1 > /dev/null)"
  rc=$?
  if [ $rc -ne 0 ]; then
    "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "ERROR processor.sh failed with code $rc: $proc_output"
    "$ROOT/lib/default_handler.sh" --note "processor_failed"
  else
    # Validate the produced calllist to ensure it meets format and uniqueness rules
    if [ -s "$ROOT/$CALLLIST_FILE" ]; then
      val_output="$(sh "$ROOT/lib/validate_calllist.sh" 2>&1)"
      val_rc=$?
      if [ $val_rc -eq 0 ]; then
        "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "INFO calllist validation passed for $CALLLIST_FILE"
      else
        "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "ERROR calllist validation failed: $val_output"
        "$ROOT/lib/default_handler.sh" --note "validation_failed"
        exit $val_rc
      fi
    else
      "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "ERROR calllist file $CALLLIST_FILE missing after processor"
      "$ROOT/lib/default_handler.sh" --note "calllist_missing"
      exit 3
    fi
  fi
else
  "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "WARN No candidate rows were produced; invoking default handler"
  "$ROOT/lib/default_handler.sh" --note "no_matches"
fi

# Final summary (only output from orchestrator)


count=$(awk -f "$ROOT/lib/count_rows.awk" "$AGG")
echo "Run completed; rows_aggregated=$count"
"$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "$LOG_TIME_FORMAT" "INFO Run completed; rows_aggregated=$count"

# Cleanup ephemeral files and old HTML files
"$ROOT/lib/cleanup_tmp.sh" "$ROOT" "$SRC_DIR"

exit 0
