#!/usr/bin/awk -f
# count_rows.awk - print count of rows with at least two pipe-separated fields
BEGIN { FS = "|"; c = 0 }
NF >= 2 { c++ }
END { print c+0 }
