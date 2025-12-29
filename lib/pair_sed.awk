#!/usr/bin/awk -F: -f
# pair_sed.awk - pairs COMPANY: and LOCATION: lines into 'Company | Location'
# Maintains last seen company and pairs with next seen location
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
{
  tag = $1
  sub(/^[^:]*:/, "", $0)
  val = $0
  # remove control characters and decode common HTML entities
  gsub(/[[:cntrl:]]/, "", val)
  gsub(/&amp;/, "&", val)
  gsub(/&nbsp;/, " ", val)
  gsub(/&#39;|&#x27;/, "'", val)
  val = trim(val)
  if (tag == "COMPANY") { comp = val }
  else if (tag == "LOCATION") { if (comp != "") { print comp " | " val; comp = "" } }
}
