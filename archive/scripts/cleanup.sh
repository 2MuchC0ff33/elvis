#!/bin/sh
# scripts/cleanup.sh
# Wrapper for cleanup_tmp
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/cleanup.sh"

cleanup_tmp "$@"
