#!/bin/sh
# tests/test_load_fetch_config.sh
# Verify scripts/lib/load_fetch_config.sh loads an INI file and exports keys

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmpd="$(mktemp -d)"
ini="$tmpd/fetch_test.ini"
cat > "$ini" <<'INI'
BACKOFF_SEQUENCE=9,8,7
NEW_FETCH_VAR=xyz
UA_ROTATE=false
INI

# Ensure variables not set
unset BACKOFF_SEQUENCE || true
unset NEW_FETCH_VAR || true

# Source loader (it exports vars)
. "$REPO_ROOT/scripts/lib/load_fetch_config.sh" "$ini"

if [ "${BACKOFF_SEQUENCE:-}" != "9,8,7" ]; then
  echo "FAIL: BACKOFF_SEQUENCE expected 9,8,7, got '${BACKOFF_SEQUENCE:-}'" >&2
  rm -rf "$tmpd"
  exit 1
fi
if [ "${NEW_FETCH_VAR:-}" != "xyz" ]; then
  echo "FAIL: NEW_FETCH_VAR expected 'xyz', got '${NEW_FETCH_VAR:-}'" >&2
  rm -rf "$tmpd"
  exit 1
fi

# Precedence test: env should take precedence (loader should not override)
export BACKOFF_SEQUENCE=orig
. "$REPO_ROOT/scripts/lib/load_fetch_config.sh" "$ini"
if [ "$BACKOFF_SEQUENCE" != "orig" ]; then
  echo "FAIL: BACKOFF_SEQUENCE was overridden by loader" >&2
  rm -rf "$tmpd"
  exit 1
fi

rm -rf "$tmpd"

echo "PASS: load_fetch_config.sh works"
exit 0
