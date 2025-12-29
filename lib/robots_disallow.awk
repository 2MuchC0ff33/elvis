#!/usr/bin/awk -f
# robots_disallow.awk - print DISALLOWED if robots.txt contains a User-agent: * followed by Disallow: / on same UA block
# Usage: awk -f robots_disallow.awk robots.txt
BEGIN { ua = 0 }
{
  l = tolower($0)
  if (l ~ /^user-agent:/) {
    ua = (l ~ /user-agent:\s*\*/)
  }
  if (ua && $0 ~ /^Disallow:/) {
    if ($0 ~ /Disallow:\s*\/\s*$/) { print "DISALLOWED"; exit 0 }
  }
}
