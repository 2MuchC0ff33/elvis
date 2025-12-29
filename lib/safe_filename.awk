#!/usr/bin/awk -f
# safe_filename.awk - convert URL to safe filename: replace non-alnum . _ - with _ and trim to 100 chars
{ s = $0; gsub(/[^A-Za-z0-9._-]/, "_", s); print substr(s,1,100) }
