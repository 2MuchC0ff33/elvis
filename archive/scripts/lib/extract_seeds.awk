# extract_seeds.awk - extract seed_id and base_url from normalized seeds CSV
# Emits lines of the form: seed_id|base_url
# Usage: awk -f scripts/lib/extract_seeds.awk seeds.normalized.csv

# This parser is robust to commas inside the location field by taking
# the first and last comma as field separators (seed, location, base_url).
NR>1 {
  line = $0
  # find first comma
  first = index(line, ",")
  if (first == 0) next
  seed = substr(line, 1, first-1)
  # find last comma
  last = length(line)
  while (last > 0 && substr(line, last, 1) != ",") last--
  if (last <= first) next
  base = substr(line, last+1)
  # optional: location = substr(line, first+1, last-first-1)
  # clean up seed and base
  gsub(/^\s+|\s+$/, "", seed)
  gsub(/^\s+|\s+$/, "", base)
  # strip surrounding quotes
  if (seed ~ /^".*"$/) { sub(/^"/, "", seed); sub(/"$/, "", seed) }
  if (base ~ /^".*"$/) { sub(/^"/, "", base); sub(/"$/, "", base) }
  if (seed != "" && base != "") print seed "|" base
}
