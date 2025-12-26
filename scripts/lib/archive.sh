#!/bin/sh
# scripts/lib/archive.sh
# Provides: archive_artifacts <paths...>
# Archives provided paths into a timestamped tar.gz under SNAPSHOT_DIR (default .snapshots)
# Writes checksum (.sha1), index entry and updates .snapshots/latest symlink

set -eu

archive_artifacts() {
  # Usage: archive_artifacts [--description "text"] <path> [<path> ...]
  desc=""
  paths=""
  # parse optional args (very small parser)
  while [ $# -gt 0 ]; do
    case "$1" in
      --description)
        shift
        desc="$1"
        ;;
      --) shift; break;;
      -*) echo "ERROR: unknown option: $1" >&2; return 2;;
      *) paths="$paths $1";;
    esac
    shift
  done

  # Default snapshot dir
  SNAP_DIR="${SNAPSHOT_DIR:-.snapshots}"

  mkdir -p "$SNAP_DIR/checksums"

  if [ -z "$paths" ]; then
    echo "ERROR: archive_artifacts requires at least one path" >&2
    return 2
  fi

  # Build list of existing items (skip non-existing)
  to_archive=""
  for p in $paths; do
    if [ -e "$p" ]; then
      to_archive="$to_archive $p"
    else
      echo "WARN: skipping missing path: $p" >&2
    fi
  done

  if [ -z "$to_archive" ]; then
    echo "ERROR: no valid paths to archive" >&2
    return 3
  fi

  ts=$(date -u +%Y%m%dT%H%M%SZ)
  snapshot_name="snap-$ts.tar.gz"
  snapshot_path="$SNAP_DIR/$snapshot_name"

  # Create tarball (preserve file ownership and permissions as much as possible)
  # Use positional parameters to expand multiple paths safely in POSIX sh
  # Build positional parameters explicitly to avoid word-splitting/globbing issues
  set --
  for p in $to_archive; do
    set -- "$@" "$p"
  done
  tar -czf "$snapshot_path" "$@"

  # Compute checksum using available tool
  if command -v sha1sum >/dev/null 2>&1; then
    # Write in standard sha1sum output format: "<hash>  <filename>"
    (cd "$SNAP_DIR" && sha1sum "${snapshot_name}") > "$SNAP_DIR/checksums/${snapshot_name}.sha1"
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$SNAP_DIR" && shasum -a1 "${snapshot_name}") > "$SNAP_DIR/checksums/${snapshot_name}.sha1"
  else
    # Fallback to openssl - produce "<hash>  <filename>"
    if command -v openssl >/dev/null 2>&1; then
      hex=$(openssl dgst -sha1 "$snapshot_path" | awk '{print $2}')
      echo "$hex  ${snapshot_name}" > "$SNAP_DIR/checksums/${snapshot_name}.sha1"
    else
      echo "WARN: no checksum utility found; skipping checksum generation" >&2
    fi
  fi

  # Append index entry
  idx_file="$SNAP_DIR/index"
  echo "$snapshot_name | $ts | ${desc:-no-description}" >> "$idx_file"

  # Update latest symlink (replace)
  ln -sf "$snapshot_name" "$SNAP_DIR/latest"

  echo "$snapshot_path"
}

# Allow this file to be sourced or executed as a small CLI
if [ "${0##*/}" = "archive.sh" ]; then
  # Called as script
  # Usage: scripts/lib/archive.sh [--description "desc"] <paths...>
  archive_artifacts "$@"
fi
