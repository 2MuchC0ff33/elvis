
# Runbook — Elvis (operations & configuration)

This runbook documents the operational configuration, initialisation, and quick reference for running the Elvis scraper.

## Initialisation Sequence (Init Workflow)

Elvis uses a modular, POSIX-compliant shell init sequence to prepare the environment before scraping or lead generation. The init process ensures all configuration files are loaded, required environment variables are validated, and logging is set up.

### Init Steps

1. **Load .env**: `scripts/lib/load_env.sh` — loads environment overrides and secrets (optional).
2. **Load project.conf**: `scripts/lib/load_config.sh` — loads canonical project configuration.
3. **Load Seek pagination config**: `scripts/lib/load_seek_pagination.sh` — loads Seek-specific selectors and pagination settings.
4. **Validate environment**: `scripts/lib/validate_env.sh` — checks all required variables are set.
5. **Prepare log file**: `scripts/lib/prepare_log.sh` — ensures `logs/log.txt` and its directory exist.

The master orchestrator is `bin/elvis-run`, which runs all steps in order:

```sh
bin/elvis-run init
```

For help and usage examples:

```sh
bin/elvis-run help
```

Each modular script can be sourced or executed directly. See `scripts/init-help.sh` for details.

### Example: Manual Step-by-Step Init

```sh
. scripts/lib/load_env.sh
. scripts/lib/load_config.sh
. scripts/lib/load_seek_pagination.sh
. scripts/lib/validate_env.sh
. scripts/lib/prepare_log.sh
```

If any required config or variable is missing, a clear error is printed and the process exits non-zero.

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

2. Permanent operational default (project-level): edit `project.conf`:

  FETCH_TIMEOUT=15

3. Secrets (API keys, notification credentials): place only in `.env` or use a secret manager and ensure `.env` is in `.gitignore`.

4. Run all init steps and start a new log:

  bin/elvis-run init

5. Show help for all init scripts:

  bin/elvis-run help

6. Run tests for the init workflow:

  tests/run-tests.sh

## Seeds & per-seed overrides

- Keep seeds in `data/seeds/seeds.csv` with `seed_id` column. Example row:

  seek_fifo_perth,"Perth, WA",<https://www.seek.com.au/fifo-jobs/in-All-Perth-WA>
- Per-seed overrides live in `configs/seek-pagination.ini` under `[overrides]`
  and are keyed by `seed_id` (example in the file comments).

grep -E '^[A-Z0-9_]+=.*' project.conf > "$tmp_conf"
done < "$tmp_conf"

## Modular Init Scripts Reference

- `scripts/lib/load_env.sh` — Loads `.env` (if present) into the environment.
- `scripts/lib/load_config.sh` — Loads `project.conf` into the environment.
- `scripts/lib/load_seek_pagination.sh` — Loads Seek pagination config as SEEK_* variables.
- `scripts/lib/validate_env.sh` — Validates all required environment variables.
- `scripts/lib/prepare_log.sh` — Ensures log file and directory exist.
- `scripts/init-help.sh` — Prints help and usage for all init scripts.
- `bin/elvis-run` — Orchestrates the full init sequence.

All scripts are POSIX-compliant and provide clear error messages on failure.

## Troubleshooting & change detection

- If any init step fails, check the error message for missing files or variables.
- If pagination fails across seeds, check `configs/seek-pagination.ini` selectors and `page_next_marker` first.
- If run behaviour differs between environments, ensure you check the effective source for keys (env vs `project.conf`) by adding logging to the script.

## Testing the Init Workflow

Run all tests for the init sequence:

```sh
tests/run-tests.sh
```

This will check config loading, environment validation, and log setup. All tests should pass for a correct setup.

## Troubleshooting & change detection

- If pagination fails across seeds, check `configs/seek-pagination.ini`
  selectors and `page_next_marker` first.
- If run behaviour differs between environments, ensure you check the effective
  source for keys (env vs `project.conf`) by adding logging to the script.

## Migration note

- `config.ini` was deprecated and retained only for reference; move any required
  non-secret keys from `config.ini` into `project.conf` and remove references to
  `config.ini` in automation scripts.

---


Keep this runbook updated when configuration practices, file locations, or init scripts change.
