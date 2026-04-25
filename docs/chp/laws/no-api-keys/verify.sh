#!/bin/bash
# Verification script for law: no-api-keys

# Get the absolute path to CHP base directory
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

# Source CHP common functions
source "$CHP_BASE/core/common.sh"

# Main verification logic
verify_law() {
    local law_name="no-api-keys"

    log_info "Verifying law: no-api-keys"

    # Get list of staged files
    local staged_files=$(git diff --cached --name-only --diff-filter=ACM)

    if [ -z "$staged_files" ]; then
        log_info "No staged files to check"
        return 0
    fi

    # API key patterns to detect (these are common patterns, not actual keys)
    local patterns=(
        "sk-[a-zA-Z0-9]{32,}"           # Stripe keys
        "AIza[0-9A-Za-z\\-_]{35}"       # Google API keys
        "AKIA[0-9A-Z]{16}"             # AWS access keys
        "ghp_[a-zA-Z0-9]{36}"          # GitHub personal access tokens
        "gho_[a-zA-Z0-9]{36}"          # GitHub OAuth tokens
        "ghu_[a-zA-Z0-9]{36}"          # GitHub user tokens
        "ghs_[a-zA-Z0-9]{36}"          # GitHub server tokens
        "ghr_[a-zA-Z0-9]{36}"          # GitHub refresh tokens
        "xoxb-[0-9]{11,13}-[0-9]{11,13}-[a-zA-Z0-9]{24}" # Slack bot tokens
        "xoxp-[0-9]{11,13}-[0-9]{11,13}-[0-9]{12}-[a-zA-Z0-9]{32}" # Slack user tokens
    )

    # Check each staged file
    local violations=0
    local violating_files=()

    while IFS= read -r file; do
        # Check if file still exists (might have been deleted)
        if [ ! -f "$file" ]; then
            continue
        fi

        # Skip binary files and certain file types
        if [[ "$file" =~ \.(png|jpg|jpeg|gif|ico|pdf|zip|tar|gz|lock)$ ]]; then
            continue
        fi

        # Check for API key patterns in the staged version
        local staged_content=$(git diff --cached "$file" | grep -E '^\+')

        for pattern in "${patterns[@]}"; do
            if echo "$staged_content" | grep -qE "$pattern"; then
                violations=$((violations + 1))
                violating_files+=("$file")
                break  # Count each file only once
            fi
        done
    done <<< "$staged_files"

    if [ $violations -gt 0 ]; then
        log_error "Potential API keys detected in $violations staged file(s)"
        log_error "Violating files:"
        for file in "${violating_files[@]}"; do
            log_error "  - $file"
        done
        log_error ""
        log_error "Please remove API keys before committing."
        log_error "Use environment variables or secret management systems instead."
        log_error "For guidance, see: docs/chp/laws/no-api-keys/guidance.md"
        return 1
    fi

    log_info "Law verification passed: no-api-keys"
    return 0
}

# Run verification
verify_law
exit $?
