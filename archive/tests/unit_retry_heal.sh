#!/bin/sh
# tests/unit_retry_heal.sh
# Tests retry_with_backoff and heal preserve/restore

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t retry)"
trap 'rm -rf "$tmp"' EXIT

# retry_with_backoff: create a failer that fails twice then succeeds
cat > "$tmp/failer.sh" <<'SH'
#!/bin/sh
countfile="$PWD/failer.count"
count=0
if [ -f "$countfile" ]; then count=$(cat "$countfile" | tr -d '[:space:]' || echo 0); fi
count=$((count+1))
printf '%s' "$count" > "$countfile"
if [ "$count" -lt 3 ]; then echo "failing attempt $count" >&2; exit 1; else echo "succeeding attempt $count"; exit 0; fi
SH
chmod +x "$tmp/failer.sh"
. "$REPO_ROOT/scripts/lib/error.sh"
if ! retry_with_backoff 5 "$tmp/failer.sh"; then echo "FAIL: retry_with_backoff did not recover" >&2; exit 1; fi

echo "PASS: retry_with_backoff recovered"

# heal: preserve_failed_artifacts and restore_latest_snapshot
unit_heal="$tmp/heal_test"
mkdir -p "$unit_heal/data"
printf 'hello' > "$unit_heal/data/seed.txt"
mkdir -p "$unit_heal/.snapshots" && tar -czf "$unit_heal/.snapshots/snap-test2.tar.gz" -C "$unit_heal" data
export SNAPSHOT_DIR="$unit_heal/.snapshots"
. "$REPO_ROOT/scripts/lib/heal.sh"
mkdir -p tmp
printf 'failed' > tmp/test.step.status
preserve_failed_artifacts test.step
if [ -z "$(find "$SNAPSHOT_DIR/failed" -name 'failed-test.step-*' -print -quit)" ]; then echo "FAIL: preserve_failed_artifacts did not create tarball" >&2; exit 1; fi

restore_dir=$(restore_latest_snapshot)
[ -d "$restore_dir" ] || { echo "FAIL: restore_latest_snapshot did not create dir" >&2; exit 1; }
[ -f "$restore_dir/data/seed.txt" ] || { echo "FAIL: restore_latest_snapshot missing file" >&2; exit 1; }

# attempt_recover_step: run a simple command
attempt_recover_step unitstep "sh -c 'printf recovered > tmp/heal_recovered.txt; exit 0'"
if [ ! -f tmp/heal_recovered.txt ]; then echo "FAIL: attempt_recover_step did not run recovery" >&2; exit 1; fi

echo "PASS: unit_retry_heal"
exit 0
