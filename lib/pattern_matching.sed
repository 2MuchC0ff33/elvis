# pattern_matching.sed - sed-based fallback extractor
# Reads HTML from stdin or file and emits lines: Company Name | Location
# Uses stable automation attributes: data-automation="jobCompany" and data-automation="jobLocation"

# Strategy:
# - For each article block, extract company and location anchor inner text
# - We operate line-by-line and buffer a block between <article and </article>

: a
/<article/ { :b; H; n; /<\/article>/!b; x
# extract company
s/\n/ /g
s/.*data-automation=\"jobCompany\"[^>]*>\([^<]*\).*/\1/; h
x
s/.*data-automation=\"jobLocation\"[^>]*>\([^<]*\).*/\1/; H
x
s/\n/ | /g
p
x
s/.*//
}
n
b a
