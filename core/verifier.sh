#!/bin/bash
# Verification runner for CHP laws

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/tightener.sh"

# Source logger
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Initialize logger
logger_init

# Check if a file path matches a glob pattern
# Args: pattern, file_path
matches_glob() {
    local pattern="$1"
    local file_path="$2"

    # Normalize paths to use forward slashes
    pattern="${pattern//\//}"
    file_path="${file_path//\//}"

    # Use case pattern matching for glob support
    # This handles *, ?, and ** patterns natively
    case "$file_path" in
        $pattern)
            return 0
            ;;
    esac
    return 1
}

# Check if a file path matches any of the given patterns
# Args: file_path, json_array_of_patterns
matches_any_pattern() {
    local file_path="$1"
    local patterns_json="$2"

    # If patterns array is empty, return true (matches all)
    if [[ -z "$patterns_json" ]] || [[ "$patterns_json" == "null" ]]; then
        return 0
    fi

    # Iterate through patterns
    local pattern
    while IFS= read -r pattern; do
        pattern=$(echo "$pattern" | tr -d '\r"')
        if [[ -n "$pattern" ]] && matches_glob "$pattern" "$file_path"; then
            return 0
        fi
    done < <(echo "$patterns_json" | jq -r '.[]? // empty' 2>/dev/null)

    return 1
}

# Check if a file is within a law's scope
# Args: file_path, law_json_path
check_file_scope() {
    local file_path="$1"
    local law_json="$2"

    # Check include patterns
    local include_patterns
    include_patterns=$(jq -r '.include // empty' "$law_json" 2>/dev/null)

    if [[ -n "$include_patterns" ]] && [[ "$include_patterns" != "null" ]]; then
        # If include is specified, file must match at least one pattern
        if ! matches_any_pattern "$file_path" "$include_patterns"; then
            return 1  # Not in scope
        fi
    fi

    # Check exclude patterns (overrides include)
    local exclude_patterns
    exclude_patterns=$(jq -r '.exclude // empty' "$law_json" 2>/dev/null)

    if [[ -n "$exclude_patterns" ]] && [[ "$exclude_patterns" != "null" ]]; then
        # If file matches any exclude pattern, it's out of scope
        if matches_any_pattern "$file_path" "$exclude_patterns"; then
            return 1  # Excluded from scope
        fi
    fi

    return 0  # In scope
}

# Get affected files for a hook type
# Args: hook_type
get_affected_files() {
    local hook_type="$1"

    case "$hook_type" in
        pre-commit)
            git diff --cached --name-only
            ;;
        pre-push)
            # Check if upstream branch exists
            if git rev-parse @{u} >/dev/null 2>&1; then
                git diff --name-only HEAD @{u}
            else
                git diff --name-only HEAD^..HEAD
            fi
            ;;
        post-commit)
            # Files just committed
            git diff --name-only HEAD^..HEAD
            ;;
        *)
            # For other hooks, return empty (no file context)
            echo ""
            ;;
    esac
}

# Check if a law should run based on file scope
# Args: law_json_path, hook_type
check_law_scope() {
    local law_json="$1"
    local hook_type="$2"

    # Get affected files for this hook
    local affected_files
    affected_files=$(get_affected_files "$hook_type")

    # If no files affected (or hook type doesn't have file context), check if law has scope restrictions
    if [[ -z "$affected_files" ]]; then
        # For hooks without file context (like pre-tool), we can't filter by scope
        # So we run the law if it has no include patterns (meaning it applies globally)
        local include_patterns
        include_patterns=$(jq -r '.include // empty' "$law_json" 2>/dev/null)

        if [[ -z "$include_patterns" ]] || [[ "$include_patterns" == "null" ]] || [[ "$include_patterns" == "[]" ]]; then
            return 0  # No scope restriction, run the law
        else
            # Law has scope restrictions but we can't check them
            log_warn "Hook '$hook_type' has no file context, cannot filter by scope for $(jq -r '.id // .name' "$law_json"), running anyway"
            return 0
        fi
    fi

    # Check each affected file
    local file_count=0
    local in_scope_count=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        ((file_count++))

        if check_file_scope "$file" "$law_json"; then
            ((in_scope_count++))
        fi
    done <<< "$affected_files"

    # Only run law if at least one file is in scope
    if [[ $in_scope_count -gt 0 ]]; then
        log_debug "Law scope: $in_scope_count/$file_count files affected"
        return 0
    else
        log_debug "Law scope: No affected files match law's include/exclude patterns, skipping"
        return 1
    fi
}

# Verify a single law
verify_law() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    local law_dir="$LAWS_DIR/$law_name"
    local law_json="$law_dir/law.json"
    local verify_script="$law_dir/verify.sh"

    # Check if law is enabled
    local enabled
    enabled=$(jq -r 'if has("enabled") then .enabled else "true" end' "$law_json" 2>/dev/null)

    if [[ "$enabled" != "true" ]]; then
        log_info "Law is disabled, skipping verification: $law_name"
        return 0
    fi

    if [[ ! -f "$verify_script" ]]; then
        log_error "Verification script not found: $verify_script"
        return 1
    fi

    if [[ ! -x "$verify_script" ]]; then
        log_error "Verification script not executable: $verify_script"
        return 1
    fi

    # Run the verification script
    if bash "$verify_script"; then
        # Log successful evaluation
        logger_evaluation "$law_name" "verification" "passed"
        return 0
    else
        local exit_code=$?
        # Log failed evaluation as violation
        logger_violation "$law_name" "verification" "failed" "verification-script" "fix the issue reported by verify.sh"
        # Record the failure and trigger tightening
        record_failure "$law_name"
        return $exit_code
    fi
}

# Verify all laws for a specific hook
verify_hook_laws() {
    local hook_type="$1"

    if [[ -z "$hook_type" ]]; then
        log_error "Hook type is required"
        return 1
    fi

    # Log hook trigger
    local law_list=$(find "$LAWS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ',' | sed 's/,$//')
    logger_hook_trigger "$hook_type" "$law_list"

    local overall_result=0

    # Find all laws that apply to this hook
    for law_dir in "$LAWS_DIR"/*; do
        if [[ -d "$law_dir" ]]; then
            local law_name=$(basename "$law_dir")
            local law_json="$law_dir/law.json"

            if [[ -f "$law_json" ]]; then
                # Check if this law is enabled
                local enabled
                enabled=$(jq -r 'if has("enabled") then .enabled else "true" end' "$law_json" 2>/dev/null)

                if [[ "$enabled" != "true" ]]; then
                    # Skip disabled laws
                    continue
                fi

                # Check if this law applies to the hook
                local hooks
                hooks=$(jq -r '.hooks[]? // empty' "$law_json" 2>/dev/null)

                # Strip carriage returns and check for exact match
                if echo "$hooks" | tr -d '\r' | grep -qx "${hook_type}"; then
                    # Check if any affected files are within the law's scope
                    if check_law_scope "$law_json" "$hook_type"; then
                        # Verify this law
                        if ! verify_law "$law_name"; then
                            overall_result=1
                        fi
                    fi
                fi
            fi
        fi
    done

    return $overall_result
}

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [[ -z "$1" ]]; then
        log_error "Usage: $0 <law-name|hook-type>"
        exit 1
    fi

    # Check if first arg is a law name or hook type
    if law_exists "$1"; then
        verify_law "$1"
    else
        verify_hook_laws "$1"
    fi
fi
