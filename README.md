# Elvis: Australian Sales Lead Call List Scraper

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)

Elvis is a POSIX shell-based web scraper that generates daily call lists of
Australian companies from job boards like Seek. It is designed for reliability,
transparency, and easy customization, following Unix philosophy and best
practices for open source projects.

---

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Implementation Details](#implementation-details)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## Features

- **POSIX Shell Only**: No Python, Node, or external dependencies beyond
  standard Unix tools (curl, awk, sed, grep, sort, uniq, tr, date, printf).
- **Configurable**: All behavior is controlled via a single config file
  (`etc/elvisrc`).
- **Respects robots.txt**: Honors site crawling rules when enabled.
- **User-Agent Rotation**: Rotates user agents to avoid blocks.
- **Exponential Backoff**: Retries failed requests with increasing delays.
- **CAPTCHA Detection**: Skips pages that present CAPTCHAs.
- **Pagination Support**: Follows next-page links to collect more results.
- **Deduplication**: Ensures unique company entries, case-insensitive, with
  history tracking.
- **Validation**: Ensures output meets format and quality standards.
- **Logging**: Structured logs for all actions and network events.
- **Extensible**: Modular design with AWK and SED scripts for parsing and
  extraction.

---

## Getting Started

### Prerequisites

- Unix-like environment (Linux, macOS, Cygwin, WSL, etc.)
- POSIX shell (sh, bash, dash, etc.)
- Standard Unix utilities: curl, awk, sed, grep, sort, uniq, tr, date, printf

### Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/yourusername/elvis.git
   cd elvis
   ```

2. **Make scripts executable:**

   ```sh
   chmod +x bin/elvis.sh lib/*.sh
   ```

3. **Configure:** Edit `etc/elvisrc` to set paths, toggles, and limits as
   needed.

---

## Configuration

All configuration is centralized in [`etc/elvisrc`](etc/elvisrc):

- File paths (input, output, logs, history)
- Behavior toggles (robots.txt, UA rotation, retry logic)
- Network and rate limiting
- Output limits

**Do not hard-code values elsewhere.**

---

## Usage

### Main Run

Generate the daily call list (writes to `home/calllist.txt`):

```sh
bin/elvis.sh
```

### Append to History

Append newly discovered companies to history (case-preserving):

```sh
bin/elvis.sh --append-history
```

### Validate Output

Run the call list validator standalone:

```sh
lib/validate_calllist.sh
```

### Logs

- Logs are stored in `var/log/elvis.log`.
- Log rotation is handled automatically.

---

## Project Structure

```text
.
├── bin/                # Main entrypoint scripts
│   └── elvis.sh
├── lib/                # Library scripts (sh, awk, sed)
│   ├── data_input.sh
│   ├── processor.sh
│   ├── ...
├── etc/                # Configuration
│   └── elvisrc
├── home/               # Output call lists
│   └── calllist.txt
├── srv/                # Input data (seed URLs, UA list, company history)
│   ├── urls.txt
│   ├── ua.txt
│   └── company_history.txt
├── var/                # Logs, temp, and spool files
│   ├── log/
│   ├── spool/
│   ├── src/
│   └── tmp/
├── docs/               # Documentation
│   └── USAGE.md
├── archive/            # Historical data and changelogs
├── tests/              # Integration and unit tests
└── ...
```

---

## Implementation Details

- **Pipeline:**
  - `elvis.sh` orchestrates the run: reads seed URLs, fetches pages, parses,
    deduplicates, and validates output.
  - `data_input.sh` fetches and paginates through job listings, extracting
    company and location using modular AWK/SED scripts.
  - `processor.sh` normalizes, deduplicates, and writes the final call list,
    updating history if requested.
  - `validate_calllist.sh` ensures output quality and format.
- **Parsing:**
  - Uses SED and AWK scripts for robust extraction from HTML.
  - Fallback logic ensures extraction even if primary patterns fail.
- **Deduplication:**
  - Case-insensitive, history-aware, preserves first occurrence.
- **Extensibility:**
  - Add new extraction logic by editing or adding scripts in `lib/`.

---

## Contributing

Contributions are welcome! Please open issues or pull requests for bug fixes,
improvements, or new features.

- Follow POSIX shell and Unix philosophy.
- Keep all configuration in `etc/elvisrc`.
- Write clear, modular scripts and document your changes.
- Add or update tests in `tests/` as needed.

---

## License

This project is licensed under the
[GNU Affero General Public License v3.0](LICENSE).

---

## Acknowledgements

- [Unix Filesystem Layout](https://en.wikipedia.org/wiki/Unix_filesystem#Conventional_directory_layout)
- [RC File](http://www.catb.org/jargon/html/R/rc-file.html)
- [GitHub Flavored Markdown](https://github.github.com/gfm/)
- [Pseudocode Standard](https://users.csc.calpoly.edu/~jdalbey/SWE/pdl_std.html)
- [Sed](https://en.wikipedia.org/wiki/Sed)
- [Awk](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html)
