#!/bin/sh
# scripts/enrich.sh
# Thin wrapper for enrichment helpers. Delegates to scripts/enrich_status.sh
# Usage: enrich.sh [--input results.csv] [--out enriched.csv] [--edit]

set -eu

# Delegate to enrich_status.sh which implements the canonical behaviour.
exec sh "$(dirname "$0")/enrich_status.sh" "$@"
