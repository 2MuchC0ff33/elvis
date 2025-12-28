# rand_fraction.awk - print a random floating point in [0,1)
# Usage: awk -f scripts/lib/rand_fraction.awk
BEGIN { srand(); printf "%f", rand() }
