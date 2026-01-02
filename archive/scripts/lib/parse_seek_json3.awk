# parse_seek_json3.awk - more robust line-based extractor for SEEK embedded JSON
# Outputs CSV: company_name,prospect_name,title,phone,email,location,summary,job_id
function q(s) {
  # double internal quotes
  gsub(/"/, "\"\"", s)
  # empty fields should be explicit empty quoted "" for CSV consistency
  if (s == "") return "\"\""
  # if there are commas, quotes or control/newline chars, quote the field
  if (s ~ /[,\"]|[\r\n]|[[:cntrl:]]/) s = "\"" s "\""
  return s
}

function sanitize(s) {
  gsub(/\\u002F/, "/", s)
  gsub(/\\\//, "/", s)
  # remove escaped newlines and literal newlines/carriage returns
  gsub(/\\n|\\r/, " ", s)
  gsub(/\n|\r/, " ", s)
  gsub(/\\t/, " ", s)
  # remove control characters (safeguard against embedded control/newline bytes)
  gsub(/[[:cntrl:]]+/, " ", s)
  # decode simple HTML entities
  gsub(/&amp;/, "&", s)
  # collapse whitespace
  gsub(/[[:space:]]+/, " ", s)
  sub(/^[[:space:]]+/, "", s)
  sub(/[[:space:]]+$/, "", s)
  return s
}

BEGIN { OFS = "," }
{
  if (!found) {
    if (index($0, "\"jobs\"") > 0) {
      found=1
      # take from the first '[' on this line
      p = index($0, "[")
      if (p > 0) buf = substr($0, p)
      else buf = ""
      # count brackets
      openb = 0
      closeb = 0
      for (j = 1; j <= length(buf); j++) { ch = substr(buf,j,1); if (ch == "[") openb++; else if (ch == "]") closeb++ }
    }
  } else {
    buf = buf "\n" $0
    for (j = 1; j <= length($0); j++) { ch = substr($0,j,1); if (ch == "[") openb++; else if (ch == "]") closeb++ }
  }
  if (found && openb > 0 && openb == closeb) {
    # buf now contains the jobs array; split objects by '},{' into object chunks (avoid splitting on other newlines)
    gsub(/},[[:space:]]*{/, "}\n{", buf)
    mcount = split(buf, parts, "}\n{")
    for (pi = 1; pi <= mcount; pi++) {
      line = parts[pi]
      # restore braces if they were stripped by split
      if (line !~ /^{/) line = "{" line
      if (line !~ /}$/) line = line "}"
      # trim surrounding array markers/commas
      gsub(/^[[:space:]]*\[+/, "", line)
      gsub(/\]+[[:space:]]*$/, "", line)
      gsub(/^,|,$/, "", line)
      if (line !~ /\{/) continue
      job_id=""; company=""; title=""; location=""; summary=""
      # pick id from the first ~300 chars of the object to avoid nested ids (locations/employer ids)
      head = substr(line, 1, 300)
      if (match(head, /"id"[[:space:]]*:[[:space:]]*"([0-9]+)"/, m)) job_id = m[1]
      if (match(line, /"companyName"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) company = m[1]
      else if (match(line, /"employer"[[:space:]]*:[[:space:]]*\{[^}]*"name"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) company = m[1]
      else if (match(line, /"advertiser"[[:space:]]*:[[:space:]]*\{[^}]*"description"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) company = m[1]
      if (match(line, /"title"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) title = m[1]
      if (match(line, /"teaser"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) summary = m[1]
      if (match(line, /"locations"[[:space:]]*:[[:space:]]*\[[^\]]*\{[^}]*"label"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) location = m[1]
      if (company == "" && match(line, /"subClassification"[[:space:]]*:[[:space:]]*\{[^}]*"description"[[:space:]]*:[[:space:]]*"([^"]+)"/, m)) company = "subClassification: " m[1]
      # sanitize extracted strings
      company = sanitize(company)
      title = sanitize(title)
      location = sanitize(location)
      summary = sanitize(summary)
      # emit only company and location (CSV) and skip subClassification-only companies
      if (job_id != "") {
        if (company ~ /^subClassification:/) {
          # skip noisy classification rows
          next
        }
        out = q(company) OFS q(location)
        # final safeguard: remove any control chars/newlines and collapse whitespace
        gsub(/[[:cntrl:]]+/, " ", out)
        gsub(/[[:space:]]+/, " ", out)
        sub(/^[[:space:]]+/, "", out)
        sub(/[[:space:]]+$/, "", out)
        print out
      }
    }
    exit
  }
}
