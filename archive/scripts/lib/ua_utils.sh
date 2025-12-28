#!/bin/sh
# scripts/lib/ua_utils.sh
# Helper to choose a randomized, cleaned User-Agent string from a UA list.
# Usage: . scripts/lib/ua_utils.sh && choose_ua

choose_ua() {
  # prefer explicit UA_LIST_PATH, otherwise default to data/ua.txt then configs/user_agents.txt
  UA_LIST_PATH="${UA_LIST_PATH:-data/ua.txt}"
  [ -f "$UA_LIST_PATH" ] || UA_LIST_PATH="${UA_LIST_PATH:-configs/user_agents.txt}"

  # If UA rotation disabled, fall back to USER_AGENT env or default
  if [ "${UA_ROTATE:-false}" != "true" ]; then
    if [ -n "${USER_AGENT:-}" ]; then
      printf '%s' "${USER_AGENT}"
      return 0
    fi
    printf '%s' "elvis/1.0 (+https://example.com)"
    return 0
  fi

  if [ ! -f "$UA_LIST_PATH" ]; then
    # No UA list available
    if [ -n "${USER_AGENT:-}" ]; then
      printf '%s' "${USER_AGENT}"
      return 0
    fi
    printf '%s' "elvis/1.0 (+https://example.com)"
    return 0
  fi

  # Filter and clean UA lines, remove surrounding quotes and trim whitespace.
  # Skip known crawler/bot signatures unless ALLOW_BOTS=true
  awk -v allow_bots="${ALLOW_BOTS:-false}" 'function ltrim(s){sub(/^[ \t\r\n]+/,"",s);return s} function rtrim(s){sub(/[ \t\r\n]+$/,"",s);return s} {
      line=$0
      # strip surrounding whitespace and quotes (single or double) using safe char class
      gsub(/^[[:space:]\047\"]+|[[:space:]\047\"]+$/,"",line)
      if (line == "") next
      low = tolower(line)
      if (allow_bots != "true" && low ~ /(googlebot|bingbot|slurp|facebookbot|bot\/|crawler|spider|yahooseeker)/) next
      print line
    }' "$UA_LIST_PATH" | awk -f "$(dirname "$0")/lib/pick_random.awk"
}
