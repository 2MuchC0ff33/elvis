#!/usr/bin/awk -f
# get_origin.awk - print scheme://host portion of a URL
{ if (match($0, /https?:\/\/[^\/]*/)) print substr($0, RSTART, RLENGTH) }
