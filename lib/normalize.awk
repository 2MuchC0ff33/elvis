#!/usr/bin/awk -F'|' -f
# normalize.awk - Normalize and validate incoming rows
# Input lines: Company|Location  or arbitrary
# Output: lc_company|Company|Location
# Prints INVALID <line> <reason> to stderr for missing values

function trim(s) { gsub(/^\s+|\s+$/, "", s); return s }
{
  # initial trim
  company = trim($1)
  location = trim($2)

  # decode common HTML entities (SED-first tries may not catch them all)
  gsub(/&amp;/, "&", company)
  gsub(/&nbsp;/, " ", company)
  gsub(/&#39;|&#x27;/, "'", company)
  gsub(/&amp;/, "&", location)
  gsub(/&nbsp;/, " ", location)
  gsub(/&#39;|&#x27;/, "'", location)

  # remove stray trailing angle brackets, control or replacement characters introduced by extraction
  gsub(/[[:cntrl:]<>]+$/, "", company)
  gsub(/[[:cntrl:]<>]+$/, "", location)

  # final trim after cleaning
  company = trim(company)
  location = trim(location)

  if (company == "" || location == "") {
    reason = (company == "" ? "missing_company" : "missing_location")
    printf "INVALID %s %s\n", $0, reason > "/dev/stderr"
    next
  }

  lc = tolower(company)
  print lc "|" company "|" location
}
