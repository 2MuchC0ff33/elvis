# TODO — Roadmap & Task List

A step-by-step, incremental roadmap for this project (POSIX shell + curl + coreutils). Follow tasks in order. See primary spec: [README.md](README.md) and agent guidance: [.github/copilot-instructions.md](.github/copilot-instructions.md). Seeds are in [seeds.txt](seeds.txt).

---

## Setup (Repo housekeeping & minimal scaffolding)

- [ ] Add `.editorconfig` (UTF-8, LF) (branch: `feature/setup-editorconfig`)  
  - Dependency: none  
  - Git: `git checkout -b feature/setup-editorconfig`
- [ ] Add `.gitattributes` to enforce UTF-8 + LF (branch: `feature/add-gitattributes`)  
  - Dependency: `.editorconfig`  
  - Git: `git checkout -b feature/add-gitattributes`
- [ ] Update `.gitignore` to ignore `logs/`, `tmp/`, `data/calllists/`, `.env` (branch: `feature/update-gitignore`)  
  - Dependency: none — see current [`.gitignore`](.gitignore) and extend it  
  - Git: `git checkout -b feature/update-gitignore`
- [ ] Add `.env.example` (branch: `feature/add-env-example`)  
  - Dependency: `.gitignore` (ensure `.env` ignored)  
  - Git: `git checkout -b feature/add-env-example`
- [ ] Create authoritative folders (branch: `feature/create-folders`)  
  - Create: `scripts/`, `scripts/lib/`, `bin/`, `configs/`, `data/calllists/`, `data/seeds/`, `docs/`, `docs/man/`, `logs/`, `tmp/`, `tests/`, `examples/`, `cron/`, `.github/workflows/`  
  - Git: `git checkout -b feature/create-folders`

---

## Configuration (templates & examples)

- [ ] Add `configs/seek-pagination.ini` template (branch: `feature/add-configs`)  
  - Dependency: `configs/` created  
  - Git: `git checkout -b feature/add-configs`
- [ ] Add `config.ini` and `project.conf` example files at repo root (branch: `feature/add-config-templates`)  
  - Dependency: `configs/seek-pagination.ini`  
  - Git: `git checkout -b feature/add-config-templates`
- [ ] Add `.env` usage docs to `README.md` and `docs/runbook.md` (branch: `feature/doc-env`)  
  - Dependency: `.env.example`  
  - Git: `git checkout -b feature/doc-env`

---

## Documentation (docs & manpages)

- [ ] Add `docs/runbook.md` with run/rollback procedures & enrichment policy (branch: `docs/add-runbook`)  
  - Dependency: basic scripts & `.env` examples  
  - Git: `git checkout -b docs/add-runbook`
- [ ] Add `docs/man/elvis.1` (mandoc man page) (branch: `docs/add-manpage`)  
  - Dependency: skeleton `bin/elvis-run` (below)  
  - Git: `git checkout -b docs/add-manpage`
- [ ] Update `README.md` with the finalized "Project Structure" (branch: `docs/update-readme-structure`)  
  - Dependency: repo scaffolding complete  
  - Git: `git checkout -b docs/update-readme-structure`

Referenced files:

- [README.md](README.md)
- [.github/copilot-instructions.md](.github/copilot-instructions.md)

---

## Core scripts — iterative, testable steps

1) Orchestrator & helpers (skeleton → expand)

- [ ] Add `bin/elvis-run` launcher (branch: `feature/add-launcher`)  
  - Small wrapper that calls `scripts/run.sh` and checks prerequisites.  
  - Git: `git checkout -b feature/add-launcher`
- [ ] Add `scripts/run.sh` skeleton (branch: `feature/add-run-sh`)  
  - Read `seeds.txt`, create temp workspace, call fetch/parse/dedupe, output CSV to `data/calllists/calllist_YYYY-MM-DD.csv`.  
  - Dependency: `seeds.txt` exists ([seeds.txt](seeds.txt))  
  - Git: `git checkout -b feature/add-run-sh`
- [ ] Add `scripts/lib/log.sh` logging utility (branch: `feature/add-logging-lib`)  
  - Functions: log_start, log_seed, log_end, log_warn, log_error; single-line run format per README.  
  - Git: `git checkout -b feature/add-logging-lib`

1) Fetching & reliability

- [ ] Add `scripts/fetch.sh` implementing `fetch_with_backoff(url)` (branch: `feature/add-fetch-sh`)  
  - Respect timeouts, UA rotation, randomized delay, retries (5s→20s→60s). Record failures and skip on CAPTCHA.  
  - Dependency: `scripts/lib/http_utils.sh` and `scripts/lib/log.sh`  
  - Git: `git checkout -b feature/add-fetch-sh`
- [ ] Add `scripts/lib/http_utils.sh` for UA pool & robots.txt check (branch: `feature/add-http-utils`)  
  - Implement `allowed_by_robots(url)` helper.  
  - Git: `git checkout -b feature/add-http-utils`

1) Parsing & extraction

- [ ] Add `scripts/parse.sh` implementing `parse_listings(html)` (branch: `feature/add-parse-sh`)  
  - Use `awk`/`grep`/`sed` to split `</article>` and extract fields using `data-automation` markers per [README.md](README.md).  
  - Git: `git checkout -b feature/add-parse-sh`
- [ ] Add unit-friendly parsing examples under `tests/fixtures/` (branch: `test/add-parse-fixtures`)  
  - Git: `git checkout -b test/add-parse-fixtures`

1) Deduplication & validation

- [ ] Add `scripts/dedupe.sh` to dedupe case-insensitively against today's set and `companies_history.txt` (branch: `feature/add-dedupe-sh`)  
  - Follow PDL `is_dup_company` behavior described in [README.md](README.md). Ensure no normalisation except lowercase check.  
  - Dependency: `companies_history.txt` presence (admin-managed)  
  - Git: `git checkout -b feature/add-dedupe-sh`
- [ ] Add `scripts/validate.sh` to validate phone/email and phone normalisation `+61` → `0` (branch: `feature/add-validate-sh`)  
  - Implement email regex `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}` and phone digits-only rule.  
  - Git: `git checkout -b feature/add-validate-sh`

1) Enrichment & markers (manual steps)

- [ ] Add `scripts/enrich.sh` which flags rows needing manual enrichment and offers dork templates (branch: `feature/add-enrich-sh`)  
  - Produce an "enrich-needed" file/signal so an operator can add contact info.  
  - Git: `git checkout -b feature/add-enrich-sh`
- [ ] Add interactive helper `scripts/choose_dork.sh` (branch: `feature/add-dork-helper`)  
  - Uses `seeds.txt` or `dork_templates` and opens a browser with a query.  
  - Git: `git checkout -b feature/add-dork-helper`

1) History & append helpers

- [ ] Add `scripts/history_append.sh` to append accepted `company_name` to `companies_history.txt` (branch: `feature/add-history-append`)  
  - Interactive confirmation and safe append (atomic write).  
  - Git: `git checkout -b feature/add-history-append`

---

## Data & manual operations

- [ ] Create `companies_history.txt` (branch: `admin/create-companies-history`)  
  - Add guidance in `docs/runbook.md` for admin workflow. Leave empty initially (admin-managed).  
  - Git: `git checkout -b admin/create-companies-history`
- [ ] Verify and clean `seeds.txt` formatting and headers (branch: `maintenance/standardize-seeds`)  
  - Git: `git checkout -b maintenance/standardize-seeds`

---

## Testing & Quality

- [ ] Add `tests/run-tests.sh` harness and smoke tests (branch: `test/add-run-tests`)  
  - Fixtures: parse, dedupe, validate, fetch (mocked)  
  - Git: `git checkout -b test/add-run-tests`
- [ ] Add shellcheck configuration and address findings (branch: `chore/fix-shellcheck`)  
  - Git: `git checkout -b chore/fix-shellcheck`
- [ ] Add CI workflow `.github/workflows/ci.yml` (branch: `ci/add-ci`)  
  - Steps: shellcheck, run `tests/run-tests.sh`, lint docs; see [.github/copilot-instructions.md](.github/copilot-instructions.md)  
  - Git: `git checkout -b ci/add-ci`

Referenced file:

- [.github/copilot-instructions.md](.github/copilot-instructions.md)

---

## Automation & scheduling

- [ ] Add `cron/elvis.cron` example and docs (branch: `feature/add-cron`)  
  - Show cron entry to run `bin/elvis-run` daily; include concurrency and logging guidance.  
  - Git: `git checkout -b feature/add-cron`
- [ ] Add `.github/workflows/scheduled-run.yml` for optional GitHub Actions scheduled test/run (branch: `feature/schedule-gh-action`)  
  - Use cautious, read-only / dry-run mode only; do not auto-publish outputs without operator approval.  
  - Git: `git checkout -b feature/schedule-gh-action`
- [ ] Add log rotation script or `logrotate` config and retention policy (branch: `feature/add-log-rotation`)  
  - Git: `git checkout -b feature/add-log-rotation`

---

## Security & compliance

- [ ] Ensure `.env` is ignored and provide `.env.example` (branch: `security/ignore-env`)  
  - Git: `git checkout -b security/ignore-env`
- [ ] Add robots.txt checks into fetchers and log if blocked (branch: `feature/respect-robots`)  
  - Git: `git checkout -b feature/respect-robots`
- [ ] Add guidance in `docs/runbook.md` for legal & privacy compliance (branch: `docs/add-compliance`)  
  - Git: `git checkout -b docs/add-compliance`

---

## Release & Production Readiness

- [ ] Prepare a production checklist & runbook in `docs/runbook.md` (branch: `ops/runbook`)  
  - Items: monitoring, backup of `companies_history.txt`, restore steps, emergency stop, and audit extraction.  
  - Git: `git checkout -b ops/runbook`
- [ ] Final QA run: execute a full manual run, enrich contacts, verify ≥25 leads (branch: `release/qa-run`)  
  - On success: tag `v0.1.0` and create release notes.  
  - Git: `git checkout -b release/qa-run`
- [ ] Add `CONTRIBUTING.md` and `CODE_OF_CONDUCT` (branch: `docs/contributing`)  
  - Git: `git checkout -b docs/contributing`

---

## Nice-to-have / future improvements

- [ ] Add optional `edbrowse` or light browser fallback if Seek switches to client-only rendering (branch: `feature/browser-fallback`)
- [ ] Provide a small UI to help manual enrichment (branch: `feature/enrichment-ui`)
- [ ] Audit tooling to compute run statistics and weekly summary emails (branch: `feature/ops-audit`)

---

## How to use this TODO

- Claim a single task per branch and open PR with linked issue (if enabled).  
- Reference the relevant files when writing code: [README.md](README.md), [seeds.txt](seeds.txt), [.gitignore](.gitignore), [.github/copilot-instructions.md](.github/copilot-instructions.md).  
- Keep commits small and descriptive; use feature branches as suggested above.

---

© Project: follow LICENSE (see [LICENSE](LICENSE)).  
