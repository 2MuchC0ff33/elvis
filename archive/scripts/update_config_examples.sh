#!/bin/sh
# scripts/update_config_examples.sh
# Ensure .env.example and project.conf contain the same set of keys; add missing keys with placeholder values.

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_EXAMPLE="$REPO_ROOT/.env.example"
PROJECT_CONF="$REPO_ROOT/project.conf"

if [ ! -f "$ENV_EXAMPLE" ] || [ ! -f "$PROJECT_CONF" ]; then
  echo "ERROR: both $ENV_EXAMPLE and $PROJECT_CONF must exist" >&2
  exit 2
fi

extract_keys() {
  # prints KEY=VALUE lines (ignores comments and empty lines)
  awk -F= '/^[A-Z0-9_]+=/ {print $0}' "$1" | sed -E 's/[ \t]*$//'
}

# build associative key->value map by normalising lines
tmp_all_keys=$(mktemp)
trap 'rm -f "$tmp_all_keys"' EXIT

# collect keys from both files
awk -F= '/^[A-Z0-9_]+=/ {print $1"="substr($0, index($0,$2))}' "$PROJECT_CONF" | sed 's/[ \t]*$//' > "$tmp_all_keys" || true
awk -F= '/^[A-Z0-9_]+=/ {print $1"="substr($0, index($0,$2))}' "$ENV_EXAMPLE" >> "$tmp_all_keys" || true

# get unique keys (preserve first seen value)
awk -F= '!seen[$1]++ {print $1"="$0;}' "$tmp_all_keys" | sed -E 's/^[^=]+=//' > /tmp/_env_keys_values.$$ || true

# Ensure project.conf has all keys
while IFS= read -r line; do
  key=$(printf '%s' "$line" | sed -E 's/=.*//')
  val=$(printf '%s' "$line" | sed -E 's/^[^=]*=//')
  # If key not present in project.conf, append with val or placeholder
  if ! grep -q "^$key=" "$PROJECT_CONF"; then
    echo "# Added by update_config_examples.sh" >> "$PROJECT_CONF"
    if [ -n "$val" ]; then
      echo "$key=$val" >> "$PROJECT_CONF"
    else
      echo "$key=" >> "$PROJECT_CONF"
    fi
    echo "INFO: added $key to project.conf"
  fi
  # Ensure .env.example has the key
  if ! grep -q "^$key=" "$ENV_EXAMPLE"; then
    echo "# Added by update_config_examples.sh" >> "$ENV_EXAMPLE"
    if [ -n "$val" ]; then
      echo "$key=$val" >> "$ENV_EXAMPLE"
    else
      echo "$key=" >> "$ENV_EXAMPLE"
    fi
    echo "INFO: added $key to .env.example"
  fi
done < /tmp/_env_keys_values.$$

# tidy: ensure files end with newline
sed -i -e '$a\' "$PROJECT_CONF" || true
sed -i -e '$a\' "$ENV_EXAMPLE" || true

exit 0
