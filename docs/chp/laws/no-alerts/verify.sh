#!/bin/bash
# Verification script for law: no-alerts

# Get the absolute path to CHP base directory
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

# Source CHP common functions
source "$CHP_BASE/core/common.sh"

# Main verification logic
verify_law() {
    local law_name="no-alerts"

    log_info "Verifying law: no-alerts"

    # Pattern to detect: alert\(
    PATTERNS=(
        "alert\("
    )

    # File types to check: *.js,*.ts,*.tsx
    FILES=$(git diff --cached --name-only | grep -E '\.(js|ts|tsx)$' || true)

    if [ -z "$FILES" ]; then
        log_info "No matching files to check"
        return 0
    fi

    for pattern in "${PATTERNS[@]}"; do
        if echo "$FILES" | xargs grep -n "$pattern" 2>/dev/null; then
            log_error "alert() call found in staged files"
            return 1
        fi
    done

    log_info "Law verification passed: no-alerts"
    return 0
}

# Run verification
verify_law
exit $?
