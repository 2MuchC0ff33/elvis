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
# shellcheck source=/dev/null
if [ -f "$ROOT/etc/elvisrc" ]; then
  . "$ROOT/etc/elvisrc"
fi

# Debug: print ROOT and SRC_DIR
echo "DEBUG: ROOT=$ROOT SRC_DIR=$SRC_DIR" >&2

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
  # delegate safe filename creation to a small AWK script
  echo "$1" | awk -f "$ROOT/lib/safe_filename.awk"
}

# Example invocation to avoid SC2329 warning
if [ "${DEBUG_SAFE_FILENAME:-}" = "true" ]; then
  echo "DEBUG: safe_filename for $URL: $(safe_filename "$URL")" >&2
fi
get_origin() {
  # delegate origin extraction to a small AWK script
  echo "$1" | awk -f "$ROOT/lib/get_origin.awk"
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
  idx=$((epoch % lines + 1))
  sed -n "${idx}p" "$ROOT/$UA_FILE" | head -n 1
}

check_robots() {
  # Basic robots.txt check: Disallow: / prevents all crawling
  if [ "$VERIFY_ROBOTS" != "true" ]; then
    return 0
  fi
  origin=$(get_origin "$URL") || return 0
  # Sanitize origin to a safe filename using sed script in lib/
  safe_origin=$(echo "$origin" | sed -n -f "$ROOT/lib/origin_sanitize.sed")
  robots_file="$ROOT/$TMP_DIR/robots_${safe_origin}.txt"
  # Cache robots for the run
  if [ ! -f "$robots_file" ]; then
    curl -sS --max-time "$TIMEOUT" -A "elvis-robots-check" "$origin/robots.txt" > "$robots_file" || :
  fi
  # Check for User-agent: * then Disallow: / using dedicated AWK script
  if awk -f "$ROOT/lib/robots_disallow.awk" "$robots_file" | grep -q .; then
    return 1
  else
    return 0
  fi
}

random_delay() {
  # Sleep a randomized interval between DELAY_MIN and DELAY_MAX
  min="$DELAY_MIN"; max="$DELAY_MAX"
  s=$(awk -v min="$min" -v max="$max" -f "$ROOT/lib/random_delay.awk")
  sleep "$s"
}

get_next_link() {
  # Delegates next-link extraction to a separate AWK script to satisfy the "AWK-first" and refactor rules.
  htmlfile="$1"
  awk -f "$ROOT/lib/get_next.awk" "$htmlfile" | sed -n '1p'
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
  count_pages=$((count_pages + 1))

  # Determine safe output path (use AWK helper to sanitize URL)
  safe=$(printf '%s' "$current" | awk -f "$ROOT/lib/safe_filename.awk")
  out="$SRC_DIR/${safe}.html"

  # Determine UA (rotated per attempt)
  UA="$(choose_ua)"

  # Debug: print output file and URL
  echo "DEBUG: curl -o $out $current" >&2

  # Prepare visited tracking to avoid infinite loops for this seed
  visited_file="$ROOT/$TMP_DIR/visited_$$.txt"
  touch "$visited_file"

  # Retries with exponential backoff and proper HTTP status capture (single curl call per attempt)
  attempt=1
  fetched=0
  extra403_count=0
  max_attempts="$MAX_RETRIES"

  while [ "$attempt" -le "$max_attempts" ]; do
    # choose UA per attempt (helps rotate on 403)
    UA="$(choose_ua)"

    # pick a backoff value for this attempt from BACKOFF_SEQUENCE (use last value if attempts exceed sequence length)
    backoff=$(echo "$BACKOFF_SEQUENCE" | awk -v i="$attempt" -f "$ROOT/lib/backoff.awk")

      # Single curl invocation that writes body to $out and prints HTTP code and effective_url to stdout which we capture
    resp=$(curl -sS -L --max-time "$TIMEOUT" --connect-timeout "$TIMEOUT" -A "$UA" -w '%{http_code}|%{url_effective}' -o "$out" "$current" 2>>"$ROOT/var/log/curl_stderr.log" || echo "000|")
    http_code=${resp%%|*}
    # eff_url is not used, so we omit assignment to avoid SC2034
    size=$(wc -c < "$out" 2>/dev/null || echo 0)
    log_network "$current" "$attempt" "$http_code" "$size"

    # CAPTCHA detection - stop immediately if found
    if grep -iE "$CAPTCHA_PATTERNS" "$out" >/dev/null 2>&1; then
      log "WARN" "CAPTCHA detected on $current; skipping further attempts"
      fetched=0
      break
    fi

    case "$http_code" in
      200)
        fetched=1
        break
        ;;
      403)
        if [ "$RETRY_ON_403" = "true" ] && [ "$extra403_count" -lt "$EXTRA_403_RETRIES" ]; then
          extra403_count=$((extra403_count + 1))
          log "INFO" "Received 403 on $current; rotating UA and retrying (extra403 #$extra403_count)"
          attempt=$((attempt + 1))
          sleep "$backoff"
          continue
        fi
        ;;
      000)
        log "WARN" "Curl invocation failed (timeout or network) for $current on attempt $attempt"
        ;;
      *)
        log "WARN" "Unexpected http_code=$http_code for $current on attempt $attempt"
        ;;
    esac

    attempt=$((attempt + 1))
    # sleep backoff before next attempt unless this was the last attempt
    if [ "$attempt" -le "$max_attempts" ]; then
      sleep "$backoff"
    fi
  done

  if [ "$fetched" -ne 1 ]; then
    log "WARN" "Failed to fetch $current after $((attempt-1)) attempts; skipping page"
  else
    # SED-first extraction: produce COMPANY:/LOCATION: lines then pair with AWK
    tmp_sed="$ROOT/$TMP_DIR/sed_$$.txt"
    sed -n -f "$ROOT/lib/extract_jobs.sed" "$out" > "$tmp_sed" || :

    # Pair COMPANY and LOCATION into rows
    tmp_parsed="$ROOT/$TMP_DIR/parsed_$$.txt"
    awk -f "$ROOT/lib/pair_sed.awk" "$tmp_sed" > "$tmp_parsed" || :

    # If we found rows, emit them; else fallback to AWK parser
    if [ -s "$tmp_parsed" ]; then
      cat "$tmp_parsed"
    else
      # Fallback to AWK-first parser
      awk -f "$ROOT/lib/loop.awk" "$out" || :
      # second fallback: sed pattern_matching
      if ! awk -f "$ROOT/lib/loop.awk" "$out" | grep -q .; then
        sed -n -f "$ROOT/lib/pattern_matching.sed" "$out" || :
      fi
    fi

    rm -f "$tmp_sed" "$tmp_parsed"
  fi

  # find next page link
  if next_href="$(get_next_link "$out")"; then
    # resolve relative URLs
    if echo "$next_href" | grep -qE '^https?://'; then
      new_url="$next_href"
    else
      origin="$(get_origin "$seed")"
      relpath=$(printf '%s' "$next_href" | awk -f "$ROOT/lib/normalize_relpath.awk")
      new_url="$origin$relpath"
    fi

    # Avoid loops: if new_url equals current or we've already visited it, stop
    if [ "$new_url" = "$current" ]; then
      log "WARN" "Next page equals current ($current); stopping to avoid loop"
      break
    fi
    if grep -Fxq "$new_url" "$visited_file" 2>/dev/null; then
      log "WARN" "Next page $new_url already visited for $seed; stopping to avoid loop"
      break
    fi

    # If next points to origin root (no useful pagination), stop
    origin_root="$(get_origin "$seed")/"
    case "$new_url" in
      "$origin_root"|"$origin_root"*)
        log "WARN" "Next page resolves to origin root ($new_url); stopping to avoid irrelevant pages"
        break
        ;;
    esac

    current="$new_url"
    echo "$current" >> "$visited_file"
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
