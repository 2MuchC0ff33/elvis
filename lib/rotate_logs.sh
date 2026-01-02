#!/bin/sh
# rotate_logs.sh - Log rotation helper
ROOT="$1"
LOG_FILE="$2"
LOG_ROTATE_DAYS="$3"

if [ -f "$ROOT/$LOG_FILE" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$ROOT/$LOG_FILE") ))
  age_days=$(( age / 86400 ))
  if [ "$age_days" -ge "$LOG_ROTATE_DAYS" ]; then
    mv "$ROOT/$LOG_FILE" "$ROOT/$LOG_FILE.$(date +%Y%m%d)"
    touch "$ROOT/$LOG_FILE"
    "$ROOT/lib/log.sh" "$ROOT" "$LOG_FILE" "%Y-%m-%d %H:%M:%S" "INFO Log rotated; previous archived"
  fi
else
  touch "$ROOT/$LOG_FILE"
fi
