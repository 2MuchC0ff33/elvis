#!/bin/sh
# scripts/lib/load_seek_pagination.sh
# Load Seek pagination config (INI-style) into environment variables
# Usage: . scripts/lib/load_seek_pagination.sh [INI_FILE]
# Exports variables as SEEK_<section>_<key>

set -eu

INI_FILE="${1:-configs/seek-pagination.ini}"
if [ ! -f "$INI_FILE" ]; then
  echo "Error: Seek pagination config '$INI_FILE' not found." >&2
  exit 1
fi

section=""
while IFS= read -r line; do
  case "$line" in
    \[*\]) section="$(echo "$line" | sed 's/\[//;s/\]//;s/[^A-Za-z0-9]/_/g' | tr '[:lower:]' '[:upper:]')" ;;
    ''|\#*) continue ;;
    *=*)
      key="$(echo "$line" | cut -d= -f1 | tr -d ' ' | awk '{print toupper($0)}')"
      val="$(echo "$line" | cut -d= -f2- | sed 's/^ *//;s/ *$//')"
      [ -n "$section" ] && export "SEEK_${section}_${key}"="$val"
      ;;
  esac
done < "$INI_FILE"
