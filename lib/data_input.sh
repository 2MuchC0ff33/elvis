#!/bin/sh
# data_input.sh - fetch pages for a single seed URL
# - honours robots.txt (if VERIFY_ROBOTS=true)
# - rotates UA from srv/ua.txt (if UA_ROTATE=true)
# - implements retries with exponential backoff (BACKOFF_SEQUENCE)
# - detects CAPTCHA markers and skips pages that present them
# - respects randomized delays between pages
# - emits lines of the form: Company Name | Location (pipe-separated)

set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/etc/elvisrc"

URL="$1"
if [ -z "$URL" ]; then
  echo "Usage: $0 <url>" >&2
  exit 2
fi

# Helpers
log() {
  ts="$(date +"$LOG_TIME_FORMAT")"
  printf "%s %s\n" "$ts" "$*" >> "$ROOT/$LOG_FILE"
}

log_network() {
  ts="$(date +"$LOG_TIME_FORMAT")"
  printf "%s\t%s\t%s\t%s\t%s\n" "$ts" "$1" "$2" "$3" "$4" >> "$ROOT/$LOG_FILE"
}

safe_filename() {
  # Convert URL to safe filename
  echo "$1" | sed 's/[^A-Za-z0-9._-]/_/g' | cut -c1-200
}

get_origin() {
  echo "$1" | sed -n 's#\(https\?://[^/]*\).*#\1#p'
}

choose_ua() {
  if [ "$UA_ROTATE" != "true" ] || [ ! -s "$ROOT/$UA_FILE" ]; then
    # fallback to a generic UA
    printf 'elvis-scraper/1.0 (+https://example.local)'
    return
  fi
  lines=$(wc -l < "$ROOT/$UA_FILE" | tr -d ' ')
  if [ "$lines" -eq 0 ]; then
    printf 'elvis-scraper/1.0 (+https://example.local)'
    return
  fi
  epoch=$(date +%s)
  idx=$(expr $epoch % $lines + 1)
  sed -n "${idx}p" "$ROOT/$UA_FILE" | head -n 1
}

check_robots() {
  # Basic robots.txt check: Disallow: / prevents all crawling
  if [ "$VERIFY_ROBOTS" != "true" ]; then
    return 0
  fi
  origin=$(get_origin "$URL") || return 0
  robots_file="$ROOT/$TMP_DIR/robots_$(echo "$origin" | sed 's/[^A-Za-z0-9]/_/g').txt"
  # Cache robots for the run
  if [ ! -f "$robots_file" ]; then
    curl -sS --max-time "$TIMEOUT" -A "elvis-robots-check" "$origin/robots.txt" > "$robots_file" || :
  fi
  # Check for User-agent: * then Disallow: /
  awk 'BEGIN{ua=0} /^User-agent:/ {ua=(tolower($0) ~ /user-agent:\s*\*/)} ua && /^Disallow:/ {if ($0 ~ /Disallow:\s*\/\s*$/) {print "DISALLOWED"; exit 0}}' "$robots_file" | grep -q . && return 1 || return 0
}

random_delay() {
  # Sleep a randomized interval between DELAY_MIN and DELAY_MAX
  min="$DELAY_MIN"; max="$DELAY_MAX"
  s=$(awk -v min="$min" -v max="$max" 'BEGIN {srand(); printf "%.3f", min + rand()*(max-min)}')
  sleep "$s"
}

get_next_link() {
  # Tries to find the Next page URL from HTML file passed as arg
  htmlfile="$1"
  # Try aria-label="Next"
  next=$(awk 'BEGIN{IGNORECASE=1} /aria-label=\"Next\"/ {gsub(/.*href=\"|\".*/,"",$0); if (match($0, /href=\"[^\"]+\"/)) {s=substr($0,RSTART,RLENGTH); gsub(/href=\"|\"/,"",s); print s; exit}}' "$htmlfile")
  if [ -n "$next" ]; then printf "%s" "$next"; return 0; fi
  # Try rel="next"
  next=$(grep -i 'rel="next"' -m1 "$htmlfile" 2>/dev/null | sed -n 's/.*href="\([^"]*\)".*/\1/p')
  if [ -n "$next" ]; then printf "%s" "$next"; return 0; fi
  return 1
}

# Start process
if ! check_robots; then
  log "WARN" "robots.txt disallows crawling of $URL; skipping"
  exit 0
fi

# Pagination loop
seed="$URL"
count_pages=0
current="$seed"
while :; do
  if [ "$count_pages" -ge "$PAGINATION_MAX_PAGES" ]; then
    log "WARN" "Reached PAGINATION_MAX_PAGES for $seed; stopping to avoid loops"
    break
  fi
  count_pages=$(expr $count_pages + 1)

  safe="$(safe_filename "$current")"
  out="$ROOT/$SRC_DIR/${safe}.html"

  # Determine UA
  UA="$(choose_ua)"

  # Retries with exponential backoff
  attempt=0
  extra403=0
  fetched=0
  http_code=0
  for backoff in $BACKOFF_SEQUENCE; do
    attempt=$(expr $attempt + 1)
    # Adjust 403-specific retries
    if [ "$RETRY_ON_403" = "true" ] && [ "$extra403" -gt 0 ]; then
      : # use extra403 to influence loop termination
    fi
    # Fetch page
    curl -sS -L --max-time "$TIMEOUT" -A "$UA" -o "$out" "$current"
    http_code=$(printf "$(curl -s -I -L --max-time "$TIMEOUT" -A "$UA" -o /dev/null -w '%{http_code}' "$current")") || http_code=0
    size=$(wc -c < "$out" 2>/dev/null || echo 0)
    log_network "$current" "$attempt" "$http_code" "$size"

    # CAPTCHA detection
    if grep -iE "$CAPTCHA_PATTERNS" "$out" >/dev/null 2>&1; then
      log "WARN" "CAPTCHA detected on $current; skipping further attempts"
      fetched=0
      break  # stop retries for this page
    fi

    case "$http_code" in
      200)
        fetched=1
        break
        ;;
      403)
        # special handling for 403
        if [ "$RETRY_ON_403" = "true" ]; then
          if [ "$extra403" -lt "$EXTRA_403_RETRIES" ]; then
            extra403=$(expr $extra403 + 1)
            sleep "$backoff"
            continue
          fi
        fi
        ;;
      *)
        # For other codes, continue retrying up to MAX_RETRIES
        ;;
    esac

    # sleep backoff before next attempt
    sleep "$backoff"
  done

  if [ "$fetched" -ne 1 ]; then
    log "WARN" "Failed to fetch $current after $attempt attempts; skipping page"
    # try to continue to next page if link exists
  else
    # parse content with AWK-first parser; loop.aw produces 'Company Name | Location' lines to stdout
    # We also use sed fallback if AWK emits nothing for the page
    $ROOT/lib/loop.aw "$out" || :
    # If AWK emitted nothing, try sed fallback
    if ! $ROOT/lib/loop.aw "$out" | grep -q .; then
      sed -n -f "$ROOT/lib/pattern_matching.sed" "$out" || :
    fi
  fi

  # find next page link
  if next_href="$(get_next_link "$out")"; then
    # resolve relative URLs
    if echo "$next_href" | grep -qE '^https?://'; then
      current="$next_href"
    else
      origin="$(get_origin "$seed")"
      current="$origin$(printf '%s' "$next_href" | sed 's/^\/*/\//')"
    fi
    log "INFO" "Next page discovered for $seed -> $current"
    # respect randomized delay between pages
    random_delay
    continue
  else
    # authoritative stop: no next link
    log "INFO" "No Next control found; stopping pagination for $seed"
    break
  fi

done

exit 0
