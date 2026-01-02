#!/bin/sh
# tests/unit_paginate_sleep_marker.sh
# Tests paginate random delay + SLEEP_CMD and custom PAGE_NEXT_MARKER handling

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t pagtest)"
trap 'rm -rf "$tmp"' EXIT

# mock fetch that cycles through pages
cat > "$tmp/mock_fetch2.sh" <<'SH'
#!/bin/sh
COUNTER_FILE="$PWD/mock_fetch2.counter"
count=1
if [ -f "$COUNTER_FILE" ]; then count=$(cat "$COUNTER_FILE" | tr -d '[:space:]' || echo 1); fi
if [ "$count" -eq 1 ]; then
  printf '<html><body>page1<span data-automation="page-next"></span></body></html>'
elif [ "$count" -eq 2 ]; then
  printf '<html><body>page2<span data-automation="page-next"></span></body></html>'
else
  printf '<html><body>page3</body></html>'
fi
count=$((count+1))
printf '%s' "$count" > "$COUNTER_FILE"
SH
chmod +x "$tmp/mock_fetch2.sh"
# mock sleep that records value
cat > "$tmp/mock_sleep.sh" <<'SH'
#!/bin/sh
printf '%s' "$1" > "$PWD/mock_sleep.called"
exit 0
SH
chmod +x "$tmp/mock_sleep.sh"
export DELAY_MIN=2
export DELAY_MAX=2
# ensure PAGE_NEXT_MARKER is set for tests
export PAGE_NEXT_MARKER='data-automation="page-next"'
# ensure OFFSET_STEP is set (Seek default)
export OFFSET_STEP=22
# ensure MAX_PAGES set for safety
export MAX_PAGES=5
# override FETCH_SCRIPT and SLEEP_CMD
FETCH_SCRIPT="$tmp/mock_fetch2.sh" SLEEP_CMD="$tmp/mock_sleep.sh" sh "$REPO_ROOT/scripts/lib/paginate.sh" 'http://x' 'PAG_PAGE' > "$tmp/pag.out" || true
sleep_file_search=$(find . -maxdepth 2 -name 'mock_sleep.called' -print -quit || true)
if [ -n "$sleep_file_search" ]; then
  called=$(cat "$sleep_file_search")
  case "$called" in
    2|2.000|2.0) echo "PASS: paginate used SLEEP_CMD with $called" ;;
    *) echo "FAIL: unexpected sleep called: $called" >&2; exit 1 ;;
  esac
else
  echo "FAIL: paginate did not call SLEEP_CMD" >&2; exit 1
fi

# custom PAGE_NEXT_MARKER
cat > "$tmp/mock_fetch3.sh" <<'SH'
#!/bin/sh
FLAGFILE="/tmp/mock_fetch3_called_$$"
if [ ! -f "$FLAGFILE" ]; then
  printf '<html><body>first <span data-automation="NEXT-MY"></span></body></html>'
  touch "$FLAGFILE"
else
  printf '<html><body>final</body></html>'
fi
SH
chmod +x "$tmp/mock_fetch3.sh"
# run with custom marker
PAGE_NEXT_MARKER='data-automation="NEXT-MY"' MAX_PAGES=2 FETCH_SCRIPT="$tmp/mock_fetch3.sh" sh "$REPO_ROOT/scripts/lib/paginate.sh" 'http://x' 'PAG_PAGE' > "$tmp/pag3.out" || true
grep -q 'first' "$tmp/pag3.out" || { echo "FAIL: paginate custom marker not processed" >&2; exit 1; }

echo "PASS: unit_paginate_sleep_marker"
exit 0
