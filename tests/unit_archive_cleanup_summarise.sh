#!/bin/sh
# tests/unit_archive_cleanup_summarise.sh
# Tests archive_artifacts, cleanup_tmp, and summarise

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t arctest)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/subdir"
printf 'hello' > "$tmp/file1.txt"
printf 'world' > "$tmp/subdir/file2.txt"
# isolated snapshot dir
save_SNAPSHOT_DIR="${SNAPSHOT_DIR:-}"
export SNAPSHOT_DIR="$tmp/snapshots"

sh "$REPO_ROOT/scripts/archive.sh" "$tmp/file1.txt" "$tmp/subdir" || { echo "FAIL: archive.sh failed" >&2; exit 1; }
# check snapshot
snap_file=$(find "$tmp/snapshots" -name 'snap-*' -type f -print -quit || true)
[ -n "$snap_file" ] || { echo "FAIL: no snapshot created" >&2; exit 1; }
[ -f "$tmp/snapshots/checksums/$(basename "$snap_file").sha1" ] || { echo "FAIL: checksum missing" >&2; exit 1; }
grep -q "$(basename "$snap_file")" "$tmp/snapshots/index" || { echo "FAIL: index missing" >&2; exit 1; }

# cleanup_tmp: create files then clean
mkdir -p "$tmp/cleanup_test"
printf 'a' > "$tmp/cleanup_test/fileA.tmp"
printf 'b' > "$tmp/cleanup_test/subB.tmp"
sh "$REPO_ROOT/scripts/cleanup.sh" "$tmp/cleanup_test" || { echo "FAIL: cleanup.sh failed" >&2; exit 1; }
if [ -n "$(find "$tmp/cleanup_test" -mindepth 1 -print -quit)" ]; then echo "FAIL: cleanup did not remove contents" >&2; exit 1; fi

# summarise: create snapshot and calllists to examine summary output
mkdir -p "$tmp/data/calllists" "$tmp/logs"
printf 'company\n' > "$tmp/data/calllists/calllist_2025-12-24.csv"
printf 'WARN: something happened\n' > "$tmp/logs/log.txt"
export SNAPSHOT_DIR="$tmp/snapshots"
sh "$REPO_ROOT/scripts/summarise.sh" --out "$tmp/summary.txt" || { echo "FAIL: summarise.sh failed" >&2; exit 1; }
[ -f "$tmp/summary.txt" ] || { echo "FAIL: summary not produced" >&2; exit 1; }
grep -q 'calllists_count' "$tmp/summary.txt" || { echo "FAIL: summary missing calllists_count" >&2; exit 1; }

# restore SNAPSHOT_DIR
if [ -n "$save_SNAPSHOT_DIR" ]; then export SNAPSHOT_DIR="$save_SNAPSHOT_DIR"; else unset SNAPSHOT_DIR || true; fi

echo "PASS: unit_archive_cleanup_summarise"
exit 0
