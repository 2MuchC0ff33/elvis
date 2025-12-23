# Copilot / AI Agent Instructions — elvis

These instructions help an AI coding agent be immediately productive in this repository.
Reference files: `README.md` (primary specification), `seeds.txt`, `companies_history.txt`, and `seeds.txt` (seed URL templates).

---

## Quick project summary
- Purpose: Produce a daily CSV call list of Australian companies with at least one contact (phone or email) by scraping public job listing pages (primary source: Seek Australia).
- Key files and outputs:
  - `seeds.txt` — seed listing URLs and dork templates
  - `companies_history.txt` — one company name per line; used for case-insensitive historical dedupe
  - `calllist_YYYY-MM-DD.csv` — daily output (overwritten each run)
  - `log.txt` — per-run logs (timestamp, seeds, pages, listings, warnings/errors)

## What to know up front (high-value conventions)
- Company deduplication: **case-insensitive on `company_name` only**; do NOT normalise punctuation, suffixes, or whitespace. Same name across different locations is still a duplicate.
- Required output row fields: `company_name` (required), `prospect_name`, `title`, `phone`, `email`, `location`. Skip any listing missing `company_name`.
- Contact requirement: Final call list rows must have **at least one valid contact** (phone or email) after manual enrichment.
- Phone normalisation: digits-only. Convert `+61` mobile prefixes to `0` (e.g. `+61412...` => `0412...`).

## Validation patterns (copyable)
- Email regex: `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`
- Phone rule: digits only after normalisation (no spaces/formatting in stored CSV)
- When in doubt, follow the exact rules in `README.md`.

## Scraping & reliability rules (strict, observable in README)
- Respect robots.txt and site Terms-of-Service; do not scrape private profiles (LinkedIn, Facebook) or pages that disallow scraping.
- Anti-bot policy:
  - Randomised per-request delay (example: 1.2–4.8s)
  - Retries with exponential backoff (5s → 20s → 60s), up to 3 attempts per URL
  - Timeouts: set connection/read timeouts (e.g., 10–15s)
  - Do not attempt CAPTCHA solving; log and skip if encountered
  - No proxy/chaining or offshore scraping APIs
  - Rotate User-Agent strings from a vetted pool

## Logging, errors & debugging
- Log at run-level: start/end timestamps, seed URL, pages fetched, listings parsed, number of valid rows, warnings, errors (CAPTCHA, timeouts, fallback pagination detection), and any `ATTR_CHANGE=true` flags for seeds that need human review.
- Verbose mode: emit record-level debugging information for investigations.
- Follow the logging format examples in `README.md` to preserve auditability.

## Manual steps & human-in-the-loop
- Contact enrichment is manual in the current workflow; scripts should leave clear markers for rows that need enrichment.
- When a company is accepted, append its canonical name to `companies_history.txt` (admin-managed file).

## File & naming conventions
- Output filename: `calllist_YYYY-MM-DD.csv` (overwrite on each run)
- History filename: `companies_history.txt` (append-only by policy)
- Logs: single `log.txt` per run line; rotate/retain per the README policy

## Code & tooling conventions
- Scripts are shell-based (Bourne shell / POSIX): prefer `curl`, `grep`, `sed`, `awk`, `tr`, `sort`, `uniq` and `coreutils` for parsing and orchestration.
- Platform: cross-platform but primarily POSIX-like; Windows support expected through compatible shells.
- RCS is referenced for manual commits (no forced git hooks or CI referenced in repo).

## Examples (copy into PRs or quick tests)
- Minimal CSV row example:
  `company_name,prospect_name,title,phone,email,location`
- Log line example:
  `2025-12-09T09:31:07Z seed=/jobs?keywords=admin&where=Perth%2C+WA model=offset pages=6 listings=132 ok=true warn=fallback_next=false errors=0`

## When editing this file (or adding automation)
- If a `.github/copilot-instructions.md` already exists, merge carefully: preserve any project-specific guidance, update validation rules, and add new examples.
- Keep instructions short, concrete, and anchored to files present in the repo (avoid speculative automation details not found in repository docs).

---

If anything is unclear or you want additional examples (e.g., a starter `run.sh` wrapper or a log parser), tell me which part to expand and I will iterate. ✅
