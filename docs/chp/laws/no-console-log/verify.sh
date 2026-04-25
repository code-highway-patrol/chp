#!/bin/bash
# Verification script for law: no-console-log

# Get the absolute path to CHP base directory
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

# Source CHP common functions
source "$CHP_BASE/core/common.sh"

# Main verification logic
verify_law() {
    local law_name="no-console-log"

    log_info "Verifying law: no-console-log"

    # Get list of staged files
    local staged_files=$(git diff --cached --name-only --diff-filter=ACM)

    if [ -z "$staged_files" ]; then
        log_info "No staged files to check"
        return 0
    fi

    # File extensions to skip (documentation, config, data files)
    local skip_pattern='\.(md|json|txt|sh|yml|yaml|lock|gitignore)$'

    # Check each staged file
    local violations=0
    local violating_files=()

    while IFS= read -r file; do
        # Skip files that match the skip pattern
        if echo "$file" | grep -qE "$skip_pattern"; then
            continue
        fi

        # Check if file still exists (might have been deleted)
        if [ ! -f "$file" ]; then
            continue
        fi

        # Check for console.log in the staged version of the file
        if git diff --cached "$file" | grep -q 'console\.log'; then
            violations=$((violations + 1))
            violating_files+=("$file")
        fi
    done <<< "$staged_files"

    if [ $violations -gt 0 ]; then
        log_error "console.log detected in $violations staged file(s)"
        log_error "Violating files:"
        for file in "${violating_files[@]}"; do
            log_error "  - $file"
        done
        log_error ""
        log_error "Please remove console.log statements before committing."
        log_error "Use proper logging libraries or remove debug statements."
        log_error "For guidance, see: docs/chp/laws/no-console-log/guidance.md"
        return 1
    fi

    log_info "Law verification passed: no-console-log"
    return 0
}

# Run verification
verify_law
exit $?
