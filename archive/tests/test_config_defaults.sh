#!/bin/sh
# tests/test_config_defaults.sh
# Verify key defaults exist in project.conf

set -eu
CONF_FILE="project.conf"

if [ ! -f "$CONF_FILE" ]; then
  echo "ERROR: $CONF_FILE not found" >&2
  exit 2
fi

check_key() {
  key="$1"
  expected="$2"
  val=$(grep -E "^$key=" "$CONF_FILE" || true)
  if [ -z "$val" ]; then
    echo "FAIL: $key not present in $CONF_FILE" >&2
    return 1
  fi
  # Extract RHS
  rhs=$(printf '%s' "$val" | sed -E 's/^[^=]+=//')
  if [ "$rhs" != "$expected" ]; then
    echo "FAIL: $key has value '$rhs' (expected '$expected')" >&2
    return 2
  fi
  echo "OK: $key=$rhs"
  return 0
}

check_key VERIFY_ROBOTS true
check_key BACKOFF_SEQUENCE 5,20,60
check_key MIN_LEADS 25

echo "All config default checks passed."
