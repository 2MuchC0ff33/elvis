#!/bin/sh
# scripts/log_rotate.sh
# Simple log rotation helper: archives logs into .snapshots and prunes older archives
# Usage: scripts/log_rotate.sh [--keep-weeks N] [--dry-run]

set -eu

KEEP_WEEKS=4
DRY_RUN=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --keep-weeks)
      shift; KEEP_WEEKS="${1:-}";;
    --dry-run)
      DRY_RUN=true;;
    -h|--help)
      echo "Usage: $0 [--keep-weeks N] [--dry-run]"; exit 0;;
    *) echo "ERROR: unknown option: $1" >&2; exit 2;;
  esac
  shift || true
done

SNAP_DIR="${SNAPSHOT_DIR:-.snapshots}"
mkdir -p "$SNAP_DIR/checksums"

TS=$(date -u +%Y%m%dT%H%M%SZ)
ARCHIVE_NAME="logs-$TS.tar.gz"
ARCHIVE_PATH="$SNAP_DIR/$ARCHIVE_NAME"

if [ "$DRY_RUN" = true ]; then
  echo "DRY-RUN: would create $ARCHIVE_PATH containing logs/ and tmp/last_failed.status (if present)"
else
  # Only include logs and any failure marker useful for debugging
  tar -czf "$ARCHIVE_PATH" logs tmp/last_failed.status 2>/dev/null || tar -czf "$ARCHIVE_PATH" logs || true
  # checksum if available
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum "$ARCHIVE_PATH" > "$SNAP_DIR/checksums/$ARCHIVE_NAME.sha1" || true
  fi
  echo "Archived logs -> $ARCHIVE_PATH"
fi

# Prune older archives beyond keep count
if [ "$DRY_RUN" = true ]; then
  echo "DRY-RUN: would prune archives, keeping latest $KEEP_WEEKS"
else
  set -- "$SNAP_DIR"/logs-*.tar.gz
  # handle case of no archives
  if [ ! -e "$1" ]; then
    echo "No log archives to prune"
    exit 0
  fi
  # list sorted and remove older ones
  files=$(ls -1 "$SNAP_DIR"/logs-*.tar.gz | sort)
  keep=$(echo "$files" | tail -n "$KEEP_WEEKS" || true)
  for f in $files; do
    echo "$keep" | grep -q "$(basename "$f")" || rm -f "$f" && echo "Pruned: $f"
  done
fi

exit 0
