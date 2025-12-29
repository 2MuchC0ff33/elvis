#!/usr/bin/awk -f
# loop.awk - AWK-first HTML parser that extracts Company and Location from Seek-like pages
# Usage: loop.awk <html-file>
# Emits lines: Company Name | Location
# Approach:
# - Split input on <article ... data-automation="normalJob" ...> ... </article>
# - Within each article block, locate <a data-automation="jobCompany">TEXT</a> and <a data-automation="jobLocation">TEXT</a>
# - Normalize whitespace and decode common HTML entities minimally

BEGIN {
  IGNORECASE = 1
  RS = "<article"
  FS = "\n"
  OFS = " | "
}

# Minimal HTML entity decoding for &amp; &lt; &gt; &quot; &apos;
function decode(s) {
  gsub(/&amp;/, "&", s)
  gsub(/&lt;/, "<", s)
  gsub(/&gt;/, ">", s)
  gsub(/&quot;/, "\"", s)
  gsub(/&apos;/, "'", s)
  return s
}

# Trim function
function trim(s) { gsub(/^\s+|\s+$/, "", s); return s }

# Process each record (each article candidate)
NR > 1 {
  block = $0
  # Only consider blocks that are normalJob
  if (block !~ /data-automation\s*=\s*"normalJob"/) next

  comp = ""
  loc = ""

  # Extract company anchor content
  if (match(block, /<a[^>]*data-automation\s*=\s*"jobCompany"[^>]*>[^<]*</)) {
    s = substr(block, RSTART, RLENGTH)
    gsub(/<[^>]*>/, "", s)
    comp = trim(decode(s))
  } else if (match(block, /data-automation\s*=\s*"jobCompany"[^>]*>[^<]*</)) {
    s = substr(block, RSTART, RLENGTH)
    gsub(/.*>/, "", s)
    gsub(/<.*/, "", s)
    comp = trim(decode(s))
  }

  # Extract location anchor content
  if (match(block, /<a[^>]*data-automation\s*=\s*"jobLocation"[^>]*>[^<]*</)) {
    s = substr(block, RSTART, RLENGTH)
    gsub(/<[^>]*>/, "", s)
    loc = trim(decode(s))
  } else if (match(block, /data-automation\s*=\s*"jobLocation"[^>]*>[^<]*</)) {
    s = substr(block, RSTART, RLENGTH)
    gsub(/.*>/, "", s)
    gsub(/<.*/, "", s)
    loc = trim(decode(s))
  }

  if (comp != "" && loc != "") {
    print comp OFS loc
  }
}
