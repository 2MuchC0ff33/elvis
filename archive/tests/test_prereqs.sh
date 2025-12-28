#!/bin/sh
# tests/test_prereqs.sh
# Fail early if essential tools are missing (gawk, curl)

set -eu

missing=0
for cmd in gawk curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "FAIL: required tool missing: $cmd" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "PASS: prerequisites present (gawk, curl)"
exit 0
