#!/bin/sh
# scripts/fetch.sh
# Fetch a URL with exponential backoff and retries
# Usage: fetch.sh <url> [retries] [timeout]
# Echoes response or exits nonzero

set -eu
# Load environment overrides and project config if available
if [ -f "$(dirname "$0")/lib/load_env.sh" ]; then . "$(dirname "$0")/lib/load_env.sh"; fi
if [ -f "$(dirname "$0")/lib/load_config.sh" ]; then sh "$(dirname "$0")/lib/load_config.sh"; fi
if [ -f "$(dirname "$0")/lib/load_seek_pagination.sh" ]; then sh "$(dirname "$0")/lib/load_seek_pagination.sh"; fi

url="$1"
retries="${2:-3}"
timeout="${3:-15}"
# Support BACKOFF_SEQUENCE env var (comma or space separated), default to 5,20,60
BACKOFF_SEQUENCE="${BACKOFF_SEQUENCE:-5,20,60}"
# Convert comma to space list for indexing
backoff_seq=$(printf '%s' "$BACKOFF_SEQUENCE" | tr ',' ' ')
# Allow overriding curl command (useful for tests)
CURL_CMD="${CURL_CMD:-curl}"
# User-Agent handling: UA_ROTATE, UA_LIST_PATH or USER_AGENT
UA_ROTATE="${UA_ROTATE:-false}"
USER_AGENT_OVERRIDE="${USER_AGENT:-}"
UA_LIST_PATH="${UA_LIST_PATH:-configs/user_agents.txt}"
# 403 handling: allow extra retries and UA rotation (defaults)
RETRY_ON_403="${RETRY_ON_403:-true}"
EXTRA_403_RETRIES="${EXTRA_403_RETRIES:-2}"
# Default browser-like headers
ACCEPT_HEADER="${ACCEPT_HEADER:-text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8}"
ACCEPT_LANGUAGE="${ACCEPT_LANGUAGE:-en-AU,en;q=0.9}"
# Allow curl to use compressed transfer encodings
CURL_COMPRESSED="--compressed"

# Basic robots.txt verification helper (naive): returns 0 if allowed, 1 if disallowed or undetermined
allowed_by_robots() {
  verify="${VERIFY_ROBOTS:-false}"
  if [ "$verify" != "true" ]; then
    return 0
  fi
  # extract scheme+host and path
  host_path=$(echo "$url" | sed -E 's#^(https?://[^/]+)(/.*)?#\1 \2#')
  host=$(printf '%s' "$host_path" | awk '{print $1}')
  path=$(printf '%s' "$host_path" | awk '{print $2}'); path=${path:-/}
  robots_url="$host/robots.txt"
  # fetch robots.txt (do not retry here)
  robots=$($CURL_CMD -sS --max-time 10 "$robots_url" 2>/dev/null || true)
  if [ -z "$robots" ]; then
    # no robots found - be conservative and allow
    return 0
  fi
  # Very small parser: find lines under User-agent: * until next User-agent or EOF
  awk_script="BEGIN{ua=0} /^User-agent:/ {ua=(\$0 ~ /User-agent:[[:space:]]*\*/)?1:0} ua && /^Disallow:/ {print \$0}"
  disallows=$(printf '%s' "$robots" | awk "$awk_script")
  # Iterate disallow entries and check for prefix match against the path
  # Use a heredoc to read lines in the current shell (avoid subshells)
  if [ -n "$disallows" ]; then
    while IFS= read -r line; do
      dis=$(printf '%s' "$line" | sed -E 's/^Disallow:[[:space:]]*//')
      # empty disallow means allow all
      if [ -z "$dis" ]; then
        continue
      fi
      if [ "$dis" = "/" ]; then
        return 1
      fi
      case "$path" in
        "$dis"* ) return 1 ;;
        *) ;;
      esac
    done <<-EOF
$disallows
EOF
  fi
  return 0
}

# Select a User-Agent string
# prefer central UA chooser if available
if [ -f "$(dirname "$0")/lib/ua_utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$(dirname "$0")/lib/ua_utils.sh"
else
  choose_ua() {
    if [ "$UA_ROTATE" = "true" ] && [ -f "$UA_LIST_PATH" ]; then
      awk -f scripts/lib/pick_random.awk "$UA_LIST_PATH"
    elif [ -n "$USER_AGENT_OVERRIDE" ]; then
      printf '%s' "$USER_AGENT_OVERRIDE"
    else
      printf '%s' "elvis/1.0 (+https://example.com)"
    fi
  }
fi

# CAPTCHA detection helper
is_captcha() {
  printf '%s' "$1" | grep -qiE 'captcha|recaptcha|g-recaptcha' && return 0 || return 1
}

for attempt in $(seq 1 "$retries"); do
  # check robots policy before first attempt
  if [ "$attempt" -eq 1 ]; then
    if ! allowed_by_robots; then
      echo "ERROR: blocked by robots.txt for $url" >&2
      exit 2
    fi
  fi
  ua_header=$(choose_ua)
  # Defensive: ensure a user-agent is present
  if [ -z "$ua_header" ]; then
    ua_header="elvis/1.0 (+https://example.com)"
  fi
  # derive host and referer to make requests appear like normal navigation
  host=$(printf '%s' "$url" | sed -E 's#^(https?://[^/]+)(/.*)?#\1#')
  referer="${REFERER:-$host}"
  # Capture response and HTTP status; log network events to ${NETWORK_LOG:-logs/network.log}
  resp_and_code=$($CURL_CMD -sS -w "\n---HTTP-STATUS:%{http_code}" --max-time "$timeout" -H "User-Agent: $ua_header" -H "Accept: $ACCEPT_HEADER" -H "Accept-Language: $ACCEPT_LANGUAGE" -H "Referer: $referer" $CURL_COMPRESSED "$url" 2>/dev/null || true)
  # If curl produced a response (possibly with trailing status) then parse it
  if [ -n "$resp_and_code" ]; then
    http_code=$(printf '%s' "$resp_and_code" | sed -n 's/.*---HTTP-STATUS:\([0-9][0-9][0-9]\)$/\1/p' || true)
    response=$(printf '%s' "$resp_and_code" | sed -e 's/\n---HTTP-STATUS:[0-9][0-9][0-9]$//')
    # Log: timestamp, url, attempt, http_code, bytes
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    bytes=$(printf '%s' "$response" | wc -c | tr -d ' ')
    mkdir -p "$(dirname "${NETWORK_LOG:-logs/network.log}")"
    printf '%s\t%s\t%d\t%s\t%d\n' "$ts" "$url" "$attempt" "${http_code:-0}" "$bytes" >> "${NETWORK_LOG:-logs/network.log}"

    # detect CAPTCHA signals and fail early
    if is_captcha "$response"; then
      echo "WARN: CAPTCHA or human check detected for $url" >&2
      # treat as fetch failure so caller can decide to skip the route
      SLEEP_CMD="${SLEEP_CMD:-sleep}"
      sleep_time=$(echo "$backoff_seq" | cut -d' ' -f"$attempt" 2>/dev/null || echo 60)
      echo "WARN: fetch failed (attempt $attempt), sleeping $sleep_time s..." >&2
      $SLEEP_CMD "$sleep_time"
      continue
    fi

    # If the status code was not provided by the curl wrapper (e.g. test mocks), treat non-empty response as success
    if [ -z "$http_code" ]; then
      printf '%s' "$response"
      exit 0
    fi
    # Otherwise require explicit 2xx HTTP codes
    if printf '%s' "$http_code" | grep -qE '^2[0-9][0-9]$'; then
      printf '%s' "$response"
      exit 0
    else
      if [ "$http_code" = "403" ] && [ "${RETRY_ON_403:-true}" = "true" ]; then
        echo "WARN: received HTTP 403 for $url; increasing retries by $EXTRA_403_RETRIES and rotating UA" >&2
        retries=$((retries + EXTRA_403_RETRIES))
        UA_ROTATE="true"
        SLEEP_CMD="${SLEEP_CMD:-sleep}"
        sleep_time=$(echo "$backoff_seq" | cut -d' ' -f"$attempt" 2>/dev/null || echo 60)
        echo "WARN: fetch (403) failed (attempt $attempt), sleeping $sleep_time s before retry..." >&2
        $SLEEP_CMD "$sleep_time"
        ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        mkdir -p "$(dirname "${NETWORK_LOG:-logs/network.log}")"
        printf '%s\t%s\t%d\t403\t%s\n' "$ts" "$url" "$attempt" "403-retry" >> "${NETWORK_LOG:-logs/network.log}"
        continue
      fi
      echo "WARN: non-success HTTP code $http_code for $url" >&2
      SLEEP_CMD="${SLEEP_CMD:-sleep}"
      sleep_time=$(echo "$backoff_seq" | cut -d' ' -f"$attempt" 2>/dev/null || echo 60)
      echo "WARN: fetch failed (attempt $attempt), sleeping $sleep_time s..." >&2
      $SLEEP_CMD "$sleep_time"
      continue
    fi
  fi
  SLEEP_CMD="${SLEEP_CMD:-sleep}"
  sleep_time=$(echo "$backoff_seq" | cut -d' ' -f"$attempt" 2>/dev/null || echo 60)
  echo "WARN: fetch failed (attempt $attempt), sleeping $sleep_time s..." >&2
  $SLEEP_CMD "$sleep_time"
done
echo "ERROR: fetch failed after $retries attempts: $url" >&2
exit 1
