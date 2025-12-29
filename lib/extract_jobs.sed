# extract_jobs.sed - SED-first extraction of company and location fragments
# Emits lines of the form:
# COMPANY:Company Name
# LOCATION:Location Text

# Extract jobCompany anchor contents, then clean entities and trailing junk
/data-automation="jobCompany"/ {
  s/.*data-automation="jobCompany"[^>]*>\([^<]*\).*/\1/
  # decode a few common entities and remove control chars
  s/&amp;/\&/g
  s/&nbsp;/ /g
  s/&#39;/\'/g
  s/&#x27;/\'/g
  s/[[:cntrl:]]//g
  # trim leading/trailing whitespace
  s/^[[:space:]]*//
  s/[[:space:]]*$//
  # remove stray trailing '<' characters that appear in some pages
  s/<*$//
  s/.*/COMPANY:&/p
}

# Extract jobLocation anchor contents and clean
/data-automation="jobLocation"/ {
  s/.*data-automation="jobLocation"[^>]*>\([^<]*\).*/\1/
  s/&amp;/\&/g
  s/&nbsp;/ /g
  s/&#39;/\'/g
  s/&#x27;/\'/g
  s/[[:cntrl:]]//g
  s/^[[:space:]]*//
  s/[[:space:]]*$//
  s/<*$//
  s/.*/LOCATION:&/p
}
