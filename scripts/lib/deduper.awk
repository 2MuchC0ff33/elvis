# deduper.awk - perform case-insensitive dedupe against history
# Usage (called from scripts/deduper.sh):
#   awk -F, -v HISTTMP=/tmp/hist.tmp -v NEWFILE=/tmp/new.tmp -f scripts/lib/deduper.awk

BEGIN {
  # load history file into lowercased keys
  if (HISTTMP != "") {
    while ((getline h < HISTTMP) > 0) {
      gsub(/^ +| +$/,"",h)
      h = tolower(h)
      if (h != "") hist[h]=1
    }
    close(HISTTMP)
  }
}

# process CSV rows (header is expected to be handled by caller)
{
  comp = $1
  gsub(/^ +| +$/,"",comp)
  if (comp == "") next
  l = tolower(comp)
  if (l == "") next
  if (hist[l]) next
  if (seen[l]) next
  seen[l]=1
  print $0
  if (NEWFILE != "") {
    print comp >> NEWFILE
  }
}
