#!/usr/bin/awk -f
# get_next.awk - Extracts the next page URL using aria-label="Next" or rel="next" or <link rel="next">
# Emits a single line with the (possibly relative) href, if found

BEGIN { IGNORECASE = 1 }
{
  # Try to find a tag with aria-label="Next" and an href attribute on the same line
  if (match($0, /aria-label\s*=\s*"Next"[^>]*href\s*=\s*"[^"]+"/)) {
    s = substr($0, RSTART, RLENGTH)
    if (match(s, /href\s*=\s*"[^"]+"/)) {
      h = substr(s, RSTART, RLENGTH)
      gsub(/href\s*=\s*"/, "", h)
      gsub(/"/, "", h)
      print h
      exit
    }
  }

  # Try link or anchor with rel="next"
  if (match($0, /rel\s*=\s*"next"[^>]*href\s*=\s*"[^"]+"/)) {
    s = substr($0, RSTART, RLENGTH)
    if (match(s, /href\s*=\s*"[^"]+"/)) {
      h = substr(s, RSTART, RLENGTH)
      gsub(/href\s*=\s*"/, "", h)
      gsub(/"/, "", h)
      print h
      exit
    }
  }

  # Also handle <link rel="next" href="..."> in head
  if (match($0, /<link[^>]*rel\s*=\s*"next"[^>]*href\s*=\s*"[^"]+"/)) {
    s = substr($0, RSTART, RLENGTH)
    if (match(s, /href\s*=\s*"[^"]+"/)) {
      h = substr(s, RSTART, RLENGTH)
      gsub(/href\s*=\s*"/, "", h)
      gsub(/"/, "", h)
      print h
      exit
    }
  }
}
