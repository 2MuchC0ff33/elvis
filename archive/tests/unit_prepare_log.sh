#!/bin/sh
# tests/unit_prepare_log.sh
# Tests prepare_log.sh creates logs/log.txt

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rm -rf "$REPO_ROOT/logs"
sh "$REPO_ROOT/scripts/lib/prepare_log.sh" "$REPO_ROOT/logs/log.txt"
if [ ! -f "$REPO_ROOT/logs/log.txt" ]; then
  echo "FAIL: prepare_log.sh did not create log file" >&2
  exit 1
fi

echo "PASS: unit_prepare_log"
exit 0
