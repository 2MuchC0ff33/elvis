#!/bin/sh
# tests/test_update_readme.sh
# Simple smoke test for scripts/update_readme.sh (--dry-run)
set -eu

sh ./scripts/update_readme.sh --dry-run > /tmp/update_readme.out
if ! grep -q "<!-- AUTO-GENERATED-PROJECT-TREE:START -->" /tmp/update_readme.out; then
  echo "Missing START marker in output" >&2
  exit 1
fi
if ! grep -q "<!-- AUTO-GENERATED-PROJECT-TREE:END -->" /tmp/update_readme.out; then
  echo "Missing END marker in output" >&2
  exit 1
fi

echo "OK: update_readme dry-run produced markers"
