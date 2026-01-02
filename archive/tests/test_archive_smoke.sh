#!/bin/sh
# tests/test_archive_smoke.sh
# Smoke test for archive_artifacts: create a snapshot and a checksum in SNAPSHOT_DIR

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "[TEST] archive_artifacts smoke test"
TMP_DIR="$(mktemp -d)"
mkdir -p "$TMP_DIR/files"
printf 'hello' > "$TMP_DIR/files/a.txt"
printf 'world' > "$TMP_DIR/files/b.txt"
SNAP_DIR="$TMP_DIR/snaps"
export SNAPSHOT_DIR="$SNAP_DIR"

# Run archive.sh to archive the test files
sh "$REPO_ROOT/scripts/archive.sh" "$TMP_DIR/files/a.txt" "$TMP_DIR/files/b.txt" >/dev/null 2>&1 || true

# Check for snapshot file and checksum
snap_count=$(ls -1 "$SNAP_DIR"/snap-*.tar.gz 2>/dev/null | wc -l || echo 0)
checksum_count=$(ls -1 "$SNAP_DIR"/checksums/*.sha1 2>/dev/null | wc -l || echo 0)

if [ "$snap_count" -ge 1 ] && [ "$checksum_count" -ge 1 ]; then
  echo "PASS: snapshot and checksum created in $SNAP_DIR"
  rm -rf "$TMP_DIR"
  exit 0
else
  echo "FAIL: snapshot or checksum missing in $SNAP_DIR"
  echo "snap_count=$snap_count checksum_count=$checksum_count"
  ls -la "$SNAP_DIR" || true
  rm -rf "$TMP_DIR"
  exit 1
fi
