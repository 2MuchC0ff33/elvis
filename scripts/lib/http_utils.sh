#!/bin/sh
# scripts/lib/http_utils.sh
# Minimal HTTP helper functions used by fetchers. Exported functions:
#   fetch_with_backoff <url> [retries] [timeout]
# Returns: prints response body to stdout on success, non-zero exit on failure.

fetch_with_backoff() {
  url="$1"
  retries="${2:-3}"
  timeout="${3:-15}"
  backoff_seq="5 20 60"

  if [ -z "$url" ]; then
    echo "ERROR: fetch_with_backoff requires a URL" >&2
    return 2
  fi

  for attempt in $(seq 1 "$retries"); do
    if curl -sS --max-time "$timeout" "$url"; then
      return 0
    fi
    sleep_time=$(echo "$backoff_seq" | cut -d' ' -f"$attempt" 2>/dev/null || echo 60)
    echo "WARN: fetch failed (attempt $attempt), sleeping $sleep_time s..." >&2
    sleep "$sleep_time"
  done
  echo "ERROR: fetch failed after $retries attempts: $url" >&2
  return 1
}

# Allow this script to be sourced
# Example: . scripts/lib/http_utils.sh && fetch_with_backoff "http://..."
