#!/usr/bin/awk -f
# random_delay.awk - prints a random float between min and max (3 decimal places)
# Usage: awk -v min=1.2 -v max=4.8 -f random_delay.awk
BEGIN {
  if (min == "" || max == "") { print "0.500"; exit }
  srand()
  s = min + rand() * (max - min)
  printf "%.3f", s
}
