#!/bin/sh
# scripts/update_readme.sh
# Regenerate the auto-generated README sections (project tree and commands)
# Usage: scripts/update_readme.sh [--dry-run]

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT_DIR/README.md"
TMPFILE="/tmp/update_readme.$$"
DRY_RUN=false

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

# Generate a compact textual tree (top-level + one-level children)
generate_text_tree() {
  printf '.\n'
  for entry in "$ROOT_DIR"/*; do
    name=$(basename "$entry")
    if [ -d "$entry" ]; then
      printf '├── %s\n' "$name"
      # list a few children (files only, up to 6)
      i=0
      for child in "$entry"/*; do
        [ -e "$child" ] || break
        childname=$(basename "$child")
        printf '│   ├── %s\n' "$childname"
        i=$((i+1))
        [ "$i" -ge 6 ] && break
      done
    else
      printf '├── %s\n' "$name"
    fi
  done
}

# Generate commands list (bin and top-level scripts)
generate_commands_list() {
  printf '### Commands\n\n'

  if [ -x "$ROOT_DIR/bin/elvis-run" ]; then
    printf '%s\n' '- `bin/elvis-run` — master orchestrator (see `bin/elvis-run help`)'
  fi

  for sh in "$ROOT_DIR"/scripts/*.sh; do
    [ -e "$sh" ] || continue
    name=$(basename "$sh")
    # Prefer the first comment line (but skip shebang lines) as the short description
    desc=$(awk -v name="$name" 'NR<=12 { if ($0 ~ /^#!/) next; if ($0 ~ /^#/) { line=$0; sub(/^#\s?/, "", line); if (line == name) next; print line; exit } }' "$sh" || true)
    [ -n "$desc" ] || desc="Shell script"
    printf '%s\n' '- `scripts/'"$name"'` — '"${desc}"
  done
}

# Build the generated block
gen_block() {
  cat <<'EOF'
<!-- AUTO-GENERATED-PROJECT-TREE:START -->
A generated project scaffold (updated by `scripts/update_readme.sh`) — do not edit manually.

```mermaid
flowchart TB
  %% Top-level project layout (folders & key files)
  subgraph ROOT["."]
    direction TB
    editorconfig[".editorconfig"]
    gitattributes[".gitattributes"]
    gitignore[".gitignore"]
    envfile[".env"]
    configs_root["project.conf (primary) / seek-pagination.ini"]
    license["LICENSE"]
    readme["README.md"]
    seeds["seeds.csv"]
    history["companies_history.txt"]

    subgraph BIN["bin/"]
      bin_run["elvis-run"]
    end

    subgraph SCRIPTS["scripts/"]
      run_sh["run.sh"]
      fetch_sh["fetch.sh"]
      parse_sh["parse.sh"]
      dedupe_sh["dedupe.sh"]
      validate_sh["validate.sh"]
      enrich_sh["enrich.sh"]
      subgraph LIB["scripts/lib/"]
        http_utils["http_utils.sh"]
      end
    end

    subgraph CONFIGS["configs/"]
      seek_ini["seek-pagination.ini"]
    end

    subgraph DOCS["docs/"]
      runbook["runbook.md"]
      subgraph MAN["docs/man/"]
        manpage["elvis.1"]
      end
    end

    subgraph DATA["data/"]
      calllists["calllists/"]
      seeds_data["seeds/"]
    end

    logs["logs/"]
    tmp["tmp/"]
    examples["examples/"]
    github[".github/"]
    cron["cron/"]
    tests["tests/"]
  end
```

```text
<!-- AUTO-GENERATED-PROJECT-TREE:TEXT-START -->
EOF

  # Insert generated text tree
  generate_text_tree

  cat <<'EOF'
<!-- AUTO-GENERATED-PROJECT-TREE:TEXT-END -->
```

<!-- AUTO-GENERATED-PROJECT-TREE:END -->
EOF

  # Commands list
  generate_commands_list
}

# Replace between markers using perl (preserve everything else)
replace_readme() {
  newcontent=$(mktemp)
  gen_block > "$newcontent"
  # Replace the section between markers using awk to avoid quoting issues
  awk -v newfile="$newcontent" '{
    if ($0 ~ /<!-- AUTO-GENERATED-PROJECT-TREE:START -->/) {
      while ((getline line < newfile) > 0) print line;
      skip = 1; next
    }
    if (skip && $0 ~ /<!-- AUTO-GENERATED-PROJECT-TREE:END -->/) { skip = 0; next }
    if (!skip) print
  }' "$README" > "$TMPFILE"

  if [ "$DRY_RUN" = "true" ]; then
    cat "$TMPFILE"
  else
    mv "$TMPFILE" "$README"
    echo "Updated $README"
  fi
  rm -f "$newcontent"
}

# Basic validations
if [ ! -f "$README" ]; then
  echo "ERROR: README.md not found in $ROOT_DIR" >&2
  exit 2
fi

replace_readme

exit 0
