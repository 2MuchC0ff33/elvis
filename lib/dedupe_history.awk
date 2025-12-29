#!/usr/bin/awk -f
# dedupe_history.awk - deduplicate history file preserving first case-preserving occurrence
# - Trims whitespace, ignores blank lines, preserves comment lines starting with '#'
# - Preserves the first (case-preserving) occurrence of each company name
# Usage: awk -f dedupe_history.awk history.txt
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
{
  # Preserve comment lines verbatim
  if ($0 ~ /^#/) { print $0; next }
  line = trim($0)
  if (line == "") next
  key = tolower(line)
  if (!seen[key]++) print line
}
