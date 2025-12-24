#!/bin/sh
# scripts/lib/cleanup.sh
# Minimal safe cleanup helpers for Elvis end-sequence workflow.
# Exports: cleanup_tmp [--dry-run] [--keep-days N] [paths...]

set -euo pipefail

cleanup_tmp() {
  dry_run=false
  keep_days=0
  paths=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)
        dry_run=true
        ;;
      --keep-days)
        shift
        keep_days=${1:-0}
        ;;
      --)
        shift
        break
        ;;
      -*) echo "ERROR: unknown option: $1" >&2; return 2;;
      *) paths="$paths $1";;
    esac
    shift
  done

  if [ -z "$paths" ]; then
    # default to repo tmp dir
    paths="$PWD/tmp"
  fi

  for p in $paths; do
    if [ ! -e "$p" ]; then
      echo "WARN: path does not exist, skipping: $p" >&2
      continue
    fi

    if [ "$dry_run" = true ]; then
      echo "DRY-RUN: would clean: $p"
      if [ "$keep_days" -gt 0 ]; then
        echo "DRY-RUN: would remove files older than $keep_days days under $p"
      fi
      continue
    fi

    if [ "$keep_days" -gt 0 ]; then
      find "$p" -type f -mtime +"$keep_days" -print -exec rm -f {} \; || true
      find "$p" -type d -empty -delete || true
    else
      # remove contents but keep directory
      if [ -d "$p" ]; then
        rm -rf "$p"/* || true
      else
        rm -f "$p" || true
      fi
    fi
  done
}

# Allow script to be executed directly
if [ "${0##*/}" = "cleanup.sh" ]; then
  cleanup_tmp "$@"
fi
