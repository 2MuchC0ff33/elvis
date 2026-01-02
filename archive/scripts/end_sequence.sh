#!/bin/sh
# scripts/end_sequence.sh
# Orchestrator for end-sequence workflow: archive -> cleanup -> summarise
# Usage: end_sequence.sh [--no-archive] [--no-cleanup] [--no-summary] [--snapshot-desc "text"] [--dry-run] [--continue-on-error]

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/error.sh"
# install trap for errors (optional, keeps on_err available)
install_trap || true
. "$SCRIPT_DIR/lib/archive.sh"
. "$SCRIPT_DIR/lib/cleanup.sh"
. "$SCRIPT_DIR/lib/summarise.sh"
. "$SCRIPT_DIR/lib/heal.sh"

no_archive=false
no_cleanup=false
no_summary=false
snapshot_desc="end-sequence"
dry_run=false
continue_on_error=false
# auto-heal feature (disabled by default)
auto_heal=false

while [ $# -gt 0 ]; do
  case "$1" in
    --no-archive) no_archive=true ;;
    --no-cleanup) no_cleanup=true ;;
    --no-summary) no_summary=true ;;
    --snapshot-desc) shift; snapshot_desc="$1" ;;
    --dry-run) dry_run=true ;;
    --continue-on-error) continue_on_error=true ;;
    --auto-heal) auto_heal=true ;;
    -h|--help)
      echo "Usage: $0 [--no-archive] [--no-cleanup] [--no-summary] [--snapshot-desc \"text\"] [--dry-run] [--continue-on-error] [--auto-heal]"
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
    if safe_run archive archive_artifacts --description "$snapshot_desc" data/calllists companies_history.txt logs 2>>logs/log.txt; then
      snapshot_path=""
      for file in "${SNAPSHOT_DIR:-.snapshots}"/snap-*; do
        [ -e "$file" ] || continue
        snapshot_path="$(basename "$file")"
      done
      echo "INFO: snapshot created: $snapshot_path" >> logs/log.txt
    else
      echo "ERROR: archive step failed" | tee -a logs/log.txt >&2
      if [ "$auto_heal" = true ]; then
        echo "HEAL: auto-heal enabled, attempting recovery for archive..." >> logs/log.txt
        # attempt recovery and re-run archive once
        attempt_recover_step archive "archive_artifacts --description '$snapshot_desc' data/calllists companies_history.txt logs" || true
        # try a re-run
        if safe_run archive archive_artifacts --description "$snapshot_desc" data/calllists companies_history.txt logs 2>>logs/log.txt; then
          snapshot_path=""
          for file in "${SNAPSHOT_DIR:-.snapshots}"/snap-*; do
            [ -e "$file" ] || continue
            snapshot_path="$(basename "$file")"
          done
          echo "INFO: snapshot created after recovery: $snapshot_path" >> logs/log.txt
        else
          run_failed=1
          [ "$continue_on_error" = true ] || exit 3
        fi
      else
        run_failed=1
        [ "$continue_on_error" = true ] || exit 3
      fi
    fi
  fi
fi

# 2) Cleanup
if [ "$no_cleanup" = false ]; then
  if [ "$dry_run" = true ]; then
    echo "DRY-RUN: would clean tmp and other artefacts..."
  else
    echo "INFO: cleaning temporary files..." >> logs/log.txt
    if safe_run cleanup cleanup_tmp tmp 2>>logs/log.txt; then
      echo "INFO: cleanup completed" >> logs/log.txt
    else
      echo "ERROR: cleanup step failed" | tee -a logs/log.txt >&2
      if [ "$auto_heal" = true ]; then
        echo "HEAL: auto-heal enabled, attempting recovery for cleanup..." >> logs/log.txt
        attempt_recover_step cleanup "cleanup_tmp tmp" || true
        if safe_run cleanup cleanup_tmp tmp 2>>logs/log.txt; then
          echo "INFO: cleanup completed after recovery" >> logs/log.txt
        else
          run_failed=1
          [ "$continue_on_error" = true ] || exit 4
        fi
      else
        run_failed=1
        [ "$continue_on_error" = true ] || exit 4
      fi
    fi
  fi
fi

# 3) Summarise
if [ "$no_summary" = false ]; then
  if [ "$dry_run" = true ]; then
    echo "DRY-RUN: would generate summary..."
  else
    echo "INFO: generating summary..." >> logs/log.txt
    if generate_summary summary.txt --append 2>>logs/log.txt; then
      echo "INFO: summary written to summary.txt" >> logs/log.txt
    else
      echo "ERROR: summary step failed" | tee -a logs/log.txt >&2
      if [ "$auto_heal" = true ]; then
        echo "HEAL: auto-heal enabled, attempting recovery for summarise..." >> logs/log.txt
        attempt_recover_step summarise "generate_summary summary.txt --append" || true
        if generate_summary summary.txt --append 2>>logs/log.txt; then
          echo "INFO: summary written to summary.txt after recovery" >> logs/log.txt
        else
          run_failed=1
          [ "$continue_on_error" = true ] || exit 5
        fi
      else
        run_failed=1
        [ "$continue_on_error" = true ] || exit 5
      fi
    fi
  fi
fi

if [ "$run_failed" -ne 0 ]; then
  echo "END-SEQUENCE: completed with errors" | tee -a logs/log.txt >&2
  exit 6
fi

echo "END-SEQUENCE: completed successfully" >> logs/log.txt
exit 0
