#!/bin/sh
# scripts/lib/http_utils.sh
# Minimal HTTP helper functions used by fetchers. Exported functions:
#   fetch_with_backoff <url> [retries] [timeout]
# Returns: prints response body to stdout on success, non-zero exit on failure.

fetch_with_backoff() {
  url="$1"
  retries="${2:-3}"
  timeout="${3:-15}"
  BACKOFF_SEQUENCE="${BACKOFF_SEQUENCE:-5,20,60}"
  backoff_seq=$(printf '%s' "$BACKOFF_SEQUENCE" | tr ',' ' ')
  CURL_CMD="${CURL_CMD:-curl}"
  UA_ROTATE="${UA_ROTATE:-false}"
  USER_AGENT_OVERRIDE="${USER_AGENT:-}"
  UA_LIST_PATH="${UA_LIST_PATH:-configs/user_agents.txt}"

  if [ -z "$url" ]; then
    echo "ERROR: fetch_with_backoff requires a URL" >&2
    return 2
  fi

  choose_ua() {
    if [ "$UA_ROTATE" = "true" ] && [ -f "$UA_LIST_PATH" ]; then
      awk 'BEGIN{srand();} {a[NR]=$0} END{if(NR>0) print a[int(rand()*NR)+1]}' "$UA_LIST_PATH"
    elif [ -n "$USER_AGENT_OVERRIDE" ]; then
      printf '%s' "$USER_AGENT_OVERRIDE"
    else
      printf '%s' "elvis/1.0 (+https://example.com)"
    fi
  }

  is_captcha() {
    printf '%s' "$1" | grep -qiE 'captcha|recaptcha|g-recaptcha' && return 0 || return 1
  }

  allowed_by_robots() {
    verify="${VERIFY_ROBOTS:-false}"
    if [ "$verify" != "true" ]; then
      return 0
    fi
    host_path=$(echo "$url" | sed -E 's#^(https?://[^/]+)(/.*)?#\1 \2#')
    host=$(printf '%s' "$host_path" | awk '{print $1}')
    path=$(printf '%s' "$host_path" | awk '{print $2}'); path=${path:-/}
    robots_url="$host/robots.txt"
    robots=$($CURL_CMD -sS --max-time 10 "$robots_url" 2>/dev/null || true)
    if [ -z "$robots" ]; then
      return 0
    fi
    awk_script='BEGIN{ua=0} /^User-agent:/ {ua=($0 ~ /User-agent:[[:space:]]*\*/)?1:0} ua && /^Disallow:/ {print $0}'
    disallows=$(printf '%s' "$robots" | awk "$awk_script")
    if [ -n "$disallows" ]; then
      while IFS= read -r line; do
        dis=$(printf '%s' "$line" | sed -E 's/^Disallow:[[:space:]]*//')
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

  for attempt in $(seq 1 "$retries"); do
    # check robots policy before first attempt
    if [ "$attempt" -eq 1 ]; then
      if ! allowed_by_robots; then
        echo "ERROR: blocked by robots.txt for $url" >&2
        return 2
      fi
    fi
    ua_header=$(choose_ua)
    if response=$($CURL_CMD -sS --max-time "$timeout" -H "User-Agent: $ua_header" "$url" 2>/dev/null); then
      if is_captcha "$response"; then
        echo "WARN: CAPTCHA or human check detected for $url" >&2
        sleep_time=$(echo "$backoff_seq" | cut -d' ' -f"$attempt" 2>/dev/null || echo 60)
        echo "WARN: fetch failed (attempt $attempt), sleeping $sleep_time s..." >&2
        sleep "$sleep_time"
        continue
      fi
      printf '%s' "$response"
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

# Allow this script to be sourced
# Example: . scripts/lib/http_utils.sh && fetch_with_backoff "http://..."
