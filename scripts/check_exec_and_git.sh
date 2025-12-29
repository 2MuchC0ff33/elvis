#!/bin/sh

# Directories to check
DIRS="bin lib etc scripts"

# File extensions to check
EXTS="sh awk sed"

# Find matching files
find_files() {
    for dir in $DIRS; do
        for ext in $EXTS; do
            find "$dir" -type f -name "*.$ext" 2>/dev/null
        done
    done
}

# Check and fix executable permissions
fix_permissions() {
    for file in $(find_files); do
        if [ ! -x "$file" ]; then
            echo "Setting executable permission: $file"
            chmod +x "$file"
        fi
    done
}

# Check and fix git index permissions
fix_git_index() {
    for file in $(find_files); do
        # Check if file is tracked by git
        if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            # Check if git index has executable bit
            if ! git ls-files --stage "$file" | grep -qE '100755'; then
                echo "Updating git index for executable: $file"
                git update-index --chmod=+x "$file"
            fi
        fi
    done
}

fix_permissions
fix_git_index
