# validator.awk - validate and normalise CSV records
# Expects: CSV with header containing company_name,prospect_name,title,phone,email,location
# Usage: awk -v email_re="<regex>" -f scripts/lib/validator.awk input.csv > out.csv

BEGIN {
  FS = ","
  OFS = ","
}

NR==1 {
  print $0
  next
}

{
  # trim all fields
  for (i=1; i<=NF; i++) { gsub(/^ +| +$/, "", $i) }
  company = $1
  phone = $4
  email = $5
  # reconstruct location fields (6..NF)
  location = ""
  if (NF >= 6) {
    location = $6
    for (j=7; j<=NF; j++) location = location "," $j
  }
  # phone normalisation: replace +61 with 0 and strip non-digits
  gsub(/\+61/, "0", phone)
  gsub(/[^0-9]/, "", phone)
  # validate email if present
  valid_email = 1
  if (length(email) > 0) {
    # build anchored regex using email_re variable passed from shell
    if (email !~ ("^" email_re "$")) valid_email = 0
  }
  # required: company
  if (company == "") {
    print "INVALID", NR, "missing company" > "/dev/stderr"
    next
  }
  # require at least one contact
  if (length(phone) == 0 && length(email) == 0) {
    print "INVALID", NR, "missing contact" > "/dev/stderr"
    next
  }
  if (length(email) > 0 && valid_email == 0) {
    print "INVALID", NR, "invalid email: " email > "/dev/stderr"
    next
  }
  # set normalised fields and emit
  $4 = phone
  $5 = email
  $6 = location
  print $0
}
