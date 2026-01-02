#!/bin/sh
# tests/unit_validate_env.sh
# Tests for validate_env.sh

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure validate_env.sh fails when required vars missing
# Unset vars temporarily
old_SEEDS_FILE="${SEEDS_FILE:-}"
old_OUTPUT_DIR="${OUTPUT_DIR:-}"
old_HISTORY_FILE="${HISTORY_FILE:-}"
old_LOG_FILE="${LOG_FILE:-}"
old_SEEK_PAGINATION_CONFIG="${SEEK_PAGINATION_CONFIG:-}"
unset SEEDS_FILE OUTPUT_DIR HISTORY_FILE LOG_FILE SEEK_PAGINATION_CONFIG || true

if sh "$REPO_ROOT/scripts/lib/validate_env.sh" 2>/dev/null; then
  echo "FAIL: validate_env.sh did not fail with missing vars" >&2
  exit 1
fi

# restore (best-effort)
[ -n "$old_SEEDS_FILE" ] && export SEEDS_FILE="$old_SEEDS_FILE" || unset SEEDS_FILE || true
[ -n "$old_OUTPUT_DIR" ] && export OUTPUT_DIR="$old_OUTPUT_DIR" || unset OUTPUT_DIR || true
[ -n "$old_HISTORY_FILE" ] && export HISTORY_FILE="$old_HISTORY_FILE" || unset HISTORY_FILE || true
[ -n "$old_LOG_FILE" ] && export LOG_FILE="$old_LOG_FILE" || unset LOG_FILE || true
[ -n "$old_SEEK_PAGINATION_CONFIG" ] && export SEEK_PAGINATION_CONFIG="$old_SEEK_PAGINATION_CONFIG" || unset SEEK_PAGINATION_CONFIG || true

echo "PASS: unit_validate_env"
exit 0
