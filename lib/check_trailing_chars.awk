# check_trailing_chars.awk
# Prints line number and line for company names with trailing control chars or angle brackets
BEGIN { FS = "|" }
{
  c = $1
  gsub(/[[:cntrl:]<>]+$/, "", c)
  if (c != $1) print NR ":" $0
}
