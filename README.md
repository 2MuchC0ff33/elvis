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

## 11. Anti-Bot/Evasion & Reliability

- Do not use proxies or offshore scraping APIs
- Be conservative:
    - Slow, randomised delays and hard rate limiting
    - Rotate UA strings
    - DuckDuckGo Lite is preferred for minimal JS/CAPTCHA
    - Log and skip if CAPTCHA appears (manual intervention only)
- Retrying: max of 3 times per URL; exponential backoff (5s, 20s, 60s); skip after that

---

## 12. Error Handling, Logging & Monitoring

- Script logs all runs to `log.txt`
    - Include: timestamp, queried URLs, search terms
    - Number of unique records found
    - Errors/warnings (CAPTCHA, timeout etc.)
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

## Seek.com.au Selector Mapping (as at 8 December 2025)

- **Pagination:**
  - Use the `data-automation="page-next"` value to locate the “Next” button:
    ```html
    <span data-automation="page-next">Next</span>
    ```
  - Fallback: detect text "Next" in any span if the above fails (prone to breakage).
- **Shell/C Workflow:** Seek paginates search with the URL parameter `start`, e.g. `start=22` for page 2 (22 results per page):
  ```
  https://www.seek.com.au/jobs?keywords=administrator&where=Perth%2C+WA&start=22
  ```
  Keep incrementing `start` by ‘22’ until the "Next" span is missing.

- **Job listing/card structure:**
  - Each job is: `<article data-automation="normalJob">...</article>`
    - **Title:** `<a data-automation="jobTitle">`
    - **Company:** `<a data-automation="jobCompany">`
    - **Location:** `<a data-automation="jobLocation">`
    - **Short description:** `<span data-automation="jobShortDescription">`
    - **Job ID:** `data-job-id` attribute
  - Only fields visible here can be automatically gathered.

- **Contact info (phone/email):**
  - **Not present** in Seek job cards — must be found by operator using dorks, company sites and public resources.

- **Selectors advice:**
  - Always use `data-automation` attributes for scrapers/parsers (e.g. `[data-automation="jobCompany"]`). Avoid using class names (change frequently).

- **Search fields:**
  - **Keywords**: `<input id="keywords-input" name="keywords" type="text" ...>`
  - **Location**: `<input id="SearchBar__Where" name="where" type="search" ...>`

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
