# check_empty_clean.awk
# Prints line number and line for empty company or location after trimming whitespace
BEGIN { FS = "|" }
{
  gsub(/^[ \t]+|[ \t]+$/, "", $1)
  gsub(/^[ \t]+|[ \t]+$/, "", $2)
  if ($1 == "" || $2 == "") print NR ":" $0
}
