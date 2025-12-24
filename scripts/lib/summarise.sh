#!/bin/sh
# scripts/lib/summarise.sh
# Provides: generate_summary [--out <file>] [--append]
# Generates a short summary of the run and writes to summary file (default ./summary.txt)

set -euo pipefail

generate_summary() {
  out_file="${1:-summary.txt}"
  append=false
  if [ "$1" = "--out" ]; then
    out_file="$2"
    shift 2
  fi
  # Accept --append flag
  for arg in "$@"; do
    if [ "$arg" = "--append" ]; then
      append=true
    fi
  done

  # Snapshot info
  SNAP_DIR="${SNAPSHOT_DIR:-.snapshots}"
  latest_snap=""
  archived_entries=0
  if [ -d "$SNAP_DIR" ]; then
    latest_snap=$(ls -1 "$SNAP_DIR" | grep '^snap-' | tail -n1 || true)
    if [ -n "$latest_snap" ]; then
      archived_entries=$(tar -tzf "$SNAP_DIR/$latest_snap" 2>/dev/null | wc -l || echo 0)
    fi
  fi

  # Calllists count
  calllists_count=0
  if [ -d "data/calllists" ]; then
    calllists_count=$(ls -1 data/calllists 2>/dev/null | wc -l || echo 0)
  fi

  # Log warnings count (grep WARN)
  warn_count=0
  if [ -f "logs/log.txt" ]; then
    warn_count=$(grep -c "WARN" logs/log.txt || true)
  fi

  # Summary lines
  summary_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  content="run_time: $summary_time\n"
  content="$content""latest_snapshot: ${latest_snap:-none}\n"
  content="$content""archived_files_count: $archived_entries\n"
  content="$content""calllists_count: $calllists_count\n"
  content="$content""log_warnings: $warn_count\n"

  if [ "$append" = true ]; then
    printf "%s\n" "$content" >> "$out_file"
  else
    printf "%s\n" "$content" > "$out_file"
  fi

  echo "$out_file"
}

if [ "${0##*/}" = "summarise.sh" ]; then
  generate_summary "$@"
fi
