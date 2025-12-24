#!/bin/sh
# scripts/archive.sh
# Wrapper CLI for archive_artifacts
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/archive.sh"

# If no args, pick common artifacts
if [ $# -eq 0 ]; then
  # Read defaults from project.conf if available
  proj_conf="$(cd "$SCRIPT_DIR/.." && pwd)/project.conf"
  files=""
  if [ -f "$proj_conf" ]; then
    # shellcheck disable=SC1090
    . "$proj_conf"
    files="$SEEDS_FILE $OUTPUT_DIR $HISTORY_FILE $LOG_FILE"
  else
    files="data/calllists companies_history.txt logs/log.txt tmp"
  fi
  set -- $files
fi

archive_artifacts "$@"
