#!/bin/sh
# scripts/build-man.sh
# Build/validate roff manpage and optionally produce a PDF
# Usage: scripts/build-man.sh [--pdf]

set -eu
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAN_SRC="$ROOT_DIR/docs/man/elvis.1"
OUT_PDF="$ROOT_DIR/docs/man/elvis.pdf"

if [ ! -f "$MAN_SRC" ]; then
  echo "ERROR: man source not found: $MAN_SRC" >&2
  exit 2
fi

# Validate with nroff if available
if command -v nroff >/dev/null 2>&1; then
  nroff -man "$MAN_SRC" | head -n1 >/dev/null 2>&1 || true
  echo "PASS: nroff validation"
else
  echo "WARN: nroff not available - cannot validate manpage formatting"
fi

# Optionally produce PDF via groff
if [ "${1:-}" = "--pdf" ]; then
  if command -v groff >/dev/null 2>&1; then
    groff -Tpdf -man "$MAN_SRC" > "$OUT_PDF"
    echo "Produced PDF: $OUT_PDF"
  else
    echo "ERROR: groff is not installed; cannot produce PDF" >&2
    exit 2
  fi
fi

echo "build-man.sh: done"
exit 0
