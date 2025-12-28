#!/bin/sh
# default_handler.sh - fallback when no valid matches found
# - Writes a placeholder line to home/calllist.txt and logs the reason

set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/etc/elvisrc"

NOTE="no_matches"
if [ "$#" -gt 0 ]; then
  NOTE="$1"
fi

mkdir -p "$ROOT/home"
printf "No valid results found | N/A\n" > "$ROOT/$CALLLIST_FILE"

echo "$(date +"$LOG_TIME_FORMAT") Default handler: $NOTE" >> "$ROOT/$LOG_FILE"

exit 0
