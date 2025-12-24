#!/bin/sh
# scripts/lib/heal.sh
# Minimal self-healing utilities for Elvis.
# Functions: attempt_recover_step <step-name> <cmd-to-rerun...>
#            preserve_failed_artifacts <step-name>

set -euo pipefail

preserve_failed_artifacts() {
  step_name="$1"
  ts=$(date -u +%Y%m%dT%H%M%SZ)
  SNAP_DIR="${SNAPSHOT_DIR:-.snapshots}"
  mkdir -p "$SNAP_DIR/failed"
  # Collect relevant files for debugging
  tmpdir="tmp/failed-${step_name}-$ts"
  mkdir -p "$tmpdir"
  # Copy status, logs, and any tmp artifacts
  cp -a tmp/${step_name}.status "$tmpdir/" 2>/dev/null || true
  cp -a logs/log.txt "$tmpdir/" 2>/dev/null || true
  # Create a tarball for later inspection
  tar -czf "$SNAP_DIR/failed/failed-${step_name}-$ts.tar.gz" -C "$tmpdir" . || true
  # record in log
  echo "HEAL: preserved failed artifacts for $step_name -> $SNAP_DIR/failed/failed-${step_name}-$ts.tar.gz" >> logs/log.txt || true
  # cleanup temp
  rm -rf "$tmpdir" || true
}

restore_latest_snapshot() {
  SNAP_DIR="${SNAPSHOT_DIR:-.snapshots}"
  latest=$(ls -1 "$SNAP_DIR" 2>/dev/null | grep '^snap-' | tail -n1 || true)
  if [ -z "$latest" ]; then
    echo "HEAL: no snapshot available" >> logs/log.txt || true
    return 1
  fi
  ts=$(date -u +%Y%m%dT%H%M%SZ)
  tmp_restore="tmp/restore-$ts"
  mkdir -p "$tmp_restore"
  tar -xzf "$SNAP_DIR/$latest" -C "$tmp_restore" || return 1
  echo "HEAL: restored snapshot $latest into $tmp_restore" >> logs/log.txt || true
  # return the restore dir path
  printf "%s" "$tmp_restore"
}

# attempt_recover_step: tries to preserve artifacts, optionally restore, and re-run
# Usage: attempt_recover_step <step-name> <cmd-to-rerun...>
attempt_recover_step() {
  step_name="$1"
  shift || true
  cmd="$@"
  echo "HEAL: attempt recovery for $step_name" >> logs/log.txt || true

  # preserve failed artifacts first
  preserve_failed_artifacts "$step_name"

  # try to restore latest snapshot if present
  restore_dir=$(restore_latest_snapshot || true)

  # optionally re-run the step (in the restored environment)
  if [ -n "$cmd" ]; then
    # if restore_dir provided, try to use it (simple heuristic: copy relevant files back)
    if [ -n "$restore_dir" ]; then
      # no-op for now; record the action
      echo "HEAL: using restored files from $restore_dir to help re-run $step_name" >> logs/log.txt || true
    fi
    # Attempt to re-run the provided command once
    if sh -c "$cmd"; then
      echo "HEAL: re-run succeeded for $step_name" >> logs/log.txt || true
      echo "recovered:true" > "tmp/${step_name}.recovered" || true
      return 0
    else
      echo "HEAL: re-run failed for $step_name" >> logs/log.txt || true
      return 1
    fi
  fi

  return 1
}

# If executed directly, show usage
if [ "${0##*/}" = "heal.sh" ]; then
  echo "This file is intended to be sourced: . scripts/lib/heal.sh" >&2
  exit 2
fi
