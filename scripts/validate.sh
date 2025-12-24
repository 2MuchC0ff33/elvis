#!/bin/sh
# scripts/validate.sh
# Validate and normalise a CSV of records.
# Usage: validate.sh input.csv --out validated.csv

set -eu

INPUT="${1:-}"
OUT=""

EMAIL_REGEX='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}'

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "Usage: $0 <input.csv> --out <validated.csv>" >&2
  exit 2
fi

# parse --out
shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out)
      shift
      OUT="$1"
      ;;
    *)
      ;;
  esac
  shift || true
done

if [ -z "$OUT" ]; then
  echo "ERROR: --out <file> required" >&2
  exit 2
fi

# Ensure header contains required fields
header=$(head -n1 "$INPUT" | tr -d '\r')
# Check required columns exist (POSIX sh compatible)
for col in company_name prospect_name title phone email location; do
  echo "$header" | grep -q "$col" || { echo "ERROR: missing column: $col" >&2; exit 2; }
done

# Process rows: normalise phone, validate fields, emit to OUT only valid rows
awk -v email_re="$EMAIL_REGEX" 'BEGIN{FS=","; OFS=","}
NR==1{print $0; next}
{
  # simple trimming
  for(i=1;i<=NF;i++){gsub(/^ +| +$/,"",$i)}
  company=$1; phone=$4; email=$5
  # reconstruct location (fields 6..NF) into a single field
  location=""
  if (NF>=6) {
    location=$6
    for(j=7;j<=NF;j++){ location = location "," $j }
  }
  # phone normalisation: replace +61 prefix with 0 and remove non-digits
  gsub(/\+61/,"0",phone)
  gsub(/[^0-9]/,"",phone)
  # email validation
  valid_email=1
  if (length(email)>0) {
    if (email !~ ("^" email_re "$")) valid_email=0
  }
  # company required
  if (company=="" ){
    print "INVALID",NR, "missing company" > "/dev/stderr"; next
  }
  # contact requirement: at least one contact (phone or email)
  if (length(phone)==0 && length(email)==0){ print "INVALID",NR, "missing contact" > "/dev/stderr"; next }
  if (length(email)>0 && valid_email==0){ print "INVALID",NR, "invalid email: " email > "/dev/stderr"; next }
  # Replace fields with normalized values
  $4=phone
  $5=email
  $6=location
  print $0
}' "$INPUT" > "$OUT" || {
  echo "ERROR: validation failed; see stderr for details" >&2
  exit 3
}

echo "Validation succeeded: output -> $OUT"
exit 0
