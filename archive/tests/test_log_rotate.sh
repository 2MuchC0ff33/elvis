#!/bin/sh
# tests/test_log_rotate.sh
# Smoke test for log_rotate.sh --dry-run

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "[TEST] log_rotate --dry-run"
out="$(mktemp)"
if sh "$REPO_ROOT/scripts/log_rotate.sh" --dry-run > "$out" 2>&1; then
  if grep -q 'DRY-RUN: would create' "$out"; then
    echo "PASS: log_rotate --dry-run printed expected message"
    rm -f "$out"
    exit 0
  else
    echo "FAIL: log_rotate --dry-run did not print expected message"; cat "$out"; rm -f "$out"; exit 1
  fi
else
  echo "FAIL: log_rotate --dry-run returned non-zero"; cat "$out"; rm -f "$out"; exit 1
fi
