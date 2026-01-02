#!/bin/sh
# usage.sh - Usage helper
cat <<EOF
Usage: $0 [--append-history]
  --append-history    Append newly-found companies to $HISTORY_FILE
EOF
exit 1
