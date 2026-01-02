#!/usr/bin/awk -f
# scripts/lib/normalize.awk
# Normalise CSV by taking the first and last comma as separators (seed, location, base_url)
# This keeps locations intact even if they contain commas (e.g., "Perth, WA").
# Trim whitespace and remove BOM/CR characters.

BEGIN { OFS = "," }
{
  line = $0
  gsub(/\r/, "", line)
  gsub(/^\xEF\xBB\xBF/, "", line)
  if (length(line) == 0) next

  # find first comma
  first = index(line, ",")
  if (first == 0) next
  # find last comma
  last = length(line)
  while (last > 0 && substr(line, last, 1) != ",") last--
  if (last <= first) next

  seed = substr(line, 1, first-1)
  location = substr(line, first+1, last-first-1)
  base = substr(line, last+1)

  # trim spaces
  gsub(/^\s+|\s+$/, "", seed)
  gsub(/^\s+|\s+$/, "", location)
  gsub(/^\s+|\s+$/, "", base)

  # remove surrounding quotes if present
  if (seed ~ /^".*"$/) { sub(/^"/, "", seed); sub(/"$/, "", seed) }
  if (location ~ /^".*"$/) { sub(/^"/, "", location); sub(/"$/, "", location) }
  if (base ~ /^".*"$/) { sub(/^"/, "", base); sub(/"$/, "", base) }

  # If location contains a comma, quote it for valid CSV output
  if (location ~ /,/) {
    # escape any existing double quotes and quote the field
    gsub(/"/, """", location)
    location = "\"" location "\""
  }

  print seed, location, base
}
