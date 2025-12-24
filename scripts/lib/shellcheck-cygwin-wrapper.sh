#!/bin/sh
# scripts/lib/shellcheck-cygwin-wrapper.sh
# A thin wrapper that converts POSIX paths to Windows paths before calling
# a Windows-installed shellcheck (useful under Cygwin when shellcheck.exe is
# installed via Scoop/Chocolatey).
# Usage: put this directory earlier in PATH so `shellcheck` resolves to this
# wrapper, or call it explicitly. It respects the SHELLCHECK environment
# variable if set to point to the real executable.

set -eu

# Determine target shellcheck binary
SC_BIN="${SHELLCHECK:-}"
if [ -z "$SC_BIN" ]; then
  # Try to discover Windows-installed shellcheck using 'where' via cmd.exe
  if command -v cmd.exe >/dev/null 2>&1; then
    # The output uses CRLF; strip CR and take the first line
    winpath="$(cmd.exe /c "where shellcheck" 2>/dev/null | tr -d '\r' | sed -n '1p' || true)"
    if [ -n "$winpath" ]; then
      # Convert to POSIX path
      if command -v cygpath >/dev/null 2>&1; then
        SC_BIN="$(cygpath -u "$winpath")"
      else
        SC_BIN="$winpath"
      fi
    fi
  fi
fi

# Fallback to a system shellcheck (if not a Windows exe)
if [ -z "$SC_BIN" ]; then
  SC_BIN="$(command -v shellcheck 2>/dev/null || true)"
fi

if [ -z "$SC_BIN" ]; then
  echo "Error: shellcheck binary not found. Install ShellCheck or set SHELLCHECK to its path." >&2
  exit 127
fi

# Build converted args: convert file args to Windows paths when appropriate
TMPARGS="$(mktemp)"
cleanup() {
  rm -f "$TMPARGS"
}
trap cleanup EXIT

for a in "$@"; do
  case "$a" in
    -) printf '%s\n' "$a" >> "$TMPARGS" ;; # stdin
    -*) printf '%s\n' "$a" >> "$TMPARGS" ;; # option
    *)
      if [ -e "$a" ] && command -v cygpath >/dev/null 2>&1; then
        # convert to Windows path
        w=$(cygpath -w "$a" 2>/dev/null || true)
        if [ -n "$w" ]; then
          printf '%s\n' "$w" >> "$TMPARGS"
        else
          printf '%s\n' "$a" >> "$TMPARGS"
        fi
      else
        printf '%s\n' "$a" >> "$TMPARGS"
      fi
      ;;
  esac
done

# Rebuild positional args safely
set --
while IFS= read -r l; do
  set -- "$@" "$l"
done < "$TMPARGS"

exec "$SC_BIN" "$@"
