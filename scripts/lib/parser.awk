# parser.awk - parse saved HTML chunks into CSV rows
# Usage: awk -f scripts/lib/parser.awk input.htmls
# Emits CSV with fields: company_name,prospect_name,title,phone,email,location,summary,job_id

BEGIN {
  RS = "\n\n"  # chunks separated by blank lines
  FS = "\n"
  OFS = ","
}

{
  # skip chunks without a normalJob marker
  if ($0 !~ /normalJob/) next
  company=""; title=""; location=""; summary=""; jobid=""

  # extract job id from the entire chunk
  if (match($0, /data-job-id="([^"]+)"/, m)) jobid = m[1]

  for (i=1; i<=NF; i++) {
    line = $i
    if (line ~ /data-automation="jobCompany"/) {
      if (match(line, />([^<]+)</, m)) company = m[1]
      else { sub(/.*data-automation="jobCompany"[^>]*>/, "", line); sub(/<.*$/, "", line); company = line }
    }
    if (line ~ /data-automation="jobTitle"/) {
      if (match(line, />([^<]+)</, m)) title = m[1]
      else { sub(/.*data-automation="jobTitle"[^>]*>/, "", line); sub(/<.*$/, "", line); title = line }
    }
    if (line ~ /data-automation="jobLocation"/) {
      if (match(line, />([^<]+)</, m)) location = m[1]
      else { sub(/.*data-automation="jobLocation"[^>]*>/, "", line); sub(/<.*$/, "", line); location = line }
    }
    if (line ~ /data-automation="jobShortDescription"/) {
      if (match(line, />([^<]+)</, m)) summary = m[1]
      else { sub(/.*data-automation="jobShortDescription"[^>]*>/, "", line); sub(/<.*$/, "", line); summary = line }
    }
  }

  if (company != "") {
    gsub(/^ +| +$/, "", company)
    gsub(/^ +| +$/, "", title)
    gsub(/^ +| +$/, "", location)
    gsub(/^ +| +$/, "", summary)
    gsub(/^ +| +$/, "", jobid)
    # print company_name, prospect_name(empty), title, phone(empty), email(empty), location, summary, jobid
    print company, "", title, "", "", location, summary, jobid
  }
}
