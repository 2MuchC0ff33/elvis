# Comprehensive Project Plan: Australian Sales Lead Call List Scraper

## 1. Project Objective

Produce a daily call list of at least 25 unique Australian companies, each with the prospect's name, title, contact details (mobile and/or email), and business location. Data will be used for sales lead-generation and prospecting. The company names must always be unique and duplicates across days will be excluded using historical company data.

## 2. Data Requirements

**Required data fields:**
- Company Name (must be unique, case-insensitive)
- Lead/Prospect Name
- Title
- Location
- Mobile phone (normalised digits only, e.g. 0412345678)
- Email (any domain)
- _Note_: If contact details are missing, the record is excluded.

## 3. Data Sources

- Primary: [Seek Australia](https://www.seek.com.au/) (job postings for employer/company field)
- Supplementary: [DuckDuckGo Lite](https://lite.duckduckgo.com/lite) (for Google-Dorking queries)
- Supplementary: [Google](https://www.google.com/) (Google-Dorking, only .com.au domains)
- Only scrape from public web pages; do not scrape private profiles (LinkedIn, personal social media) or any site disallowing scraping per robots.txt or terms of service.

## 4. Geographic, Language & Domain Limitation

- Only Australian businesses (.com.au domains)
- All content must be in English (en_AU.UTF-8 preferred)
- Seed job searches target major Australian capitals and regions (see list below)

## 5. Success Criteria, KPIs & Acceptance

- **Daily success:** List of at least 25 unique companies (case-insensitive match, no repeats vs historical list)
- Each row must have at least one contact detail (phone or email)
- Company names missing or incomplete are excluded
- No duplicates from previous lists (historical company_name exclusion)
- If <25 leads found in the day, write a partial CSV and log a warning
- The project is successful if daily lists are generated with valid contact details and no duplicate companies from previous runs

## 6. Volume, Frequency & Retention

- Minimum 25 leads per run
- Data is updated daily
- Daily call list overwrites the previous day's file (except history)
- Historical list of company names retained indefinitely (companies_history.txt under RCS/manual version control)

## 7. Storage, Output Format & Encoding

- Exported as single-line per record CSV file (UTF-8, en_AU.UTF-8)
- `calllist_YYYY-MM-DD.csv` (overwritten daily)
- Historical file: `companies_history.txt` (company names, one per line, appended manually)
- No source URLs, scrape timestamps, or lineage in the CSV
- Example format for CSV:
  ```
  company_name,prospect_name,title,phone,email,location
  XYZ Pty Ltd,John Smith,Managing Director,0412345678,email@xyz.com.au,Perth, WA
  ABC Ltd,Mary Jane,Owner,0498765432,test@abc.com.au,Darwin, NT
  ```

## 8. Tools & Tech Stack

**Essential:**
- surf (WebKit2 browser as embeddable headless rendering)
- ANSI C (using tcc, libcurl, libxml, dietlibc)
- Bourne Shell (`/bin/sh`) for orchestration
- busybox (for utilities: grep, sed, awk), wak (POSIX-compliant awk)
- csvquote (CSV-safe UNIX tooling)
- RCS (manual revision control of history)
- OpenBSD httpd (optional; concise static hosting if needed)
- mandoc (UNIX manpage compiler, documentation tool)

**Non-essential/optional:**
- Nuklear (TUI/GUI, single-header cross-platform)
- termbox (terminal UI)
- pv (pipe progress monitoring)
- menu (CLI selection scripting)

**Cross-platform:** Linux, BSD, macOS, Windows (WSL2). Static, portable, and simple tooling is required.

## 9. Scraping Method & Strategy

- Use libcurl/libxml for non-JS content
- Use surf/WebKit2 for pages needing JavaScript
- Shell scripting to orchestrate fetch, parse, validate, deduplicate, and report
- Helper binaries (grep, sed, awk) are allowed
- Google-Dorking with custom queries to DuckDuckGo Lite and Google:
  - Limit results to .com.au domains only
  - Use job title, company, person name, location dorks
- Example dork: `"Jane Smith" "email" OR "phone" OR "mobile" site:.com.au`
- Full dork/seed template list in Appendix

## 10. Data Validation, Deduplication & Cleaning

- Company name uniqueness is a case-insensitive exact string match
- If two companies have the same name but different locations, treat as duplicate
- No additional normalisation for suffixes, whitespace or punctuation
- Exclude any row missing a company name
- Accept records with either phone OR email (not mandatory for both)
- Email validation: POSIX standard regex `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`
- Phone validation: normalise to digits only, convert +61 to 0-prefix

## 11. Anti-Bot/Evasion & Reliability

- No proxies or external scraping APIs (avoid extra cost)
- Conservative, stable approach:
    - Slow, randomised request pacing and strict rate limits
    - Rotate user-agent strings
    - Use DuckDuckGo Lite to avoid JS overhead/captcha
    - Manual intervention on CAPTCHA (log and skip any failed site)
- Retry per page: up to 3 attempts per URL; exponential backoff (5s, 20s, 60s), then skip and log failures

## 12. Error Handling, Logging & Monitoring

- All runs log to `log.txt`:
    - Timestamp of run
    - URLs/search terms processed
    - Records found, unique companies added, errors/warnings (e.g., CAPTCHAs, timeouts)
    - Per-record error/debug lines if verbose mode enabled
    - Keep recent logs or rotate weekly (policy to be set later)
- No external monitoring or alerting required – local logs only

## 13. Security, Privacy & Compliance

- Only collect public information — no private or restricted data
- Explicitly avoid scraping sites or profiles disallowed by robots.txt or ToS
- Respect Australian privacy and ethical standards
- If requested, manual removal of personal/company details from history CSV will be performed

## 14. Retention & Admin Control

- Daily call list is overwritten after next run
- companies_history.txt is retained and appended manually (only by admin)
- RCS commits for company history file will be performed manually

## 15. Scheduling & Automation

- Scraper runs manually initially; cronjob on Unix/BSD/macOS/WSL2 to be set up after approval/MVP validation

## 16. Project Acceptance Criteria

- At least 25 unique companies per daily CSV (company_name case-insensitively unique, not present in companies_history.txt)
- At least one valid contact (phone or email) per prospect
- No duplicates across days
- Partial result allowed (<25 companies) — must log a warning
- Output format, tools, scripts, and logs conform to this plan

## 17. MVP/First Steps

- Prepare scripts (shell + minimal C helpers for parsing)
- Prepare `seeds.txt` (seek URLs + dork templates)
- Prepare `companies_history.txt` (admin starts, appended manually)
- Prepare documentation and log structure for auditing

---

## Appendix: Seed URLs & Google-Dork Examples

### Seek.com.au Regions/Categories
# Comprehensive Project Plan: Australian Sales Lead Call List Scraper

## Appendix: Seed Data

### Seek.com.au Regions/Categories

| Location                                    | Base URL                                                                                          |
|----------------------------------------------|---------------------------------------------------------------------------------------------------|
| Perth, WA                                   | https://www.seek.com.au/fifo-jobs/in-All-Perth-WA                                                 |
| Perth, WA (Fly-In Fly-Out)                   | https://www.seek.com.au/fifo-jobs/in-All-Perth-WA?keywords=fly-in-fly-out                         |
| Perth, WA (Mobilisation)                     | https://www.seek.com.au/fifo-jobs/in-All-Perth-WA?keywords=mobilisation                           |
| Perth, WA (Travel)                           | https://www.seek.com.au/fifo-jobs/in-All-Perth-WA?keywords=travel                                 |
| Darwin, NT                                  | https://www.seek.com.au/fifo-jobs/in-All-Darwin-NT                                                |
| Darwin, NT (Fly-In Fly-Out)                  | https://www.seek.com.au/fifo-jobs/in-All-Darwin-NT?keywords=fly-in-fly-out                        |
| Darwin, NT (Mobilisation)                    | https://www.seek.com.au/fifo-jobs/in-All-Darwin-NT?keywords=mobilisation                          |
| Darwin, NT (Travel)                          | https://www.seek.com.au/fifo-jobs/in-All-Darwin-NT?keywords=travel                                |
| Adelaide, SA                                | https://www.seek.com.au/fifo-jobs/in-All-Adelaide-SA                                              |
| Adelaide, SA (Fly-In Fly-Out)                | https://www.seek.com.au/fifo-jobs/in-All-Adelaide-SA?keywords=fly-in-fly-out                      |
| Adelaide, SA (Mobilisation)                  | https://www.seek.com.au/fifo-jobs/in-All-Adelaide-SA?keywords=mobilisation                        |
| Adelaide, SA (Travel)                        | https://www.seek.com.au/fifo-jobs/in-All-Adelaide-SA?keywords=travel                              |
| Western Australia (WA)                       | https://www.seek.com.au/fifo-jobs/in-Western-Australia-WA                                         |
| Western Australia (WA) (Fly-In Fly-Out)      | https://www.seek.com.au/fifo-jobs/in-Western-Australia-WA?keywords=fly-in-fly-out                 |
| Western Australia (WA) (Mobilisation)        | https://www.seek.com.au/fifo-jobs/in-Western-Australia-WA?keywords=mobilisation                   |
| Western Australia (WA) (Travel)              | https://www.seek.com.au/fifo-jobs/in-Western-Australia-WA?keywords=travel                         |
| South Australia (SA)                         | https://www.seek.com.au/fifo-jobs/in-South-Australia-SA                                           |
| South Australia (SA) (Fly-In Fly-Out)        | https://www.seek.com.au/fifo-jobs/in-South-Australia-SA?keywords=fly-in-fly-out                   |
| South Australia (SA) (Mobilisation)          | https://www.seek.com.au/fifo-jobs/in-South-Australia-SA?keywords=mobilisation                     |
| South Australia (SA) (Travel)                | https://www.seek.com.au/fifo-jobs/in-South-Australia-SA?keywords=travel                           |
| Alice Springs & Central Australia            | https://www.seek.com.au/fifo-jobs/in-Alice-Springs-&-Central-Australia-NT                        |
| Alice Springs & Central Australia (Fly-In Fly-Out) | https://www.seek.com.au/fifo-jobs/in-Alice-Springs-&-Central-Australia-NT?keywords=fly-in-fly-out      |
| Alice Springs & Central Australia (Mobilisation) | https://www.seek.com.au/fifo-jobs/in-Alice-Springs-&-Central-Australia-NT?keywords=mobilisation      |
| Alice Springs & Central Australia (Travel)   | https://www.seek.com.au/fifo-jobs/in-Alice-Springs-&-Central-Australia-NT?keywords=travel         |
| Northern Territory (NT)                      | https://www.seek.com.au/fifo-jobs/in-Northern-Territory-NT                                        |
| Northern Territory (NT) (Fly-In Fly-Out)     | https://www.seek.com.au/fifo-jobs/in-Northern-Territory-NT?keywords=fly-in-fly-out                 |
| Northern Territory (NT) (Mobilisation)       | https://www.seek.com.au/fifo-jobs/in-Northern-Territory-NT?keywords=mobilisation                   |
| Northern Territory (NT) (Travel)             | https://www.seek.com.au/fifo-jobs/in-Northern-Territory-NT?keywords=travel                         |

### Google/DuckDuckGo Dork Examples
```plaintext
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

- **Rate-limiting/CAPTCHA:** Conservative pace, UA rotation, manual skip on CAPTCHAs
- **Data quality:** Simple validation, strict inclusion rules, manual spot-checks
- **Cross-platform:** If surf/WebKit2 is unavailable, fallback to libcurl/libxml only and adapt scripts for compatibility

## Deliverables

1. Full requirements plan (this document)
2. Seed URL and dork template file
3. Companies history file (admin curated)
4. Scripts for CSV extraction and error logging (once approved)
5. Documentation of usage and manual run/append steps

## Seek.com.au Search Bar and Search Button Automation Guide

For automated data collection and scraping from Seek.com.au job search, the following mapping and techniques apply:

### 1. Keywords Field

- **HTML Example:**
  ```html
  <input
    id="keywords-input"
    name="keywords"
    type="text"
    placeholder="Enter keywords"
    value="">
  ```
- **Use:** Set job titles, company names, and other relevant keywords here.

### 2. Location Field

- **HTML Example:**
  ```html
  <input
    id="SearchBar__Where"
    name="where"
    type="search"
    placeholder="Enter suburb, city, or region"
    value="">
  ```
- **Use:** Set the target city/region here (e.g., Perth, WA).

### 3. Search Button

The Seek job search page submits either via the form or a search button, which is a `<span>` element, not a `<button>`, and generally controlled by JavaScript.

#### Example HTML (truncated):

```html
<span class="_1yd5ljl0 ... xg30qa4">
  <span>SEEK</span>
</span>
```

- There may be no easily-guessable selector (`id`), so select by **class** or by text ("SEEK") in browser automation tools (surf/WebKit2, Selenium, Playwright, etc.).
- This triggers JavaScript to submit the form with populated inputs.

#### Automation Usage

- **Populate** `#keywords-input` and `#SearchBar__Where` as above.
- **Trigger Search:** Simulate user click on the search button, or send an Enter key event to either input.
- **Example** (browser automation pseudo-code):

  ```js
  document.querySelector('span.xg30qa4').click();
  // Or, find the nearest <span> with innerText "SEEK"
  ```

- **Alternative:** For direct HTTP/curl scripting, just construct the jobs URL with query parameters (see below).

### How to Target in Scripts

- For direct HTTP requests (libcurl, shell, etc.), supply as query parameters:
  ```
  https://www.seek.com.au/jobs?keywords=administrator&where=Perth%2C+WA
  ```
- For browser automation, fill the inputs by their `id` or `name`, then trigger the search as above.

#### Example (Shell)
```sh
curl 'https://www.seek.com.au/jobs?keywords=administrator&where=Perth%2C+WA'
```

#### Example (C, using libcurl)
```c
snprintf(request_url, sizeof(request_url),
         "https://www.seek.com.au/jobs?keywords=%s&where=%s",
         "administrator", "Perth, WA");
curl_easy_setopt(curl, CURLOPT_URL, request_url);
```

> For JS-heavy navigation/results, use browser automation to manipulate these fields and trigger searches as described.

---

**Note:** Only `name` and `id` attributes are required for targeting; other attributes are for frontend and accessibility.

---

### Advanced: Seek Internal Job Search API

For advanced or scriptable scraping, Seek's frontend uses an internal API, called with parameters for job search and filtering:

- **API Endpoint Example**
  ```
  GET https://jobsearch-api.cloud.seek.com.au/v5/counts?siteKey=AU-Main&...
  ```

- **Parameters:**  
  - `keywords=fifo`
  - `where=Northern Territory NT`
  - Additional: `include=seodata,gptTargeting,relatedsearches`, session IDs, and more.

- **Sample Request (Shell):**
  ```sh
  curl 'https://jobsearch-api.cloud.seek.com.au/v5/counts?siteKey=AU-Main&keywords=fifo&where=Northern%20Territory%20NT&include=seodata,gptTargeting,relatedsearches&locale=en-AU'
  ```

**Notes:**
- Returns JSON with counts and metadata.
- Requires headers/cookies (`__cf_bm`, `_cfuvid`) for subsequent requests.
- Listings/job details are loaded from further API calls after search.

---

### Summary

- **Browser automation:** Fill inputs, click the search button (by class `xg30qa4` or text "SEEK").
- **Direct HTTP:** GET requests to `/jobs` or API endpoints with parameters.
- **API scraping:** Replicate session headers/cookies for JSON results.

---

**Always follow Seek.com.au's robots.txt and Terms of Service. Avoid excess or unwanted traffic.**

## DuckDuckGo Lite Search Bar Field Mapping for Scraping

DuckDuckGo Lite (`lite.duckduckgo.com/lite`) provides a simple search form, ideal for lightweight automated scraping with shell, C (libcurl), or browser automation.

### 1. Query Field

- **HTML Example:**
  ```html
  <input
    class="query"
    type="text"
    size="40"
    name="q"
    autocomplete="off"
    value=""
    autofocus="">
  ```
- **Use:** Enter the search query (keywords, dorks, company, etc.) in this field.

### 2. Search Button

- **HTML Example:**
  ```html
  <input
    class="submit"
    type="submit"
    value="Search">
  ```
- **Use:** Submits the search form.

### How to Target in Scripts

- For direct HTTP requests (curl, etc.), submit with `q=SEARCH_TERM` to the appropriate DuckDuckGo Lite search endpoint:
  ```
  https://lite.duckduckgo.com/lite/?q=company+email+site:.com.au
  ```
- For browser automation, fill the query field by `name="q"` or `class="query"`, then click the submit button by `class="submit"` or simply submit the form.

#### Example (Shell)
```sh
curl 'https://lite.duckduckgo.com/lite/?q=company+email+site:.com.au'
```

#### Example (C, using libcurl)
```c
snprintf(request_url, sizeof(request_url),
         "https://lite.duckduckgo.com/lite/?q=%s",
         "company email site:.com.au");
curl_easy_setopt(curl, CURLOPT_URL, request_url);
```

- For browser-driven approaches, simulate filling the text field and clicking the "Search" button.

---

**Note:** Only `name="q"` and `class="submit"` are required for targeting; other attributes are for UI/UX.

---

**DuckDuckGo Lite is designed for minimalism and speed, making it well suited for scripting and automated collection of search results.**  

## Google.com.au Search Bar Field Mapping for Scraping

Google's search page (`google.com.au`) uses a form with a text area for query input and a button for submitting searches.

### 1. Query Field

- **HTML Example:**
  ```html
  <textarea
    jsname="yZiJbe"
    class="gLFyf"
    id="APjFqb"
    name="q"
    title="Search"
    role="combobox"
    maxlength="2048"
    aria-label="Search"
    autocomplete="off"
    autocapitalize="none"
    autocorrect="off"
    spellcheck="false"
    rows="1"></textarea>
  ```
- **Use:** Enter the search query (keywords, dorks, company, site:.com.au, etc.) in this field.

### 2. Search Button

- **HTML Example:**
  ```html
  <input
    class="gNO89b"
    value="Google Search"
    aria-label="Google Search"
    name="btnK"
    role="button"
    tabindex="0"
    type="submit">
  ```
- **Use:** Submits the search form with the provided query.

### How to Target in Scripts

- For direct HTTP requests (curl, etc.), submit with `q=SEARCH_TERM` as a URL parameter to the Google search endpoint:
  ```
  https://www.google.com.au/search?q=company+email+site:.com.au
  ```
- For browser automation, fill the query field by `id="APjFqb"` or `name="q"`, then trigger the Search button (`name="btnK"`, `class="gNO89b"`, or by value).

#### Example (Shell)
```sh
curl 'https://www.google.com.au/search?q=company+email+site:.com.au'
```

#### Example (C, using libcurl)
```c
snprintf(request_url, sizeof(request_url),
         "https://www.google.com.au/search?q=%s",
         "company email site:.com.au");
curl_easy_setopt(curl, CURLOPT_URL, request_url);
```

- For browser-automation/code, simulate a submit event for the form or click the "Google Search" button.

---

**Note:** Only `name="q"` for the query input and `name="btnK"` for the search button are required; other attributes are for frontend, accessibility, or JavaScript control.

---

**Automated Google scraping may trigger anti-bot detection. Use slow, cautious pacing and always comply with Google's robots.txt and Terms of Service.**

