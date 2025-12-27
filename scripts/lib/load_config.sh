#!/bin/sh
# scripts/lib/load_config.sh
# Safely load project.conf into the environment (POSIX-compliant)
# Usage: . scripts/lib/load_config.sh [CONF_FILE]
# Exports variables from CONF_FILE (default: project.conf)

set -eu

CONF_FILE="${1:-project.conf}"
if [ ! -f "$CONF_FILE" ]; then
  echo "Error: Config file '$CONF_FILE' not found." >&2
  exit 1
fi

tmp_conf="$(mktemp)"
# Keep only simple key=value lines (ignore leading comment lines)
grep -E '^[A-Z0-9_]+=' "$CONF_FILE" > "$tmp_conf"
# Read and export, trimming whitespace and removing inline comments (after #)
while IFS='=' read -r key val; do
  case "$key" in
    ''|\#*) continue ;;
    *)
      # remove inline comments and trim whitespace from value
      # remove everything from first unescaped # onward
      val=$(printf '%s' "$val" | sed -E "s/[[:space:]]*#.*$//")
      # trim leading/trailing whitespace
      val=$(printf '%s' "$val" | sed -E 's/^[[:space:]]*//;s/[[:space:]]*$//')
      export "$key"="$val" ;;
  esac
done < "$tmp_conf"
rm -f "$tmp_conf"
