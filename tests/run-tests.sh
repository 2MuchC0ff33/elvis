#!/bin/sh
# tests/run-tests.sh
# Test runner for Elvis init workflow and modular scripts

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail=0

# Test: load_env.sh (should not fail if .env missing)
if ! sh "$REPO_ROOT/scripts/lib/load_env.sh"; then
  echo "FAIL: load_env.sh failed with missing .env" >&2
  fail=1
fi

# Test: load_config.sh (should fail if config missing)
if sh "$REPO_ROOT/scripts/lib/load_config.sh" not_a_real_file.conf 2>/dev/null; then
  echo "FAIL: load_config.sh did not fail on missing file" >&2
  fail=1
fi

# Test: load_seek_pagination.sh (should fail if config missing)
if sh "$REPO_ROOT/scripts/lib/load_seek_pagination.sh" not_a_real_file.ini 2>/dev/null; then
  echo "FAIL: load_seek_pagination.sh did not fail on missing file" >&2
  fail=1
fi

# Test: validate_env.sh (should fail if required vars missing)
unset SEEDS_FILE OUTPUT_DIR HISTORY_FILE LOG_FILE SEEK_PAGINATION_CONFIG || true
if sh "$REPO_ROOT/scripts/lib/validate_env.sh" 2>/dev/null; then
  echo "FAIL: validate_env.sh did not fail with missing vars" >&2
  fail=1
fi

# Test: prepare_log.sh (should create logs/log.txt)
rm -rf "$REPO_ROOT/logs"
sh "$REPO_ROOT/scripts/lib/prepare_log.sh" "$REPO_ROOT/logs/log.txt"
if [ ! -f "$REPO_ROOT/logs/log.txt" ]; then
  echo "FAIL: prepare_log.sh did not create log file" >&2
  fail=1
fi

# Test: bin/elvis-run init (should complete without error)
if ! sh "$REPO_ROOT/bin/elvis-run" init; then
  echo "FAIL: bin/elvis-run init failed" >&2
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "All tests passed."
else
  echo "Some tests failed." >&2
fi
exit "$fail"
