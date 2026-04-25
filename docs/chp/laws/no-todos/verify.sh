#!/bin/bash
# Verification script for law: no-todos

# Get the absolute path to CHP base directory
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

# Source CHP common functions
source "$CHP_BASE/core/common.sh"

# Main verification logic
verify_law() {
    local law_name="no-todos"
    local violations=0

    log_info "Verifying law: no-todos"

    # Determine which files to check based on hook context
    local files_to_check=""
    if [ -n "$CHP_HOOK_CONTEXT" ]; then
        # Hook context provides files
        files_to_check="$CHP_HOOK_CONTEXT"
    else
        # Fall back to git staged files
        files_to_check=$(git diff --cached --name-only 2>/dev/null)
    fi

    # Check for TODO/FIXME/HACK comments
    if [ -n "$files_to_check" ]; then
        while IFS= read -r file; do
            [ -z "$file" ] && continue
            [ ! -f "$file" ] && continue

            # Skip certain file patterns
            [[ "$file" =~ \.(min\.(js|css)|map|lock)$ ]] && continue
            [[ "$file" =~ node_modules/|vendor/|\.git/ ]] && continue

            # Check for TODO/FIXME/HACK comments (case insensitive)
            if grep -iE 'TODO|FIXME|HACK|XXX|NOTE' "$file" >/dev/null 2>&1; then
                log_error "TODO/FIXME/HACK comment found in: $file"
                violations=$((violations + 1))
            fi
        done <<< "$files_to_check"
    fi

    if [ $violations -gt 0 ]; then
        log_error "Found $violations file(s) with TODO comments"
        return 1
    fi

    log_info "Law verification passed: no-todos"
    return 0
}

# Run verification
verify_law
exit $?
