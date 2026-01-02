#!/bin/sh
# tests/test_end_sequence_dry_run.sh
# Smoke test that end_sequence.sh --dry-run runs cleanly and emits expected messages

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

out="$REPO_ROOT/tmp/end_sequence.dryrun.out"
rm -f "$out"
mkdir -p "$REPO_ROOT/tmp"

if sh "$REPO_ROOT/scripts/end_sequence.sh" --dry-run > "$out" 2>&1; then
  # Check for expected dry-run messages
  if grep -q 'DRY-RUN: would archive artifacts' "$out" && grep -q 'DRY-RUN: would generate summary' "$out"; then
    echo "PASS: end_sequence --dry-run emitted expected messages"
    rm -f "$out"
    exit 0
  else
    echo "FAIL: expected DRY-RUN messages missing"; cat "$out"; exit 1
  fi
else
  echo "FAIL: end_sequence --dry-run failed to run"; cat "$out"; exit 1
fi
