# uniq_count.awk
# Prints lowercased company names for uniqueness check
BEGIN { FS = "|" }
{ print tolower($1) }
