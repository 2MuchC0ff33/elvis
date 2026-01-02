#!/usr/bin/awk -f
# backoff.awk - pick backoff seconds from BACKOFF_SEQUENCE based on attempt index
# Usage: echo "$BACKOFF_SEQUENCE" | awk -v i="$attempt" -f backoff.awk
{ n = split($0, a, " "); if (i+0 <= n) print a[i+0]; else print a[n] }
