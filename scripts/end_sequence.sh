#!/bin/sh
# scripts/end_sequence.sh
# Orchestrator for end-sequence workflow: archive -> cleanup -> summarise
# Usage: end_sequence.sh [--no-archive] [--no-cleanup] [--no-summary] [--snapshot-desc "text"] [--dry-run] [--continue-on-error]

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/archive.sh"
. "$SCRIPT_DIR/lib/cleanup.sh"
. "$SCRIPT_DIR/lib/summarise.sh"

no_archive=false
no_cleanup=false
no_summary=false
snapshot_desc="end-sequence"
dry_run=false
continue_on_error=false

while [ $# -gt 0 ]; do
  case "$1" in
    --no-archive) no_archive=true ;;
    --no-cleanup) no_cleanup=true ;;
    --no-summary) no_summary=true ;;
    --snapshot-desc) shift; snapshot_desc="$1" ;;
    --dry-run) dry_run=true ;;
    --continue-on-error) continue_on_error=true ;;
    -h|--help)
      echo "Usage: $0 [--no-archive] [--no-cleanup] [--no-summary] [--snapshot-desc \"text\"] [--dry-run] [--continue-on-error]"
      exit 0
      ;;
    *) echo "ERROR: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

run_failed=0
# Create logs dir if missing
mkdir -p logs

# 1) Archive
if [ "$no_archive" = false ]; then
  if [ "$dry_run" = true ]; then
    echo "DRY-RUN: would archive artifacts..."
  else
    echo "INFO: archiving artifacts..." >> logs/log.txt
    if ! snapshot_path=$(archive_artifacts --description "$snapshot_desc" data/calllists companies_history.txt logs 2>>logs/log.txt); then
      echo "ERROR: archive step failed" | tee -a logs/log.txt >&2
      run_failed=1
      [ "$continue_on_error" = true ] || exit 3
    else
      echo "INFO: snapshot created: $snapshot_path" >> logs/log.txt
    fi
  fi
fi

# 2) Cleanup
if [ "$no_cleanup" = false ]; then
  if [ "$dry_run" = true ]; then
    echo "DRY-RUN: would clean tmp and other artefacts..."
  else
    echo "INFO: cleaning temporary files..." >> logs/log.txt
    if ! cleanup_tmp tmp 2>>logs/log.txt; then
      echo "ERROR: cleanup step failed" | tee -a logs/log.txt >&2
      run_failed=1
      [ "$continue_on_error" = true ] || exit 4
    else
      echo "INFO: cleanup completed" >> logs/log.txt
    fi
  fi
fi

# 3) Summarise
if [ "$no_summary" = false ]; then
  if [ "$dry_run" = true ]; then
    echo "DRY-RUN: would generate summary..."
  else
    echo "INFO: generating summary..." >> logs/log.txt
    if ! generate_summary summary.txt --append 2>>logs/log.txt; then
      echo "ERROR: summary step failed" | tee -a logs/log.txt >&2
      run_failed=1
      [ "$continue_on_error" = true ] || exit 5
    else
      echo "INFO: summary written to summary.txt" >> logs/log.txt
    fi
  fi
fi

if [ "$run_failed" -ne 0 ]; then
  echo "END-SEQUENCE: completed with errors" | tee -a logs/log.txt >&2
  exit 6
fi

echo "END-SEQUENCE: completed successfully" >> logs/log.txt
exit 0
