#!/bin/sh
# scripts/log_status.sh
# Log run summaries and write audit records
# Usage: log_status.sh --input file --msg "summary" --audit-file audit.txt

set -eu

INPUT=""
MSG=""
AUDIT="audit.txt"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      shift; INPUT="$1";;
    --msg)
      shift; MSG="$1";;
    --audit-file)
      shift; AUDIT="$1";;
    *) ;;
  esac
  shift || true
done

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOGFILE="logs/log.txt"
mkdir -p "$(dirname "$LOGFILE")"

if [ -n "$INPUT" ] && [ -f "$INPUT" ]; then
  total=$(tail -n +2 "$INPUT" | wc -l | tr -d ' ')
else
  total=0
fi

echo "$TS input=$INPUT total=$total msg=$MSG" >> "$LOGFILE"

# Append audit line
echo "$TS | input=$INPUT | total=$total | $MSG" >> "$AUDIT"

echo "Logged: $MSG (total=$total)"
exit 0
