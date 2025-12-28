#!/bin/sh
# scripts/lib/prepare_log.sh
# Ensure logs/log.txt exists and logs/ directory is present
# Usage: . scripts/lib/prepare_log.sh

set -eu

LOG_FILE="${1:-logs/log.txt}"
LOG_DIR="$(dirname "$LOG_FILE")"

if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR"
fi

touch "$LOG_FILE"
