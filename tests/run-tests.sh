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

# Test: shellcheck -x (if available) — verify scripts are free of issues
# Prefer repo wrapper in PATH so Cygwin path conversions happen when needed
export PATH="$REPO_ROOT/scripts/lib:$PATH"
if command -v shellcheck >/dev/null 2>&1; then
  echo "Running shellcheck -x across scripts..."
  SC_OUT="$(mktemp)" || SC_OUT="/tmp/shellcheck.out"
  # Run shellcheck and capture stdout/stderr so we can make a decision on Haskell runtime issues
  if ! find "$REPO_ROOT" -type f -name '*.sh' -print0 | xargs -0 shellcheck -x >"$SC_OUT" 2>&1; then
    if grep -q 'openBinaryFile' "$SC_OUT" >/dev/null 2>&1; then
      echo "SKIP: shellcheck appears misconfigured in this environment (openBinaryFile). Please install a native ShellCheck or adjust PATH." >&2
      sed -n '1,200p' "$SC_OUT" >&2 || true
      rm -f "$SC_OUT" || true
    else
      echo "FAIL: shellcheck reported issues" >&2
      sed -n '1,200p' "$SC_OUT" >&2 || true
      rm -f "$SC_OUT" || true
      fail=1
    fi
  else
    rm -f "$SC_OUT" || true
  fi
else
  echo "SKIP: shellcheck not installed — install shellcheck to enable lint checks" >&2
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
