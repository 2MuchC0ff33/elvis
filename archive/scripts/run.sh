#!/bin/sh
# scripts/run.sh
# Small convenience orchestrator for common workflows. Provides a simpler
# entrypoint for local runs. Supports: get-transaction-data, set-status, help

set -eu

case "${1:-}" in
  get-transaction-data)
    exec sh "$(dirname "$0")/get_transaction_data.sh";
    ;;
  set-status)
    shift
    exec sh "$(dirname "$0")/set_status.sh" "$@";
    ;;
  help|-h|--help|"" )
    echo "Usage: $0 get-transaction-data | set-status [--args] | help"
    exit 0
    ;;
  *)
    echo "Unknown command: ${1:-}" >&2
    echo "Usage: $0 get-transaction-data | set-status [--args] | help"
    exit 2
    ;;
esac
