# extract_seeds.awk - extract seed_id and base_url from normalized seeds CSV
# Emits lines of the form: seed_id|base_url
# Usage: awk -F, -f scripts/lib/extract_seeds.awk seeds.normalized.csv

BEGIN { FS = "," }
NR>1 {
  seed = $1; base = $3
  gsub(/^"|"$/, "", seed)
  gsub(/^"|"$/, "", base)
  if (seed != "" && base != "") print seed "|" base
}
