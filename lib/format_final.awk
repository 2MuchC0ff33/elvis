#!/usr/bin/awk -F'|' -f
# format_final.awk - Format candidate rows into 'Company | Location' and dedupe by lc-company
!seen[$1]++ { print $2 " | " $3 }
