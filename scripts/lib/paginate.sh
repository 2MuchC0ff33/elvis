#!/bin/sh
# scripts/lib/paginate.sh
# Paginate through a seed URL using the detected model
# Usage: paginate.sh <base_url> <model>
# Echoes each page's HTML to stdout, one after another

set -eu
base_url="$1"
model="$2"
offset=0
page=1
while :; do
  case "$model" in
    PAG_START)
      url="$base_url&start=$offset"
      ;;
    PAG_PAGE)
      url="$base_url?page=$page"
      ;;
    *)
      echo "Unknown pagination model: $model" >&2
      exit 1
      ;;
  esac
  # Use FETCH_SCRIPT if provided (test hooks), otherwise call the real fetch script
  if [ -n "${FETCH_SCRIPT:-}" ]; then
    html=$(sh "$FETCH_SCRIPT" "$url")
  else
    html=$(sh "$(dirname "$0")/../fetch.sh" "$url")
  fi
  echo "$html"
  # Stop if no Next marker
  if ! echo "$html" | grep -q 'data-automation="page-next"'; then
    break
  fi
  case "$model" in
    PAG_START) offset=$((offset+22));;
    PAG_PAGE) page=$((page+1));;
  esac
done
