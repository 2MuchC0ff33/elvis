#!/bin/sh
# scripts/lib/error.sh
# Provides basic error-handling utilities: trap handler, safe_run, retry_with_backoff
# Usage: . scripts/lib/error.sh  (then call safe_run "step-name" cmd args...)

set -euo pipefail

# Basic on-err handler: logs and leaves status files
on_err() {
  rc=$?
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "ERROR: step failed (rc=$rc) at $ts" >> logs/log.txt
  # write a failure marker for operator inspection
  echo "failed:$rc:$ts" > "tmp/last_failed.status" || true
}

# safe_run: run a command, record start/stop, and return exit code
# Usage: safe_run "step-name" <cmd> [args...]
safe_run() {
  step_name="$1"
  shift || true
  start_ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  mkdir -p tmp
  echo "RUN: $step_name:start:$start_ts" >> logs/log.txt || true
  echo "running:$start_ts" > "tmp/${step_name}.status" || true

  # Run the command, capture exit code
  if "$@"; then
    rc=0
  else
    rc=$?
  fi

  end_ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  if [ "$rc" -eq 0 ]; then
    echo "RUN: $step_name:ok:$end_ts" >> logs/log.txt || true
    echo "ok:$end_ts" > "tmp/${step_name}.status" || true
    return 0
  else
    echo "RUN: $step_name:failed:$end_ts rc=$rc" >> logs/log.txt || true
    echo "failed:$rc:$end_ts" > "tmp/${step_name}.status" || true
    return $rc
  fi
}

# retry_with_backoff: run a command with retries and exponential backoff
# Usage: retry_with_backoff <retries> <cmd> [args...]
retry_with_backoff() {
  retries="$1"; shift
  attempt=1
  backoff_seq="5 20 60"
  while [ $attempt -le "$retries" ]; do
    if "$@"; then
      return 0
    fi
    # compute sleep time from sequence or last value
    sleep_time=$(echo "$backoff_seq" | awk -v a=$attempt '{n=split($0,s," "); if(a<=n) print s[a]; else print s[n]}')
    # add small jitter
    jitter=$(expr $RANDOM % 3)
    sleep_time=$(expr $sleep_time + $jitter)
    echo "WARN: attempt $attempt failed; sleeping $sleep_time s before retry" >> logs/log.txt || true
    sleep "$sleep_time"
    attempt=$((attempt + 1))
  done
  return 1
}

# Helper to install trap in scripts that source this file
install_trap() {
  # Install ERR trap to call on_err
  trap 'on_err' ERR
}

# If executed directly, show usage
if [ "${0##*/}" = "error.sh" ]; then
  echo "This file is intended to be sourced: . scripts/lib/error.sh" >&2
  exit 2
fi
