# pick_random.awk - print a random non-empty line from file(s)
# Usage: awk -f scripts/lib/pick_random.awk file.txt
BEGIN { srand(); count=0 }
{ lines[++count]=$0 }
END {
  if (count>0) print lines[int(rand()*count)+1]
}
