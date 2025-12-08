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
