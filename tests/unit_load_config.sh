#!/bin/sh
# tests/unit_load_config.sh
# Tests for load_env, load_config, load_seek_pagination

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# load_env.sh should not fail when .env missing
if ! sh "$REPO_ROOT/scripts/lib/load_env.sh" >/dev/null 2>&1; then
  echo "FAIL: load_env.sh failed when .env missing" >&2
  exit 1
fi

# load_config.sh should fail for missing file
if sh "$REPO_ROOT/scripts/lib/load_config.sh" not_a_real_file.conf 2>/dev/null; then
  echo "FAIL: load_config.sh did not fail on missing file" >&2
  exit 1
fi

echo "PASS: unit_load_config"
exit 0
