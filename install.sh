#!/bin/sh
#
# Project installation / bootstrap script.
# This prepares the local environment so daily scraping scripts can run.
# It is safe to run multiple times (idempotent).

set -eu

# Determine repository root (directory containing this script)
ROOT_DIR=$(
    CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd
)

REQUIRED_CMDS="curl grep sed awk tr sort uniq date"

echo ">>> Checking required command-line tools..."
MISSING_CMDS=""
for cmd in $REQUIRED_CMDS; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING_CMDS="${MISSING_CMDS} $cmd"
    fi
done

if [ -n "${MISSING_CMDS# }" ]; then
    echo "ERROR: The following required tools are missing:${MISSING_CMDS}" >&2
    echo "Please install them with your system package manager (e.g., apt, yum, brew) and re-run ./install.sh." >&2
    exit 1
fi

echo ">>> Ensuring core data files exist..."

SEEDS_FILE="${ROOT_DIR}/seeds.txt"
HISTORY_FILE="${ROOT_DIR}/companies_history.txt"
LOG_FILE="${ROOT_DIR}/log.txt"

if [ ! -f "$SEEDS_FILE" ]; then
    echo "Creating seeds.txt with a comment header (add your seed URLs and templates here) ..."
    {
        echo "# seeds.txt"
        echo "# One seed URL or dork template per line."
        echo "# Populate this file with Seek AU job listing URLs or search templates as described in README.md."
    } >"$SEEDS_FILE"
else
    echo "seeds.txt already exists; leaving as-is."
fi

if [ ! -f "$HISTORY_FILE" ]; then
    echo "Creating companies_history.txt with a comment header ..."
    {
        echo "# companies_history.txt"
        echo "# One company_name per line."
        echo "# Used for case-insensitive historical dedupe on company_name only."
    } >"$HISTORY_FILE"
else
    echo "companies_history.txt already exists; leaving as-is."
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "Creating empty log.txt ..."
    : >"$LOG_FILE"
else
    echo "log.txt already exists; leaving as-is."
fi

echo ">>> Marking helper scripts as executable (if present)..."
for script in run.sh scrape.sh generate_calllist.sh; do
    if [ -f "${ROOT_DIR}/${script}" ]; then
        chmod +x "${ROOT_DIR}/${script}" || true
        echo "Marked ${script} as executable."
    fi
done

echo ">>> Installation/bootstrap complete."
echo "You can now run the scraping workflow as described in README.md."
