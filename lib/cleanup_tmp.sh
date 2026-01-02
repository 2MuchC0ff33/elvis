#!/bin/sh
# cleanup_tmp.sh - Cleanup ephemeral files in tmp/ and old HTML in src/
ROOT="$1"
SRC_DIR="$2"
# Ensure tmp directory exists
mkdir -p "$ROOT/tmp"
# Remove all files in tmp except .gitkeep (preserve repository placeholder)
find "$ROOT/tmp" -type f ! -name '.gitkeep' -delete
# Ensure a .gitkeep exists so the empty directory is tracked in git
if [ ! -f "$ROOT/tmp/.gitkeep" ]; then
  touch "$ROOT/tmp/.gitkeep"
fi

find "$ROOT/$SRC_DIR" -type f -name '*.html' -mtime +7 -delete
