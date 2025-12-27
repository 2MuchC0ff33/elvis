# CHANGELOG

All notable changes to this project will be documented in this file.

## Unreleased

- feat(config): add focused `configs/fetch.ini` and
  `scripts/lib/load_fetch_config.sh` to centralise fetch, CAPTCHA and 403
  handling; scripts now load fetch config if present and will use `project.conf`
  / `.env` values when available
- chore: update `.env.example`, `scripts/fetch.sh`, `scripts/lib/http_utils.sh`,
  `scripts/lib/paginate.sh` and docs to reflect configuration centralisation

## 23 December 2025

- docs: consolidated README into a single commit and added comprehensive project
  plan (history rewritten and squashed for clarity)

## 9 December 2025

- docs: Added new "Orchestration Flow" section detailing the full stepwise
  scraping, validation, enrichment, and output process from seeds to CSV, based
  on improved analysis of Seek.com.au behaviour.

## 8 December 2025

- docs: All sections rewritten for selector stability and modern Seek.com.au
  markup, plus attention to Australian spelling, idiom and norms.

## 6 December 2025

- Initial commit (project scaffold)

---

Notes:

- Keep the `CHANGELOG.md` up to date with each meaningful change. Use brief,
  actionable entries and standard prefixes (docs:, feat:, fix:, chore:).
