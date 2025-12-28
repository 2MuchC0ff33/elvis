# rand_int.awk - print a random integer in [0, MAX)
# Usage: awk -f scripts/lib/rand_int.awk -v MAX=3
BEGIN { if (MAX <= 0) MAX = 1; srand(); print int(rand()*MAX) }
