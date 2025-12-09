# Comprehensive Project Plan: Australian Sales Lead Call List Scraper

## 1. Project Objective

Produce a daily call list of at least 25 unique Australian companies—each record to include the prospect’s name, position, contact details (mobile and/or email), and business location. This data is for sales lead generation and business development. **Company names must always be unique** across days, using company history for deduplication.

---

## 2. Data Requirements

**Required data fields:**
- Company Name (must be unique, case-insensitive)
- Lead/Prospect Name
- Position/Title
- Location (state/region preferred)
- Mobile phone (normalised, digits only, e.g. 0412345678)
- Email (any domain)
- *Note*: Skip records if all contact details are missing.

---

## 3. Data Sources

- **Primary:** [Seek Australia](https://www.seek.com.au/) — job ads for company/employer field
- **Supplementary:** [DuckDuckGo Lite](https://lite.duckduckgo.com/lite) (manual Google-dork queries)
- **Supplementary:** [Google](https://www.google.com/) (manual Google-dork queries, .com.au only)
- Only scrape public web pages; **never** scrape private profiles (LinkedIn, Facebook etc.) or any site that disallows scraping under robots.txt or terms of service.

---

## 4. Geographic, Language & Domain Limitation

- Australian businesses only (.com.au websites/domains)
- All content in English (preferably en_AU.UTF-8)
- Seed job searches to cover all major Australian capitals and regions (see Appendix)

---

## 5. Success Criteria, KPIs & Acceptance

- **Daily target:** At least 25 unique companies (company names case-insensitive, no repeats checked against company history)
- Each row must have at least one valid contact detail (phone or email)
- Missing/incomplete company names: skip
- No duplicate companies across different days (per historical exclusion)
- If fewer than 25 leads are found, save the CSV regardless and record a warning in the logs
- Project “passes” if daily lists have valid contacts and no duplicate companies from the past

---

## 6. Volume, Frequency & Retention

- Minimum 25 leads per run
- Data refreshed daily
- Each new call list overwrites the previous day’s file (‘calllist_YYYY-MM-DD.csv’), history file is permanent (`companies_history.txt`)

---

## 7. Storage, Output Format & Encoding

- Output: UTF-8, CSV — one line per company/lead
- Filename: `calllist_YYYY-MM-DD.csv` (overwrites daily)
- History file: `companies_history.txt` (one company per line, maintained manually)
- Do not include source URLs, timestamps, or data lineage in the CSV
- **CSV Example:**
  ```
  company_name,prospect_name,title,phone,email,location
  XYZ Pty Ltd,John Smith,Managing Director,0412345678,email@xyz.com.au,Perth, WA
  ABC Ltd,Mary Jane,Owner,0498765432,test@abc.com.au,Darwin, NT
  ```

---

## 8. Tools & Tech Stack

**Essential**
- Bourne Shell for scripting
- Toybox for command line utilities
- RCS for manual version control

**Non-Essential**
- mandoc (UNIX docs/manpages)
- edbrowse an ed-alike webbrowser
- scron is a simple crond

**Cross-platform**: Linux, BSD, macOS, and Windows.

---

## 9. Scraping Method & Strategy

- Use `grep`, `sed`, `awk`, `http` from Toybox for HTML
- Shell scripts to control fetch/parse/validate/deduplicate/report
- Helper binaries are allowed

When building your scraping run, start with a diverse collection of filtered listing URLs (see Filtered Seeds below) to cover job types, regions, work styles, and more—with no headless browser or form simulation required.

- **Google-dorking (manual):** CLI scripts generate Google or DuckDuckGo queries, which are opened in lynx), never automatically scraped
  - Limit domains to .com.au
  - Use flexible dorks (e.g. name/company/job/location/contact) for best results
  - Example dork: `"Jane Smith" "email" OR "phone" OR "mobile" site:.com.au`
- Appendix includes dork and seed templates

---

## 10. Data Validation, Deduplication & Cleaning

- Company name deduplication: case-insensitive matching only (no normalisation)
- Company + different location = considered duplicate for exclusion
- Do not normalise suffixes/whitespace/punctuation
- Skip rows missing company name
- Require at least one valid contact (phone or email)
- Email validation: `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`
- Phone validation: digits only, convert +61 to 0-prefix

---

## 11. Pacing, Anti-Bot & Reliability Policy

To minimize disruptions and respect rate-limit expectations:

- **Randomized delays:** Sleep a random amount between requests (e.g., 1.2–4.8 seconds) to avoid a machine-like cadence.
- **Exponential backoff & retries:**
  - Up to 3 retries per URL
  - Backoff schedule: 5s → 20s → 60s
  - Stop after the 3rd failure; log the error and move on.
- **User-Agent rotation:** Cycle a vetted pool of UA strings; avoid suspicious or outdated UAs.
- Do not use proxies or offshore scraping APIs
- **CAPTCHA detection:** If CAPTCHA text or known markers appear, log the event, skip this route, and **do not** attempt automated solving.
- **Timeouts:** Set connection and read timeouts (e.g., 10–15 seconds) to avoid hanging.
- **Respect robots.txt and ToS:** Only operate on listing pages and public endpoints suitable for automated access.

> **Outcome:** A conservative, respectful scraper that avoids throttling and reduces maintenance due to anti-bot defenses.

**Shell backoff snippet (example):**

```sh
fetch_with_backoff() {
  url="$1"
  for attempt in 1 2 3; do
    if html="$(curl -fsSL --max-time 15 "$url")"; then
      printf '%s' "$html"
      return 0
    fi
    case "$attempt" in
      1) sleep 5  ;;
      2) sleep 20 ;;
      3) sleep 60 ;;
    esac
  done
  return 1
}
```

---

## 12. Error Handling, Logging & Monitoring

- Script logs all runs to `log.txt`
    - Include: timestamp, queried URLs, search terms
    - Number of unique records found
    - Errors/warnings (CAPTCHA, timeout etc.)
    - Warn if fallback (textual) “Next” detection was triggered or if duplicate pages were detected during pagination.
    - Add record-level debugging if ‘verbose’ enabled
    - Retain/rotate logs weekly (policy TBC)
- No external monitoring or alerting required

---

## 13. Security, Privacy & Compliance

- Only collect public information — no restricted/private data
- Do not scrape any site or page excluded by robots.txt or ToS
- Strictly observe Australian privacy law/ethical norms
- Admin can manually remove any person/company details from history if requested

---

## 14. Retention & Admin Control

- Daily call list is always overwritten
- Company history file (`companies_history.txt`) always retained and added via admin/manual only
- Manual RCS commit for company list/historic file

---

## 15. Scheduling & Automation

- Scraper script is triggered manually for now
- Scron scheduling (Unix/BSD/macOS/Windows) after MVP is accepted

---

## 16. Project Acceptance Criteria

- At least 25 unique companies per CSV file per day (case-insensitive, not in history)
- Each row contains at least one valid contact (phone/email)
- No duplicates across daily runs
- Less than 25 allowed as partial, write a warning to logs
- Output format, scripts, logs match this project scope and description

---

## 17. MVP / First Steps

- Write initial Shell scripts and helpers
- Create `seeds.txt` (Seek listing URLs + dork templates)
- Create and manage `companies_history.txt` (admin initiates)
- Document everything, structure logs for future audit

---

# Seek.com.au — Route-aware pagination (concise)

Overview
- Seek uses two distinct pagination models depending on the URL route. Detect the model for each seed URL and apply the corresponding pagination logic.
- Always stop when the page’s “Next” control disappears from the returned HTML; never assume a fixed page count.

## Pagination models

### Model A — Generic search (URLs containing `/jobs?` or `/jobs&`)
- Mechanism: `start=OFFSET` query parameter, OFFSET increases by 22:
  - Page 1 → `start=0`
  - Page 2 → `start=22`
  - Page k → `start=22*(k-1)`
- Stop condition: the Next control (e.g., `<span data-automation="page-next">Next</span>`) is absent from the returned HTML.
- Rationale: server-side offset pagination for generic searches.

### Model B — Category / region routes (paths containing `-jobs/in-`)
- Mechanism: `?page=N` (1-based). Page 1 usually has no `?page` parameter:
  - Page 1 → (no `?page`)
  - Page 2 → `?page=2`
  - Page k → `?page=k`
- Stop condition: the Next link is absent from the pagination component.
- Rationale: page-numbered UX and bookmarkable segments.

## Route model detection (POSIX shell)
- Detect Model A if URL contains `/jobs?` or `/jobs&`.
- Detect Model B if URL path matches `-jobs/in-`.
- Default to Model A when unsure.

Shell function (returns `PAG_START` or `PAG_PAGE`)
```sh
pick_pagination() {
    url="$1"
    if echo "$url" | grep -q '/jobs[?&]'; then
        echo "PAG_START"
    elif echo "$url" | grep -q '-jobs/in-'; then
        echo "PAG_PAGE"
    else
        echo "PAG_START"
    fi
}
```

## Combined POSIX shell example (toybox http)
- Uses toybox’s `http` utility (`http -f -s`) for fetches.
- Uses presence/absence of `data-automation="page-next"` in HTML as the stop check.
- Replace `parse_listings` with your stable-selector parsing (prefer `article` roots, `data-*` attributes, anchor text).

```sh
#!/bin/sh
initial_url="https://www.seek.com.au/jobs?keywords=admin&where=Perth%2C+WA"
model=$(pick_pagination "$initial_url")

case "$model" in
  PAG_START)
    offset=0
    while :; do
      url="${initial_url}&start=$offset"
      html=$(http -f -s "$url") || break
      # parse_listings "$html"   # implement stable-selector parsing separately
      if ! echo "$html" | grep -q 'data-automation="page-next"'; then
        break
      fi
      offset=$((offset + 22))
      sleep 1
    done
    ;;
  PAG_PAGE)
    page=1
    base_url="$initial_url"
    while :; do
      if [ "$page" -gt 1 ]; then
        url="${base_url}?page=$page"
      else
        url="$base_url"
      fi
      html=$(http -f -s "$url") || break
      # parse_listings "$html"   # implement stable-selector parsing separately
      if ! echo "$html" | grep -q 'data-automation="page-next"'; then
        break
      fi
      page=$((page + 1))
      sleep 1
    done
    ;;
esac
```

## Notes & best practices
- Detect the model per seed URL — misdetection can skip pages or cause infinite loops.
- Use the presence/absence of the “Next” control in the returned HTML as the authoritative stop condition.
- Prefer stable selectors and automation attributes when parsing listing content (`<article>` roots, `data-automation` attributes, `data-*` ids, and anchor text). Avoid brittle CSS class names.
- Throttle requests and randomize small sleeps to reduce load and avoid triggering rate limits.

- **Job listing/card structure:**
### Selector Discipline (stable attributes vs brittle CSS)

Seek’s listing markup provides automation-friendly signals. Prefer these over CSS class names:

- **Job card root**: the `<article>` representing a “normal” job result.
- **Job title**: the anchor text for the title.
- **Company name**: the anchor text for employer.
- **Location**: the anchor text for location.
- **Short description**: the inline summary text.
- **Job identifier**: a `data-*` attribute unique to the listing.

#### Why avoid CSS class names?
Class names on modern sites change frequently in A/B tests and refactors. Automation-oriented attributes and structural tags are more stable and intentionally readable by scripts.

#### Parsing guidelines
- Anchor your extraction to automation markers first; if absent, fall back to surrounding semantic tags and textual anchors.
- Never rely on inner CSS names like `.style__Card__1a2b` (those are brittle).
- Handle minor whitespace/HTML entity variations safely (normalize text).

**Outcome:** More resilient scrapers that survive minor refactors without constant maintenance.
  - Each job is: `<article data-automation="normalJob">...</article>`
    - **Title:** `<a data-automation="jobTitle">`
    - **Company:** `<a data-automation="jobCompany">`
    - **Location:** `<a data-automation="jobLocation">`
    - **Short description:** `<span data-automation="jobShortDescription">`
    - **Job ID:** `data-job-id` attribute
  - Only fields visible here can be automatically gathered.

- **Contact info (phone/email):**
  - **Not present** in Seek job cards — must be found by operator using dorks, company sites and public resources.

- **Search fields:**
  - **Keywords**: `<input id="keywords-input" name="keywords" type="text" ...>`
  - **Location**: `<input id="SearchBar__Where" name="where" type="search" ...>`
 
**Shell extraction outline:**

```sh
#!/bin/sh

# Function to parse job listings from HTML using stable data-automation attributes
# Extracts title, company, location, summary, and job_id from each job card
parse_listings() {
    html="$1"
    echo "$html" | awk -v RS='</article>' '
    /<article[^>]*data-automation="normalJob"/ {
        title = ""
        company = ""
        location = ""
        summary = ""
        job_id = ""
        
        # Extract title
        if (match($0, /data-automation="jobTitle"[^>]*>([^<]*)</, arr)) {
            title = arr[1]
        }
        
        # Extract company
        if (match($0, /data-automation="jobCompany"[^>]*>([^<]*)</, arr)) {
            company = arr[1]
        }
        
        # Extract location
        if (match($0, /data-automation="jobLocation"[^>]*>([^<]*)</, arr)) {
            location = arr[1]
        }
        
        # Extract summary
        if (match($0, /data-automation="jobShortDescription"[^>]*>([^<]*)</, arr)) {
            summary = arr[1]
        }
        
        # Extract job_id
        if (match($0, /data-job-id="([^"]*)"/, arr)) {
            job_id = arr[1]
        }
        
        # Print extracted data if at least title is present
        if (title != "") {
            print "Title: " title
            print "Company: " company
            print "Location: " location
            print "Summary: " summary
            print "Job ID: " job_id
            print "---"
        }
    }
    '
}
```

### Seek.com.au JavaScript Behaviour & Scraping Approach (Update as of December 2025)

Although Seek.com.au’s search UI uses dynamic JavaScript features (type-ahead suggestions, toggle controls, etc.), **the actual job listing pages are server-rendered and respond to standard URL query parameters** such as `keywords`, `where`, and `start`. This makes scraping feasible using static tools.

**Key points:**
- **No headless browser required:**  
  Listing pages can be fetched by constructing query URLs and using static HTTP requests (e.g. Toybox’s `http`). All job data and pagination elements appear in the HTML and can be parsed with shell tools (`grep`, `awk`, `sed`).
- Dynamic UI features (like suggestion dropdowns) are cosmetic and do not affect the underlying listing pages or endpoints.
- **Stable HTML selectors:**  
  Listing markup and pagination controls use stable `data-automation` attributes suitable for parsing and extraction.
- No official API or browser automation is necessary, as long as Seek continues to render results on the server-side.
- **If Seek ever transitions to client-only rendering (e.g. React hydration without SSR),** switch to an ed-alike browser (`edbrowse`) or suitable alternative for interactive/manual extraction.
- **Best practice:** Construct breadth-first collections of filtered seed listing URLs to avoid simulating the JavaScript search form.

__Bottom line:__  
For this project, **headless browser automation is not required** and static shell scripting is fully sufficient for daily scraping—future browser automation is optional and only needed if Seek changes its technical approach.

---

## Appendix: Seed URLs & Google-Dork Examples

### Seek.com.au Regions/Categories

| Location                   | Base URL                                                                   |
|----------------------------|----------------------------------------------------------------------------|
| Perth, WA                  | https://www.seek.com.au/fifo-jobs/in-All-Perth-WA                          |
| Perth, WA (Fly-In Fly-Out) | https://www.seek.com.au/fifo-jobs/in-All-Perth-WA?keywords=fly-in-fly-out  |
| Perth, WA (Mobilisation)   | https://www.seek.com.au/fifo-jobs/in-All-Perth-WA?keywords=mobilisation    |
| Perth, WA (Travel)         | https://www.seek.com.au/fifo-jobs/in-All-Perth-WA?keywords=travel          |
| Darwin, NT                 | https://www.seek.com.au/fifo-jobs/in-All-Darwin-NT                         |
| ...                        | ... (See seeds.txt for full list)                                          |

See 'Filtered Seeds' below for a breadth-first coverage strategy using server-rendered URLs with pre-set filters.

### Filtered Seeds (breadth-first coverage without JS simulation)

The search bar UX (type-ahead suggestions, toggles) is JavaScript-driven, but **listing pages themselves** are addressable with **pre-composed URLs**. Originating your crawl from filtered listing URLs avoids headless-browser automation for the search form while still covering the same search space.

#### Recommended seed types
- **Work type:** `/jobs/full-time`, `/jobs/part-time`, `/jobs/contract-temp`, `/jobs/casual-vacation`
- **Remote options:** `/jobs/on-site`, `/jobs/hybrid`, `/jobs/remote`
- **Salary filters (type and range):**
  - `salarytype=annual|monthly|hourly`
  - `salaryrange=min-max` (e.g., `salaryrange=30000-100000`)
- **Date listed:** `daterange=1|3|7|14|31` (today → monthly)
- **Cities/regions:** `/jobs/in-All-Perth-WA`, `/jobs/in-All-Sydney-NSW`, etc.
- **Category+region:** e.g., `/fifo-jobs/in-Western-Australia-WA`, `/engineering-jobs/in-All-Melbourne-VIC`

#### Workflow for seeds
1. Maintain `seeds.txt` with 1 URL per line, each representing a filtered slice.
2. For each seed:
   - Detect route (Batch 1) → choose pagination strategy.
   - Crawl until "Next" vanishes (Batch 4).
3. Merge parsed listings; dedupe by company (see Batch 9, Validation).
4. Log coverage (seed → pages visited → number of listings).

> **Why this works:** These links are server-rendered listing views that present enough HTML markers to parse without simulating client-side JS (type-ahead, form submissions).

```sh
#!/bin/sh

while IFS= read -r seed; do
  paginate "$seed"  # internally selects offset vs. page-number model
done < seeds.txt
```

### Example Google/DuckDuckGo dorks

```
"{Name}" "{Company}" (email OR "mobile number" OR contact OR phone OR mobile OR "email address" OR "contact information") site:.com.au
"{Name}" "{Company}" "contact us" site:.com.au
filetype:pdf "{Company}" "contact" site:.com.au
"{Company}" "contact details" site:.com.au
```

### Example Output Row

```
company_name,prospect_name,title,phone,email,location
XYZ Pty Ltd,John Smith,Managing Director,0412345678,email@xyz.com.au,Perth, WA
ABC Ltd,Mary Jane,Owner,0498765432,test@abc.com.au,Darwin, NT
Business Name,Henry Smith,CFO,0411111111,henry@business.com.au,Adelaide, SA
```

---

## Risk Management Summary

- *Rate limiting & CAPTCHA*: Always pace requests conservatively, rotate UAs, and manually skip/record if CAPTCHA is hit
- *Data quality*: Strict rules and validation, with manual spot checks

---

## Deliverables

1. Full requirements document (this file)
2. Seed URLs and dork template file
3. Companies history file (admin-managed)
4. Scripts for CSV extraction, validation and error logging
5. Documentation/manuals for auditing and admin steps

---

## Search Bar & Automation Mapping

### Seek.com.au

- **Keywords Field**:  
  `<input id="keywords-input" name="keywords" type="text" ...>`
- **Location Field**:  
  `<input id="SearchBar__Where" name="where" type="search" ...>`
- **Search Button**:  
  `<span ...><span>SEEK</span></span>`
  - JS automation required to trigger searches

#### Shell example:

```sh
#!/bin/sh

# URL to fetch
URL='https://www.seek.com.au/jobs?keywords=administrator&where=Perth%2C+WA'

# Execute the Toybox http command and print the output
http GET "$URL"
```

---

### DuckDuckGo Lite Field Mapping

- **Query Field:** `<input class="query" name="q" ...>`
- **Search Button:** `<input class="submit" type="submit" ...>`  
- Example: `http GET 'https://lite.duckduckgo.com/lite/?q=company+email+site:.com.au'`
- Interactive/manual only—never scraped or parsed automatically

---

### Google.com.au Field Mapping

- **Query Field:**  
  `<textarea class="gLFyf" id="APjFqb" name="q" ...>`
- **Search Button:**  
  `<input class="gNO89b" name="btnK" ...>`
- Example: `http GET 'https://www.google.com.au/search?q=company+email+site:.com.au'`
- Interactive/manual only—never scraped or parsed automatically

---

**Important:**  
- Always check robots.txt before scraping any site  
  - [Seek robots.txt](https://www.seek.com.au/robots.txt)
  - [DuckDuckGo robots.txt](https://duckduckgo.com/robots.txt)
  - [Google robots.txt](https://www.google.com.au/robots.txt)
- Only scrape Seek’s *search listing* pages (never job or profile detail pages)
- Google and DuckDuckGo: results used only to find contacts manually—not to be scraped

---

## Interactive Google-Dorking Workflow

Use CLI scripts to pick dorks, launch manual browser queries, and add enriched leads by hand.

**Basic shell:**

```sh
select DORK_QUERY in $(cat dork_templates.txt); do
  xdg-open "https://www.google.com.au/search?q=$DORK_QUERY"
  break
done
```

Results are reviewed manually and copied to the daily CSV.

---

## Changelog

- 8 December 2025: All sections rewritten for selector stability and modern Seek.com.au markup, plus attention to Australian spelling, idiom and norms.

---

**This project strictly observes robots.txt, ToS, and only uses automation where clearly permitted. Manual/interactive protocols for dorking and enrichment are integral. Do not attempt to automate any part not explicitly allowed above.**
