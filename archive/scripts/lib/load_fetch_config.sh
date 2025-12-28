#!/bin/sh
# scripts/lib/load_fetch_config.sh
# Load fetch-specific configuration from INI-style file (simple key=value)
# Usage: . scripts/lib/load_fetch_config.sh [INI_FILE]
# Exports keys as UPPERCASE variables if not already set in the environment

set -eu

INI_FILE="${1:-configs/fetch.ini}"
if [ ! -f "$INI_FILE" ]; then
  # Not fatal — fetch config is optional
  return 0
fi

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ''|\#*) continue ;;
    *=*)
      key=$(printf '%s' "$line" | cut -d= -f1 | tr -d ' ' | tr '[:lower:]' '[:upper:]')
      val=$(printf '%s' "$line" | cut -d= -f2- | sed -E 's/^ *//;s/ *$//')
      # export only if variable is not already set (env / project.conf take precedence)
      eval cur="\${$key:-}"
      if [ -z "${cur}" ]; then
        export "$key"="$val"
      fi
      ;;
    *) continue ;;
  esac
done < "$INI_FILE"

return 0
