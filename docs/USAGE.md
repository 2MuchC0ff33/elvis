# Elvis scraper - usage notes

Setup

1. Ensure files are executable (one-time):

   chmod +x bin/elvis.sh lib/\*.sh lib/loop.awk

2. Configure behaviour only in `etc/elvisrc`. Do NOT hard-code values elsewhere.

Running

- To run and produce the daily calllist (writes to `home/calllist.txt`):

  bin/elvis.sh

- To run and append newly-discovered companies to history (case-preserving):

  bin/elvis.sh --append-history

- Validation: the main run validates `home/calllist.txt` after generation. A
  failing validation will invoke `lib/default_handler.sh` and exit non-zero.

- To run the validator standalone:

  lib/validate_calllist.sh

Notes

- Uses POSIX utilities only: curl, awk, sed, grep, sort, uniq, tr, date, printf.
- Respects `robots.txt` when `VERIFY_ROBOTS=true`.
- Logs are stored in `var/log/elvis.log` with structured network logs and
  rotated weekly.
