#!/bin/sh
# scripts/fetch.sh
# Fetch a URL with exponential backoff and retries
# Usage: fetch.sh <url> [retries] [timeout]
# Echoes response or exits nonzero

set -eu
url="$1"
retries="${2:-3}"
timeout="${3:-15}"
backoff_seq="5 20 60"

for attempt in $(seq 1 "$retries"); do
	if response=$(curl -sS --max-time "$timeout" "$url"); then
		echo "$response"
		exit 0
	fi
	sleep_time=$(echo $backoff_seq | cut -d' ' -f$attempt 2>/dev/null || echo 60)
	echo "WARN: fetch failed (attempt $attempt), sleeping $sleep_time s..." >&2
	sleep "$sleep_time"
done
echo "ERROR: fetch failed after $retries attempts: $url" >&2
exit 1
