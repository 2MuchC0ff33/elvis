#!/bin/sh
# scripts/lib/load_env.sh
# Safely load .env file into the environment (POSIX-compliant)
# Usage: . scripts/lib/load_env.sh [ENV_FILE]
# Exports variables from ENV_FILE (default: .env)

set -eu

ENV_FILE="${1:-.env}"
if [ ! -f "$ENV_FILE" ]; then
  # .env is optional; do not error if missing
  return 0
fi

tmp_env="$(mktemp)"
grep -E '^[A-Z0-9_]+=.*' "$ENV_FILE" > "$tmp_env"
while IFS='=' read -r key val; do
  case "$key" in
    ''|\#*) continue ;;
    *) export "$key"="$val" ;;
  esac
done < "$tmp_env"
rm -f "$tmp_env"
