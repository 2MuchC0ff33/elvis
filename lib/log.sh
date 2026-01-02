#!/bin/sh
# log.sh - Logging helper
ROOT="$1"
LOG_FILE="$2"
LOG_TIME_FORMAT="$3"
shift 3
msg="$*"
ts="$(date +"$LOG_TIME_FORMAT")"
printf "%s %s\n" "$ts" "$msg" >> "$ROOT/$LOG_FILE"
