# Runbook — Elvis (operations & configuration)

This runbook documents the operational configuration, initialisation, and quick
reference for running the Elvis scraper.

## Get Transaction Data Workflow

This workflow automates the process of loading, normalising, splitting, and
fetching paginated data from seeds for lead generation, strictly following the
logic and pseudocode in README.md.

### Steps

1. **Normalise seeds.csv**

- Cleans whitespace, removes BOM, and ensures consistent CSV format.
- Uses:
  `awk -f scripts/lib/normalize.awk data/seeds/seeds.csv > tmp/seeds.normalized.csv`

1. **Split into per-record .txt files**

- Each record is written to `tmp/records/seed_N.txt` for modular processing.
- Uses: `sh scripts/lib/split_records.sh tmp/seeds.normalized.csv tmp/records/`

1. **Load seeds and detect pagination model**

- Loads seeds into arrays and determines the correct pagination logic for each.
- Uses: `. scripts/lib/load_seeds.sh tmp/seeds.normalized.csv` and
  `sh scripts/lib/pick_pagination.sh <url>`

1. **Paginate and fetch with backoff**

- Iterates through each page for each seed, using exponential backoff on
  failures, via fetch.sh.
- Uses: `sh scripts/lib/paginate.sh <base_url> <model>`

1. **Orchestration**

- The entire workflow is run via: `bin/elvis-run get-transaction-data`
- Output: HTML for each seed is saved to `tmp/<seed_id>.htmls`

### Error Handling

- Missing or malformed seeds file: workflow aborts with a clear error.
- Fetch failures: retried with exponential backoff, up to 3 times.
- All steps log progress and output locations.

### Example

```sh
bin/elvis-run get-transaction-data
```

This will normalise, split, detect, and fetch all seeds, saving results to
`tmp/`.

Elvis uses a modular, POSIX-compliant shell init sequence to prepare the
environment before scraping or lead generation. The init process ensures all
configuration files are loaded, required environment variables are validated,
and logging is set up.

### Init Steps

1. **Load .env**: `scripts/lib/load_env.sh` — loads environment overrides and
   secrets (optional).
2. **Load project.conf**: `scripts/lib/load_config.sh` — loads canonical project
   configuration.
3. **Load Seek pagination config**: `scripts/lib/load_seek_pagination.sh` —
   loads Seek-specific selectors and pagination settings.
4. **Validate environment**: `scripts/lib/validate_env.sh` — checks all required
   variables are set.
5. **Prepare log file**: `scripts/lib/prepare_log.sh` — ensures `logs/log.txt`
   and its directory exist.

The master orchestrator is `bin/elvis-run`, which runs all steps in order:

```sh
bin/elvis-run init
```

For help and usage examples:

```sh
bin/elvis-run help
```

Each modular script can be sourced or executed directly. See
`scripts/init-help.sh` for details.

### Example: Manual Step-by-Step Init

```sh
. scripts/lib/load_env.sh
. scripts/lib/load_config.sh
. scripts/lib/load_seek_pagination.sh
. scripts/lib/validate_env.sh
. scripts/lib/prepare_log.sh
```

If any required config or variable is missing, a clear error is printed and the
process exits non-zero.

## Key files & purpose

- `.env` / `.env.example` — runtime overrides and **secrets** (highest
  precedence). Do not commit secrets.
- `project.conf` — canonical, non-secret operational defaults (key=value).
  Scripts should use this as the single source of truth for defaults.
- `configs/seek-pagination.ini` — Seek-specific selectors and per-seed override
  examples. Keep site logic here.
- `data/seeds/seeds.csv` — seed list with header `seed_id,location,base_url`.
  Use `seed_id` to tie to per-seed overrides.

## Precedence (always follow)

1. Environment variables / `.env` (highest)
2. `project.conf`
3. Built-in script defaults (lowest)

Scripts should load configuration in that order and **log** which source
provided each setting for auditability.

## Practical usage examples

1. Set a runtime override locally (temporary):

FETCH_TIMEOUT=10 bin/elvis-run init

1. Permanent operational default (project-level): edit `project.conf`:

FETCH_TIMEOUT=15

1. Secrets (API keys, notification credentials): place only in `.env` or use a
   secret manager and ensure `.env` is in `.gitignore`.

2. Run all init steps and start a new log:

bin/elvis-run init

1. Show help for all init scripts:

bin/elvis-run help

1. Run tests for the init workflow:

tests/run-tests.sh

## Seeds & per-seed overrides

- Keep seeds in `data/seeds/seeds.csv` with `seed_id` column. Example row:

  seek_fifo_perth,"Perth,
  WA",<https://www.seek.com.au/fifo-jobs/in-All-Perth-WA>

- Per-seed overrides live in `configs/seek-pagination.ini` under `[overrides]`
  and are keyed by `seed_id` (example in the file comments).

```sh
grep -E '^[A-Z0-9_]+=.\*' project.conf > "$tmp_conf"
done < "$tmp_conf"

```

## Modular Init Scripts Reference

- `scripts/lib/load_env.sh` — Loads `.env` (if present) into the environment.
- `scripts/lib/load_config.sh` — Loads `project.conf` into the environment.
- `scripts/lib/load_seek_pagination.sh` — Loads Seek pagination config as
  SEEK\_\* variables.
- `scripts/lib/validate_env.sh` — Validates all required environment variables.
- `scripts/lib/prepare_log.sh` — Ensures log file and directory exist.
- `scripts/init-help.sh` — Prints help and usage for all init scripts.
- `bin/elvis-run` — Orchestrates the full init sequence.

All scripts are POSIX-compliant and provide clear error messages on failure.

## Testing the Init Workflow

Run all tests for the init sequence:

```sh
tests/run-tests.sh
```

This will check config loading, environment validation, and log setup. All tests
should pass for a correct setup.

### ShellCheck (recommended)

We recommend installing `shellcheck` for local linting and CI checks.
`shellcheck` helps catch common shell scripting errors and enforces good
practices. The test suite will run `shellcheck -x` (if available) across all
`.sh` files.

- Install (macOS/Homebrew): `brew install shellcheck`
- Install (Debian/Ubuntu): `sudo apt install shellcheck`
- Run locally:

```sh
shellcheck -x bin/elvis-run scripts/lib/*.sh scripts/*.sh
```

- VS Code: set the workspace setting to follow sources (see
  `.vscode/settings.json`):

```json
{
  "shellcheck.extraArgs": ["-x"]
}
```

If `shellcheck` is not installed the test runner will SKIP the lint step and
continue. Installing it is recommended for contributors and CI to ensure script
quality and maintainability.

### Cygwin / Windows note

On Cygwin, ShellCheck installed under Windows (Scoop/Chocolatey) may not accept
POSIX paths by default. We provide a small wrapper
`scripts/lib/shellcheck-cygwin-wrapper.sh` that converts POSIX file paths to
Windows paths and calls the Windows `shellcheck.exe`. To use it, set the
`SHELLCHECK` environment variable to the Windows executable's POSIX path
(example shown), or place the wrapper earlier in your `PATH`.

Example (Cygwin):

```sh
WINPATH=$(cmd.exe /c "where shellcheck" 2>/dev/null | tr -d '\r' | sed -n '1p')
[ -n "$WINPATH" ] && export SHELLCHECK="$(cygpath -u "$WINPATH")"
```

Once set, re-run `./tests/run-tests.sh` and the test runner will use the wrapper
and the Windows ShellCheck.

## Troubleshooting & change detection

- If any init step fails, check the error message for missing files or
  variables.
- If pagination fails across seeds, check `configs/seek-pagination.ini`
  selectors and `page_next_marker` first.
- If run behaviour differs between environments, ensure you check the effective
  source for keys (env vs `project.conf`) by adding logging to the script.
- If pagination fails across seeds, check `configs/seek-pagination.ini`
  selectors and `page_next_marker` first.
- If run behaviour differs between environments, ensure you check the effective
  source for keys (env vs `project.conf`) by adding logging to the script.

## Migration note

- `config.ini` was deprecated and retained only for reference; move any required
  non-secret keys from `config.ini` into `project.conf` and remove references to
  `config.ini` in automation scripts.

## Set-status workflow — Enrich, Validate, Deduplicate, Audit ✅

This workflow supports updating result records (`results.csv`) with manual
enrichment by an administrator and producing a final daily calllist with updated
statuses and an audit trail.

Quick steps:

1. Prepare `results.csv` with expected headers:
   `company_name,prospect_name,title,phone,email,location`.
2. Run `scripts/enrich_status.sh results.csv --out tmp/enriched.csv --edit` to
   create an editable copy and open it in `$EDITOR` for manual enrichment.
3. After enrichment, run
   `scripts/set_status.sh --input results.csv --enriched tmp/enriched.csv --commit-history`
   to validate, dedupe and produce `data/calllists/calllist_YYYY-MM-DD.csv`.
4. Logs are written to `logs/log.txt` and audit records to `audit.txt`.

Notes & behaviour:

- Validation checks: required fields, at least one contact (phone or email),
  email regex, and phone normalisation (converts `+61` prefixes to `0` and
  strips non-digits).
- Deduplication: case-insensitive match on `company_name` against
  `companies_history.txt` (append-only). Use `--commit-history` to append newly
  accepted companies to history.
- The workflow is orchestrated by `scripts/set_status.sh` and is available via
  `bin/elvis-run set-status`.

Example (non-interactive):

sh scripts/set_status.sh --input results.csv --enriched tmp/enriched.csv
--out-dir data/calllists --commit-history

This will run validation, deduplication (appending history), produce the daily
CSV, and write audit/log entries.

---

Keep this runbook updated when configuration practices, file locations, or init
scripts change.
