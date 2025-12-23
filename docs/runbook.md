# Runbook — Elvis (operations & configuration)

This runbook documents the operational configuration and quick reference for running the Elvis scraper.

## Key files & purpose

- `.env` / `.env.example` — runtime overrides and **secrets** (highest precedence). Do not commit secrets.
- `project.conf` — canonical, non-secret operational defaults (key=value). Scripts should use this as the single source of truth for defaults.
- `configs/seek-pagination.ini` — Seek-specific selectors and per-seed override examples. Keep site logic here.
- `data/seeds/seeds.csv` — seed list with header `seed_id,location,base_url`. Use `seed_id` to tie to per-seed overrides.

## Precedence (always follow)

1. Environment variables / `.env` (highest)
2. `project.conf`
3. Built-in script defaults (lowest)

Scripts should load configuration in that order and **log** which source provided each setting for auditability.

## Practical usage examples

1) Set a runtime override locally (temporary):

   export FETCH_TIMEOUT=10
   ./bin/elvis-run

2) Permanent operational default (project-level): edit `project.conf`:

   FETCH_TIMEOUT=15

3) Secrets (API keys, notification credentials): place only in `.env` or use a secret manager and ensure `.env` is in `.gitignore`.

## Seeds & per-seed overrides

- Keep seeds in `data/seeds/seeds.csv` with `seed_id` column. Example row:

  seek_fifo_perth,"Perth, WA",<https://www.seek.com.au/fifo-jobs/in-All-Perth-WA>

- Per-seed overrides live in `configs/seek-pagination.ini` under `[overrides]` and are keyed by `seed_id` (example in the file comments).

## Safely loading `project.conf` in shell scripts (recommended pattern)

Use a small parser that ignores comments and blank lines, then exports KEY=VALUE pairs. Example (POSIX sh compatible):

```sh
# load .env first if present
if [ -f .env ]; then
  # export variables from .env (ignore comments)
  set -a
  . .env
  set +a
fi

# load project.conf (safe parse)
while IFS='=' read -r key val; do
  case "$key" in
    ''|\#*) continue ;;
    *) export "$key"="$val" ;;
  esac
done < <(grep -E '^[A-Z0-9_]+=.*' project.conf)
```

Notes:

- Avoid simply `source`-ing files that may contain unexpected code; prefer the safe parse above.
- After loading, scripts may apply per-seed overrides by checking for `OVERRIDE_${seed_id}_KEY` environment variables or parsing `seek-pagination.ini`.

## Troubleshooting & change detection

- If pagination fails across seeds, check `configs/seek-pagination.ini` selectors and `page_next_marker` first.
- If run behaviour differs between environments, ensure you check the effective source for keys (env vs `project.conf`) by adding logging to the script.

## Migration note

- `config.ini` was deprecated and retained only for reference; move any required non-secret keys from `config.ini` into `project.conf` and remove references to `config.ini` in automation scripts.

---

Keep this runbook updated when configuration practices or file locations change.
