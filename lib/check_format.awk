# check_format.awk
# Prints line number and line for malformed lines (missing company or location)
BEGIN { FS = "|" }
NF < 2 { print NR ":" $0 }
