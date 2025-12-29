#!/usr/bin/awk -f
# normalize_relpath.awk - ensure string starts with a single leading slash
{ s = $0; gsub(/^\/*/, "", s); print "/" s }
