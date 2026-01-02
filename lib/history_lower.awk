#!/usr/bin/awk -f
# history_lower.awk - print lowercased, trimmed, non-comment input lines
# Skips blank lines and comments starting with '#'
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
{
  s = trim($0)
  if (s == "") next
  if (s ~ /^#/) next
  print tolower(s)
}
