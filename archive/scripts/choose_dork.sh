#!/bin/sh
# scripts/choose_dork.sh
# Present a numbered list of dork templates and open the selected query in a browser
# Usage: choose_dork.sh dork_templates.txt

set -eu
TEMPLATES_FILE="${1:-dork_templates.txt}"

if [ ! -f "$TEMPLATES_FILE" ]; then
  echo "ERROR: dork templates file not found: $TEMPLATES_FILE" >&2
  exit 2
fi

n=1
while IFS= read -r line; do
  [ -z "$line" ] && continue
  printf '%2d) %s\n' "$n" "$line"
  n=$((n+1))
done < "$TEMPLATES_FILE"

echo "Enter number to select a dork template:" >&2
read -r sel

if ! [ "$sel" -ge 1 ] 2>/dev/null; then
  echo "ERROR: invalid selection" >&2
  exit 2
fi

chosen=""
n=1
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if [ "$n" -eq "$sel" ]; then
    chosen="$line"
    break
  fi
  n=$((n+1))
done < "$TEMPLATES_FILE"

if [ -z "$chosen" ]; then
  echo "ERROR: selection out of range" >&2
  exit 2
fi

query_url="https://www.google.com.au/search?q=$(printf '%s' "$chosen" | sed 's/ /+/g')"
echo "Opening: $query_url"
# Try sensible browser openers
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$query_url"
elif command -v open >/dev/null 2>&1; then
  open "$query_url"
else
  echo "Please open this URL manually: $query_url"
fi
exit 0
