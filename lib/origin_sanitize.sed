# origin_sanitize.sed - produce filesystem-safe origin string from a URL origin
s/[^A-Za-z0-9]/_/g
p
