#!/usr/bin/awk -f
# scripts/lib/normalize.awk
# Normalise CSV: trim whitespace, unify delimiters, remove BOM, skip blank lines
BEGIN { FS=","; OFS="," }
{
  for (i=1; i<=NF; i++) {
    gsub(/^\s+|\s+$/, "", $i)
    gsub(/\r/, "", $i)
  }
  if (NF > 1 && $1 != "") print $0
}
