# Copilot / AI Agent Instructions — elvis

These instructions help an AI coding agent be immediately productive in this
repository. Reference files: [`README.md`](../README.md) (primary
specification), [`docs/runbook.md`](../docs/runbook.md), and
[`companies_history.txt`](../companies_history.txt).

---

## Quick project summary

- Purpose: Produce a daily CSV call list of Australian companies with at least
  one contact (phone or email) by scraping public job listing pages (primary
  source: Seek Australia).
- Key files and outputs:
  - `seeds.csv` — seed listing URLs and dork templates (see `data/seeds/`)
  - `companies_history.txt` — one company name per line; used for
    case-insensitive historical dedupe (see [`is_dup_company`](../README.md))
  - `calllist_YYYY-MM-DD.csv` — daily output (overwritten each run)
  - `log.txt` — per-run logs (timestamp, seeds, pages, listings,
    warnings/errors)
  - `.snapshots/` — local snapshot and patch storage used by the mini VCS (see
    README examples)

---

## What to know up front (high-value conventions)

- Company deduplication: **case-insensitive on `company_name` only**; do NOT
  normalise punctuation, suffixes, or whitespace. Same name across different
  locations is still a duplicate.
- Required output row fields: `company_name` (required), `prospect_name`,
  `title`, `phone`, `email`, `location`. Skip any listing missing
  `company_name`.
- Contact requirement: Final call list rows must have **at least one valid
  contact** (phone or email) after manual enrichment.
- Phone normalisation: digits-only. Convert `+61` mobile prefixes to `0` (e.g.
  `+61412...` => `0412...`).
- Follow the project's PDL and helper modules described in
  [`README.md`](../README.md), such as [`fetch_with_backoff`](../README.md) and
  pagination helpers (`pick_pagination`) when implementing fetchers and
  paginators.

---

## Updated additions (from the revised README)

1. Mini VCS integration (POSIX utilities)

   - The project uses a lightweight, POSIX-friendly mini VCS for data artefacts
     and generated outputs.
   - Tools and workflows to use:
     - Create snapshots: `tar -czf .snapshots/snap-<ts>.tar.gz <paths>` and
       record checksums (e.g. `sha1sum`).
     - Generate patches:
       `diff -uNr base/ new/ > .snapshots/patches/<name>.patch`.
     - Apply patches: `patch -p0 < .snapshots/patches/<name>.patch`.
     - Verify with `sha1sum -c` and `cmp` as needed.
   - See the `Mini VCS Integration` and Snapshot examples in
     [`README.md`](../README.md).
   - When adding automation for snapshots, ensure `.snapshots/` is in
     `.gitignore` and that checksums and an index are maintained.

2. Manuals and roff typesetting
   - There is now guidance to author manuals with `roff`/`man` macros and to
     render with `nroff`/`groff`.
   - Recommended files live under `docs/man/` (example:
     [`docs/man/elvis.1`](../docs/man/elvis.1)).
   - Helpful commands:
     - View locally: `nroff -man docs/man/elvis.1 | less -R`
     - Render UTF‑8: `groff -Tutf8 -man docs/man/elvis.1 | less -R`
     - Produce PDF (if groff present):
       `groff -Tpdf -man docs/man/elvis.1 > docs/man/elvis.pdf`
   - When generating manpages, include standard sections (`NAME`, `SYNOPSIS`,
     `DESCRIPTION`, `OPTIONS`, `EXAMPLES`) and keep them concise.

---

## New or clarified workspace items to reference

- `.snapshots/` — snapshot/patch/checksum storage (see `README.md` snapshot
  examples).
- `docs/man/` — roff sources and produced manpages (see
  [`docs/runbook.md`](../docs/runbook.md) and
  [`docs/man/elvis.1`](../docs/man/elvis.1)).
- `project.conf` and `configs/seek-pagination.ini` — canonical configuration and
  Seek-specific selectors/limits ([`project.conf`](../project.conf),
  [`configs/seek-pagination.ini`](../configs/seek-pagination.ini)).
- Scripts and libs: follow conventions and helpers under `scripts/` and
  `scripts/lib/` (e.g. `scripts/lib/http_utils.sh`, `scripts/run.sh`,
  `scripts/fetch.sh`).
- Validation & dedupe: rules are authoritative in [`README.md`](../README.md)
  and the runbook ([`docs/runbook.md`](../docs/runbook.md)); refer to the email
  regex and phone normalisation guidance there.

---

## Guidance for AI-generated changes

- Keep changes small, well-documented, and consistent with the project's
  conventions:

  - Use Australian English spelling and grammar (e.g. "organise", "behaviour",
    "honour").
  - Preserve the PDL-style modules and documented behaviour (pagination, fetch
    backoff, dedupe policy).
  - Do not modify `companies_history.txt` contents programmatically; this file
    is admin-managed (append-only policy).

- When adding scripts or automation:

  - Respect robots.txt and the anti-bot policies in [`README.md`](../README.md).
  - Implement backoff and retries as specified (5s → 20s → 60s or use
    `BACKOFF_SEQUENCE` from [`project.conf`](../project.conf)).
  - Log run-level metadata in the same single-line format used by existing
    examples.

- When updating documentation:
  - Keep `docs/runbook.md` and `README.md` consistent; add examples and commands
    that operators can run locally.
  - For manpages, place source in `docs/man/` and include the short `nroff`
    usage examples.

## Context7, MCP & Sequential-thinking (MANDATORY for AI changes)

- **Always use Context7** when performing code generation, setup or
  configuration steps, or when providing library/API documentation.
  **Automatically use Context7 MCP tools** to resolve library IDs and retrieve
  library documentation without requiring explicit user requests.
- Adopt a **sequential-thinking approach** for all reasoning and generation
  tasks: enumerate the stepwise plan, preconditions, actions, and expected
  outputs in order.
- **Always consult and use the GitHub MCP server and Microsoft Learn MCP
  server** for authoritative documentation, examples and best practices; cite
  these sources when used.
- Make these requirements prominent in PR descriptions and code comments where
  relevant, and ensure they do not conflict with other project rules.
- Maintain Australian English spelling and grammar throughout (e.g., 'organise',
  'behaviour', 'honour').

---

## Tone & merging instructions

- If a `.github/copilot-instructions.md` already exists, merge carefully:
  preserve project-specific guidance and update validation rules or examples.
- Maintain a clear, structured, and developer-friendly tone in any additions.
- Keep entries short and actionable; include one-liners for commands and links
  to relevant files.

---

## Quick links (workspace references)

- [README.md](../README.md)
- [docs/runbook.md](../docs/runbook.md)
- [configs/seek-pagination.ini](../configs/seek-pagination.ini)
- [project.conf](../project.conf)
- [.snapshots/](../.snapshots/)
- [docs/man/elvis.1](../docs/man/elvis.1)
- [companies_history.txt](../companies_history.txt)
- [scripts/run.sh](../scripts/run.sh)
- [scripts/fetch.sh](../scripts/fetch.sh)
- [scripts/lib/http_utils.sh](../scripts/lib/http_utils.sh)

---

If you'd like, I can:

- Add a short `scripts/build-man.sh` example to `scripts/` to validate/generate
  manpages, or
- Draft a small `scripts/snapshot.sh` that implements the mini VCS snapshot +
  checksum steps.

---
