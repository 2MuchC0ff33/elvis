#!/usr/bin/awk -F'|' -f
# filter_new.awk - Given history (lc company per line) then candidate rows (lc|Company|Location)
# emits rows not present in history and de-duplicates by lc-company while preserving first occurrence
# Treat the first ARGV as history regardless of file being empty
FILENAME == ARGV[1] { h[$1] = 1; next }
{ if (!h[$1] && !seen[$1]++) print $0 }
