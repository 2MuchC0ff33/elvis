#!/bin/sh
# cleanup_tmp.sh - Cleanup ephemeral files in tmp/ and old HTML in src/
ROOT="$1"
SRC_DIR="$2"
find "$ROOT/tmp" -type f -delete
find "$ROOT/$SRC_DIR" -type f -name '*.html' -mtime +7 -delete
