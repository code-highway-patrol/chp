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
    local hook_type="${1:-}"

    log_info "Verifying law: no-api-keys"

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

    local violations=0
    local violating_files=()
    local files_to_check=()

    # Detect context and get files to check
    if [[ "$hook_type" == "pre-tool" || "$hook_type" == "post-tool" ]]; then
        # Use env vars exported by the wrapper (CHP_TOOL_NAME, CHP_FILE_PATH, CHP_CONTENT)
        local tool_name="${CHP_TOOL_NAME:-}"
        local file_path="${CHP_FILE_PATH:-}"
        local content="${CHP_CONTENT:-}"

        if [[ -n "$file_path" && -n "$content" ]]; then
            files_to_check=("$file_path")
            # Write content to a temp file for pattern matching
            local tmp_content
            tmp_content=$(mktemp_chp "chp-content-XXXXXX")
            printf '%s' "$content" > "$tmp_content"
            export CHP_TOOL_CONTENT="$tmp_content"
        else
            log_info "No tool context provided, checking all files"
            # Fall back to checking all tracked files
            files_to_check=($(git ls-files))
        fi
    else
        # Git context: check staged files
        local staged_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

        if [ -z "$staged_files" ]; then
            log_info "No staged files to check"
            return 0
        fi

        while IFS= read -r file; do
            files_to_check+=("$file")
        done <<< "$staged_files"
    fi

    # Check each file
    for file in "${files_to_check[@]}"; do
        # For tool hooks, the file may not exist yet (it's the target of Write/Edit)
        if [[ "$hook_type" != "pre-tool" && "$hook_type" != "post-tool" ]]; then
            # Check if file still exists (might have been deleted)
            if [ ! -f "$file" ]; then
                continue
            fi

            # Skip binary files and certain file types
            if [[ "$file" =~ \.(png|jpg|jpeg|gif|ico|pdf|zip|tar|gz|lock)$ ]]; then
                continue
            fi
        fi

        # Get content to check
        local content_to_check=""
        if [[ ("$hook_type" == "pre-tool" || "$hook_type" == "post-tool") && -n "$CHP_TOOL_CONTENT" ]]; then
            content_to_check=$(cat "$CHP_TOOL_CONTENT" 2>/dev/null || echo "")
            rm -f "$CHP_TOOL_CONTENT" 2>/dev/null
            unset CHP_TOOL_CONTENT
            # For pre-tool, only check the provided content — skip if empty
            if [[ -z "$content_to_check" ]]; then
                continue
            fi
        else
            # For git context, check only staged changes
            content_to_check=$(git diff --cached "$file" 2>/dev/null | grep -E '^\+' || echo "")
        fi

        # If no staged content, check full file for new files
        if [[ -z "$content_to_check" ]]; then
            content_to_check=$(cat "$file" 2>/dev/null || echo "")
        fi

        # Check for API key patterns
        for pattern in "${patterns[@]}"; do
            if echo "$content_to_check" | grep -qE "$pattern"; then
                violations=$((violations + 1))
                violating_files+=("$file")
                break  # Count each file only once
            fi
        done
    done

    if [ $violations -gt 0 ]; then
        log_error "Potential API keys detected in $violations file(s)"
        log_error "Violating files:"
        for file in "${violating_files[@]}"; do
            log_error "  - $file"
        done
        log_error ""
        log_error "Please remove API keys before proceeding."
        log_error "Use environment variables or secret management systems instead."
        log_error "For guidance, see: docs/chp/laws/no-api-keys/guidance.md"
        return 1
    fi

    log_info "Law verification passed: no-api-keys"
    return 0
}

# Run verification - pass hook type from environment or argument
HOOK_TYPE="${CHP_HOOK_TYPE:-$1}"
verify_law "$HOOK_TYPE"
exit $?
