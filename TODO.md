# TODO — Roadmap & Task List

This file is the canonical, incremental roadmap for *Project Elvis* (POSIX shell + curl + coreutils). Tasks are intentionally small and sequential—start at the top and work down. Each task includes: a short description, suggested branch name, dependencies, Git command, and GitHub metadata (labels, project, milestone, issue, estimate, tags).

Metadata legend:

- Labels: comma-separated labels you should add when opening an issue/PR (e.g., `setup`, `documentation`, `automation`).
- Project: Project board name (e.g., `Project Elvis`).
- Milestone: Release target (e.g., `v1.0`).
- Issue: placeholder issue number (replace with actual issue, e.g., `#1`).
- Estimate: rough time to complete (e.g., `~1h`, `~2d`).
- Tags: short-tags for searchability (e.g., `#setup`, `#config`).

---

## 0. Onboarding (very small tasks)

A step-by-step, incremental roadmap for this project (POSIX shell + curl + coreutils). Follow tasks in order. See primary spec: [README.md](README.md) and agent guidance: [.github/copilot-instructions.md](.github/copilot-instructions.md). Seeds are in [seeds.txt](seeds.txt).

---

## 1. Setup (repo housekeeping & minimal scaffolding)

- [X] Add `.editorconfig` (UTF-8, LF) (branch: `feature/setup-editorconfig`)  
  - Description: Enforce encoding/line endings for contributors.  
  - Git: `git checkout -b feature/setup-editorconfig`  
  - Labels: `setup` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#3` | Estimate: `~30m` | Tags: `#setup #config`
- [X] Add `.gitattributes` to enforce UTF-8 + LF (branch: `feature/add-gitattributes`)  
  - Dependency: `.editorconfig`  
  - Git: `git checkout -b feature/add-gitattributes`  
  - Labels: `setup` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#4` | Estimate: `~15m` | Tags: `#setup`
- [X] Update `.gitignore` to ignore `logs/`, `tmp/`, `data/calllists/`, `.env` (branch: `feature/update-gitignore`)  
  - Git: `git checkout -b feature/update-gitignore`  
  - Labels: `setup` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#5` | Estimate: `~15m` | Tags: `#setup #config`
- [X] Add `.env.example` (branch: `feature/add-env-example`)  
  - Dependency: `.gitignore` (ensure `.env` ignored)  
  - Git: `git checkout -b feature/add-env-example`  
  - Labels: `security`, `setup` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#6` | Estimate: `~20m` | Tags: `#env #security`
- [X] Create authoritative folders (branch: `feature/create-folders`)  
  - Create: `scripts/`, `scripts/lib/`, `bin/`, `configs/`, `data/calllists/`, `data/seeds/`, `docs/`, `docs/man/`, `logs/`, `tmp/`, `tests/`, `examples/`, `cron/`, `.github/workflows/`  
  - Git: `git checkout -b feature/create-folders`  
  - Labels: `setup` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#7` | Estimate: `~1h` | Tags: `#setup #scaffold`

---

## Configuration (templates & examples)

- [ ] Add `configs/seek-pagination.ini` template (branch: `feature/add-configs`)  
  - Dependency: `configs/` created  
  - Git: `git checkout -b feature/add-configs`  
  - Labels: `config` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#8` | Estimate: `~1h` | Tags: `#configs`
- [ ] Add `config.ini` and `project.conf` example files at repo root (branch: `feature/add-config-templates`)  
  - Dependency: `configs/seek-pagination.ini`  
  - Git: `git checkout -b feature/add-config-templates`  
  - Labels: `config` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#9` | Estimate: `~1h` | Tags: `#config`
- [ ] Add `.env` usage docs to `README.md` and `docs/runbook.md` (branch: `feature/doc-env`)  
  - Dependency: `.env.example`  
  - Git: `git checkout -b feature/doc-env`  
  - Labels: `documentation`, `security` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#10` | Estimate: `~1h` | Tags: `#docs #env`

---

## Documentation (docs & manpages)

- [ ] Add `docs/runbook.md` with run/rollback procedures & enrichment policy (branch: `docs/add-runbook`)  
  - Dependency: basic scripts & `.env` examples  
  - Git: `git checkout -b docs/add-runbook`  
  - Labels: `documentation` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#11` | Estimate: `~2d` | Tags: `#docs #runbook`
- [ ] Add `docs/man/elvis.1` (mandoc man page) (branch: `docs/add-manpage`)  
  - Dependency: skeleton `bin/elvis-run` (below)  
  - Git: `git checkout -b docs/add-manpage`  
  - Labels: `documentation` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#12` | Estimate: `~2h` | Tags: `#docs #man`
- [ ] Update `README.md` with the finalised "Project Structure" (branch: `docs/update-readme-structure`)  
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
  - Labels: `automation` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#14` | Estimate: `~1h` | Tags: `#bin #launcher`
- [ ] Add `scripts/run.sh` skeleton (branch: `feature/add-run-sh`)  
  - Read `seeds.txt`, create temp workspace, call fetch/parse/dedupe, output CSV to `data/calllists/calllist_YYYY-MM-DD.csv`.  
  - Dependency: `seeds.txt` exists ([seeds.txt](seeds.txt))  
  - Git: `git checkout -b feature/add-run-sh`  
  - Labels: `automation` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#15` | Estimate: `~4h` | Tags: `#scripts #orchestrator`
- [ ] Add `scripts/lib/log.sh` logging utility (branch: `feature/add-logging-lib`)  
  - Functions: log_start, log_seed, log_end, log_warn, log_error; single-line run format per README.  
  - Git: `git checkout -b feature/add-logging-lib`  
  - Labels: `utility` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#16` | Estimate: `~2h` | Tags: `#logging`

1) Fetching & reliability

- [ ] Add `scripts/fetch.sh` implementing `fetch_with_backoff(url)` (branch: `feature/add-fetch-sh`)  
  - Respect timeouts, UA rotation, randomised delay, retries (5s→20s→60s). Record failures and skip on CAPTCHA.  
  - Dependency: `scripts/lib/http_utils.sh` and `scripts/lib/log.sh`  
  - Git: `git checkout -b feature/add-fetch-sh`  
  - Labels: `automation`, `reliability` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#18` | Estimate: `~4h` | Tags: `#fetch #backoff`
- [ ] Add `scripts/lib/http_utils.sh` for UA pool & robots.txt check (branch: `feature/add-http-utils`)  
  - Implement `allowed_by_robots(url)` helper.  
  - Git: `git checkout -b feature/add-http-utils`  
  - Labels: `automation`, `reliability` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#17` | Estimate: `~3h` | Tags: `#http #robots`

1) Parsing & extraction

- [ ] Add `scripts/parse.sh` implementing `parse_listings(html)` (branch: `feature/add-parse-sh`)  
  - Use `awk`/`grep`/`sed` to split `</article>` and extract fields using `data-automation` markers per [README.md](README.md).  
  - Git: `git checkout -b feature/add-parse-sh`  
  - Labels: `automation`, `parsing` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#19` | Estimate: `~6h` | Tags: `#parse #extract`
- [ ] Add unit-friendly parsing examples under `tests/fixtures/` (branch: `test/add-parse-fixtures`)  
  - Git: `git checkout -b test/add-parse-fixtures`  
  - Labels: `test` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#20` | Estimate: `~1h` | Tags: `#fixtures`

1) Deduplication & validation

- [ ] Add `scripts/dedupe.sh` to dedupe case-insensitively against today's set and `companies_history.txt` (branch: `feature/add-dedupe-sh`)  
  - Follow PDL `is_dup_company` behavior described in [README.md](README.md). Ensure no normalisation except lowercase check.  
  - Dependency: `companies_history.txt` presence (admin-managed)  
  - Git: `git checkout -b feature/add-dedupe-sh`  
  - Labels: `automation` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#21` | Estimate: `~3h` | Tags: `#dedupe`
- [ ] Add `scripts/validate.sh` to validate phone/email and phone normalisation `+61` → `0` (branch: `feature/add-validate-sh`)  
  - Implement email regex `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}` and phone digits-only rule.  
  - Git: `git checkout -b feature/add-validate-sh`  
  - Labels: `automation`, `data-quality` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#22` | Estimate: `~2h` | Tags: `#validate`

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
- [ ] Verify and clean `seeds.txt` formatting and headers (branch: `maintenance/standardise-seeds`)  
  - Git: `git checkout -b maintenance/standardise-seeds`

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
  - Description: Show cron entry to run `bin/elvis-run` daily; include concurrency and logging guidance.
  - Git: `git checkout -b feature/add-cron`
  - Labels: `automation`, `ops` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#31` | Estimate: `~2h` | Tags: `#cron #ops`
- [ ] Add `.github/workflows/scheduled-run.yml` for optional GitHub Actions scheduled test/run (branch: `feature/schedule-gh-action`)
  - Description: Use cautious, read-only / dry-run mode only; do not auto-publish outputs without operator approval.
  - Git: `git checkout -b feature/schedule-gh-action`
  - Labels: `automation`, `ci` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#32` | Estimate: `~3h` | Tags: `#scheduled #gh-actions`
- [ ] Add log rotation script or `logrotate` config and retention policy (branch: `feature/add-log-rotation`)
  - Description: Add log rotation script or config and retention policy.
  - Git: `git checkout -b feature/add-log-rotation`
  - Labels: `ops` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#33` | Estimate: `~2h` | Tags: `#logs`

## Security & compliance

- [ ] Ensure `.env` is ignored and provide `.env.example` (branch: `security/ignore-env`)
  - Description: Ensure `.env` is in `.gitignore` and provide `.env.example` for contributors.
  - Git: `git checkout -b security/ignore-env`
  - Labels: `security` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#34` | Estimate: `~30m` | Tags: `#security`
- [ ] Add robots.txt checks into fetchers and log if blocked (branch: `feature/respect-robots`)
  - Description: Add robots.txt checks into fetchers and log if blocked.
  - Git: `git checkout -b feature/respect-robots`
  - Labels: `compliance` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#35` | Estimate: `~2h` | Tags: `#robots`
- [ ] Add guidance in `docs/runbook.md` for legal & privacy compliance (branch: `docs/add-compliance`)
  - Description: Add legal & privacy compliance guidance to runbook.
  - Git: `git checkout -b docs/add-compliance`
  - Labels: `documentation`, `compliance` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#36` | Estimate: `~2h` | Tags: `#privacy`

## Release & Production Readiness

- [ ] Prepare a production checklist & runbook in `docs/runbook.md` (branch: `ops/runbook`)
  - Description: Add items: monitoring, backup of `companies_history.txt`, restore steps, emergency stop, and audit extraction.
  - Git: `git checkout -b ops/runbook`
  - Labels: `ops` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#37` | Estimate: `~4h` | Tags: `#ops #runbook`
- [ ] Final QA run: execute a full manual run, enrich contacts, verify ≥25 leads (branch: `release/qa-run`)
  - Description: On success: tag `v0.1.0` and create release notes.
  - Git: `git checkout -b release/qa-run`
  - Labels: `release`, `qa` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#38` | Estimate: `~1d` | Tags: `#release #qa`
- [ ] Add `CONTRIBUTING.md` and `CODE_OF_CONDUCT` (branch: `docs/contributing`)
  - Description: Add contributing and code of conduct docs.
  - Git: `git checkout -b docs/contributing`
  - Labels: `documentation` | Project: `Project Elvis` | Milestone: `v1.0` | Issue: `#39` | Estimate: `~1h` | Tags: `#docs`

## Nice-to-have / future improvements (optional)

- [ ] Add `edbrowse` or lightweight browser fallback for client-only rendered pages (branch: `feature/browser-fallback`)
  - Description: Add `edbrowse` or similar fallback for client-only rendering.
  - Labels: `feature` | Project: `Project Elvis` | Milestone: `future` | Issue: `#40` | Estimate: `~3d` | Tags: `#browser`
- [ ] Add a small web UI for manual enrichment (branch: `feature/enrichment-ui`)
  - Description: Provide a small UI to help manual enrichment.
  - Labels: `feature`, `ux` | Project: `Project Elvis` | Milestone: `future` | Issue: `#41` | Estimate: `~2w` | Tags: `#ui #enrich`
- [ ] Add audit tooling for weekly run statistics and reports (branch: `feature/ops-audit`)
  - Description: Audit tooling to compute run statistics and weekly summary emails.
  - Labels: `ops` | Project: `Project Elvis` | Milestone: `future` | Issue: `#42` | Estimate: `~3d` | Tags: `#audit #ops`

## How to use this TODO

- Pick one top-level task and **create its branch** using the Git command in the task.  
- Open a single PR per branch, assign the labels and milestone noted here, link the issue if present.  
- Keep PRs small and focused; add tests and doc changes alongside code.  
- Mark sub-tasks on this file as you complete them and keep `README.md` and `.github/copilot-instructions.md` in sync with structural changes.

---

© Project Elvis — follow LICENSE (see [LICENSE](LICENSE)).
