#!/bin/sh
# scripts/lib/paginate.sh
# Paginate through a seed URL using the detected model
# Usage: paginate.sh <base_url> <model>
# Echoes each page's HTML to stdout, one after another

set -eu
base_url="$1"
model="$2"
# Configurable marker (env or seek pagination config)
PAGE_NEXT_MARKER="${PAGE_NEXT_MARKER:-${SEEK_PAGINATION_PAGE_NEXT_MARKER:-data-automation=\"page-next\"}}"
OFFSET_STEP="${OFFSET_STEP:-22}"
# Safety limits
MAX_PAGES="${MAX_PAGES:-${SEEK_GLOBAL_MAX_PAGES:-200}}"
MAX_OFFSET="${MAX_OFFSET:-${SEEK_GLOBAL_MAX_OFFSET:-10000}}"
# Random delay between pages (seconds, float) - allow SEEK_GLOBAL_DELAY_MIN/MAX
DELAY_MIN="${DELAY_MIN:-${SEEK_GLOBAL_DELAY_MIN:-1.2}}"
DELAY_MAX="${DELAY_MAX:-${SEEK_GLOBAL_DELAY_MAX:-4.8}}"
# Allow overriding the sleep implementation for tests
SLEEP_CMD="${SLEEP_CMD:-sleep}"

offset=0
page=1
iter=0
while :; do
  iter=$((iter+1))
  case "$model" in
    PAG_START)
      url="$base_url&start=$offset"
      ;;
    PAG_PAGE)
      if [ "$page" -eq 1 ]; then
        url="$base_url"
      else
        url="$base_url?page=$page"
      fi
      ;;
    *)
      echo "Unknown pagination model: $model" >&2
      exit 1
      ;;
  esac

  # Use FETCH_SCRIPT if provided (test hooks), otherwise call the real fetch script
  if [ -n "${FETCH_SCRIPT:-}" ]; then
    html=$(sh "$FETCH_SCRIPT" "$url") || html=""
  else
    html=$(sh "$(dirname "$0")/../fetch.sh" "$url") || html=""
  fi

  echo "$html"

  # Stop if no Next marker
  if ! printf '%s' "$html" | grep -q "$PAGE_NEXT_MARKER"; then
    break
  fi

  # Safety checks
  if [ "$model" = "PAG_START" ]; then
    offset=$((offset+OFFSET_STEP));
    if [ "$offset" -gt "$MAX_OFFSET" ]; then
      echo "WARN: reached max_offset ($MAX_OFFSET), stopping" >&2
      break
    fi
  else
    page=$((page+1));
    if [ "$page" -gt "$MAX_PAGES" ]; then
      echo "WARN: reached max_pages ($MAX_PAGES), stopping" >&2
      break
    fi
  fi

  # Randomised delay between requests
  # compute a random float between DELAY_MIN and DELAY_MAX
  rand_fraction=$(awk 'BEGIN{srand(); print rand()}')
  delay=$(awk -v min="$DELAY_MIN" -v max="$DELAY_MAX" -v r="$rand_fraction" 'BEGIN{printf "%.3f", min + (max-min)*r}')
  # Use SLEEP_CMD so tests can stub sleep
  $SLEEP_CMD "$delay"
done
