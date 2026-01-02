#!/bin/sh
# scripts/fetch.sh
# Fetch a URL with exponential backoff and retries
# Usage: fetch.sh <url> [retries] [timeout]
# Echoes response or exits nonzero

set -eu
# Load environment overrides and project config if available
if [ -f "$(dirname "$0")/lib/load_env.sh" ]; then . "$(dirname "$0")/lib/load_env.sh"; fi
if [ -f "$(dirname "$0")/lib/load_config.sh" ]; then . "$(dirname "$0")/lib/load_config.sh" "$(cd "$(dirname "$0")/.." && pwd)/project.conf"; fi
# Load optional fetch-specific INI (configs/fetch.ini) to set fetch defaults if unset
if [ -f "$(dirname "$0")/lib/load_fetch_config.sh" ]; then . "$(dirname "$0")/lib/load_fetch_config.sh" "$(cd "$(dirname "$0")/.." && pwd)/configs/fetch.ini" || true; fi
# Load seek pagination config if present
if [ -f "$(dirname "$0")/lib/load_seek_pagination.sh" ]; then sh "$(dirname "$0")/lib/load_seek_pagination.sh"; fi

url="$1"
retries="${2:-3}"
timeout="${3:-15}"
# Ensure essential fetch-related configuration is provided by project.conf or .env
if [ -z "${BACKOFF_SEQUENCE:-}" ]; then
  echo "ERROR: BACKOFF_SEQUENCE not set (expected in project.conf or .env)" >&2
  exit 2
fi
# Convert comma to space list for indexing
backoff_seq=$(printf '%s' "$BACKOFF_SEQUENCE" | tr ',' ' ')
# Allow overriding curl command (should be set in project.conf)
if [ -z "${CURL_CMD:-}" ]; then
  echo "ERROR: CURL_CMD not set (expected in project.conf or .env)" >&2
  exit 2
fi
# User-Agent handling: UA_ROTATE, UA_LIST_PATH or USER_AGENT should come from config
if [ -z "${UA_ROTATE:-}" ]; then
  echo "ERROR: UA_ROTATE not set (expected in project.conf or .env)" >&2
  exit 2
fi
USER_AGENT_OVERRIDE="${USER_AGENT:-}"
if [ -z "${UA_LIST_PATH:-}" ]; then
  echo "ERROR: UA_LIST_PATH not set (expected in project.conf or .env)" >&2
  exit 2
fi
# 403 handling: expected from config
if [ -z "${RETRY_ON_403:-}" ]; then
  echo "ERROR: RETRY_ON_403 not set (expected in project.conf or .env)" >&2
  exit 2
fi
if [ -z "${EXTRA_403_RETRIES:-}" ]; then
  echo "ERROR: EXTRA_403_RETRIES not set (expected in project.conf or .env)" >&2
  exit 2
fi
# HTTP headers should come from config
if [ -z "${ACCEPT_HEADER:-}" ]; then
  echo "ERROR: ACCEPT_HEADER not set (expected in project.conf or .env)" >&2
  exit 2
fi
if [ -z "${ACCEPT_LANGUAGE:-}" ]; then
  echo "ERROR: ACCEPT_LANGUAGE not set (expected in project.conf or .env)" >&2
  exit 2
fi
# Allow curl to use compressed transfer encodings (constant)
CURL_COMPRESSED="--compressed"

# Ensure NETWORK_LOG is defined (use project.conf or .env)
if [ -z "${NETWORK_LOG:-}" ]; then
  echo "ERROR: NETWORK_LOG not set (expected in project.conf or .env)" >&2
  exit 2
fi

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
        # log robots disallow snippet for audit
        ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        mkdir -p "$(dirname "${NETWORK_LOG:-logs/network.log}")"
        printf '%s\t%s\t%d\t%s\t%s\n' "$ts" "$url" 0 "ROBOTSBLOCK" "$dis" >> "${NETWORK_LOG:-logs/network.log}"
        return 1
      fi
      case "$path" in
        "$dis"* )
          ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
          mkdir -p "$(dirname "${NETWORK_LOG:-logs/network.log}")"
          printf '%s\t%s\t%d\t%s\t%s\n' "$ts" "$url" 0 "ROBOTSBLOCK" "$dis" >> "${NETWORK_LOG:-logs/network.log}"
          return 1 ;;
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

# CAPTCHA detection helper: pattern must come from config
if [ -z "${CAPTCHA_PATTERNS:-}" ]; then
  echo "ERROR: CAPTCHA_PATTERNS not set (expected in project.conf or .env)" >&2
  exit 2
fi
is_captcha() {
  printf '%s' "$1" | grep -qiE "$CAPTCHA_PATTERNS" && return 0 || return 1
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
      # write a CAPTCHA entry to NETWORK_LOG to aid auditing
      ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      snippet=$(printf '%s' "$response" | grep -o -i -E "$CAPTCHA_PATTERNS" | head -n1 | tr -d '\n' || true)
      mkdir -p "$(dirname "${NETWORK_LOG:-logs/network.log}")"
      printf '%s\t%s\t%d\t%s\t%s\n' "$ts" "$url" "$attempt" "CAPTCHA" "$snippet" >> "${NETWORK_LOG:-logs/network.log}"
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
