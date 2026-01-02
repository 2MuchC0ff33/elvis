#!/bin/sh
# tests/unit_parse_html_json.sh
# Tests parse.sh with HTML job cards and embedded JSON

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

tmp="$(mktemp -d "${REPO_ROOT}/tmp/parsetest.XXXX" 2>/dev/null || mktemp -d -t parsetest)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/mock.htmls" <<HTML
<article data-automation="normalJob" data-job-id="job-123">
  <a data-automation="jobCompany">Example Pty Ltd</a>
  <a data-automation="jobTitle">Manager</a>
  <a data-automation="jobLocation">Perth, WA</a>
  <span data-automation="jobShortDescription">Summary text for example</span>
</article>
HTML

sh "$REPO_ROOT/scripts/parse.sh" "$tmp/mock.htmls" --out "$tmp/out.csv" || { echo "FAIL: parse.sh HTML failed" >&2; exit 1; }
grep -q 'Example Pty Ltd' "$tmp/out.csv" || { echo "FAIL: parse output missing company" >&2; exit 1; }

# JSON embedded extractor
cat > "$tmp/mock_json.html" <<HTML
<html><head><script>window.SEEK_REDUX_DATA = {"jobs":[{"id":"111","companyName":"JSON Co","title":"Dev","locations":[{"label":"Brisbane, QLD"}]},{"id":"222","companyName":"JSON Two","title":"QA","locations":[{"label":"Hobart, TAS"}]}]};</script></head><body></body></html>
HTML
sh "$REPO_ROOT/scripts/parse.sh" "$tmp/mock_json.html" --out "$tmp/out_json.csv" || { echo "FAIL: parse.sh JSON failed" >&2; exit 1; }
lines=$(wc -l < "$tmp/out_json.csv" | tr -d ' ')
if [ "$lines" -ne 3 ]; then
  echo "FAIL: parse JSON expected 3 lines (header+2), got $lines" >&2
  exit 1
fi

# sanity check quotes balanced for data rows
awk 'NR>1{count=gsub(/"/,"&"); if (count%2!=0) { print "BADLINE:" NR; exit 1 }}' "$tmp/out_json.csv" || { echo "FAIL: parse JSON produced unmatched quotes" >&2; exit 1; }

echo "PASS: unit_parse_html_json"
exit 0
