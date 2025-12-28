#!/bin/sh
# scripts/summarise.sh
# Wrapper for generate_summary
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/summarise.sh"

generate_summary "$@"
