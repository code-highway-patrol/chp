#!/usr/bin/env bash
# verify.sh for no-console-log law
# Exits 0 if no console.log found, 1 if violations detected

set -euo pipefail

# Get the directory of this script
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAW_JSON="$LAW_DIR/law.json"

# Get the repository root using git
if git rev-parse --git-dir >/dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
else
    # Fallback: go up 4 levels from law directory
    REPO_ROOT="$(cd "$LAW_DIR/../../.." && pwd)"
fi

# Source the common library
source "$REPO_ROOT/core/common.sh"

# Get include/exclude patterns from law.json
INCLUDE_PATTERNS=($(jq -r '.include[]? // empty' "$LAW_JSON"))
EXCLUDE_PATTERNS=($(jq -r '.exclude[]? // empty' "$LAW_JSON"))

# Get staged files (or all files if not in git context)
FILES_TO_CHECK=()
if git rev-parse --git-dir >/dev/null 2>&1; then
    # In a git repo - check staged files
    while IFS= read -r -d '' file; do
        FILES_TO_CHECK+=("$file")
    done < <(git diff --cached --name-only -z --diff-filter=ACM | grep -z '\.js$\|\.ts$\|\.jsx$\|\.tsx$\|\.mjs$\|\.cjs$' || true)
else
    # Not in git - check all matching files
    for pattern in "${INCLUDE_PATTERNS[@]}"; do
        while IFS= read -r -d '' file; do
            FILES_TO_CHECK+=("$file")
        done < <(find . -name "$pattern" -print0 2>/dev/null || true)
    done
fi

VIOLATIONS=0

for file in "${FILES_TO_CHECK[@]}"; do
    # Skip excluded patterns
    skip=false
    for exclude in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$file" == $exclude ]]; then
            skip=true
            break
        fi
    done
    $skip && continue

    # Check for console.log
    if grep -q 'console\.log' "$file" 2>/dev/null; then
        echo "❌ VIOLATION: console.log found in $file"
        grep -n 'console\.log' "$file" | sed 's/^/   /'
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
done

if [[ $VIOLATIONS -gt 0 ]]; then
    echo ""
    echo "Found $VIOLATIONS file(s) with console.log statements."
    echo "Use logger.info(), logger.error(), or logger.debug() instead."
    exit 1
fi

exit 0
