#!/bin/sh
# scripts/init-help.sh
# Display help and usage for Elvis initialisation scripts

cat <<EOF
Elvis Initialisation Help
========================

Usage:
  . scripts/lib/load_env.sh [ENV_FILE]           # Load .env file (default: .env)
  . scripts/lib/load_config.sh [CONF_FILE]       # Load project.conf (default: project.conf)
  . scripts/lib/load_seek_pagination.sh [INI]    # Load Seek pagination config (default: configs/seek-pagination.ini)
  . scripts/lib/validate_env.sh                  # Validate required environment variables
  . scripts/lib/prepare_log.sh [LOG_FILE]        # Ensure log file and directory exist (default: logs/log.txt)

To run the full init sequence:
  bin/elvis-run init

Each script is modular and can be sourced or executed directly.

Examples:
  . scripts/lib/load_env.sh
  . scripts/lib/load_config.sh
  . scripts/lib/load_seek_pagination.sh
  . scripts/lib/validate_env.sh
  . scripts/lib/prepare_log.sh

EOF
