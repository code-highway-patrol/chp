#!/bin/bash
# Verification runner for CHP laws

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/tightener.sh"
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

logger_init

# Args: pattern, file_path
matches_glob() {
    local pattern="$1"
    local file_path="$2"

    pattern="${pattern//\//}"
    file_path="${file_path//\//}"

    # case handles *, ?, and ** natively
    case "$file_path" in
        $pattern)
            return 0
            ;;
    esac
    return 1
}

# Args: file_path, json_array_of_patterns
matches_any_pattern() {
    local file_path="$1"
    local patterns_json="$2"

    # Empty patterns = match all
    if [[ -z "$patterns_json" ]] || [[ "$patterns_json" == "null" ]]; then
        return 0
    fi

    local pattern
    while IFS= read -r pattern; do
        pattern=$(echo "$pattern" | tr -d '\r"')
        if [[ -n "$pattern" ]] && matches_glob "$pattern" "$file_path"; then
            return 0
        fi
    done < <(echo "$patterns_json" | jq -r '.[]? // empty' 2>/dev/null)

    return 1
}

# Args: file_path, law_json_path
check_file_scope() {
    local file_path="$1"
    local law_json="$2"

    local include_patterns
    include_patterns=$(jq -r '.include // empty' "$law_json" 2>/dev/null)

    if [[ -n "$include_patterns" ]] && [[ "$include_patterns" != "null" ]]; then
        if ! matches_any_pattern "$file_path" "$include_patterns"; then
            return 1
        fi
    fi

    local exclude_patterns
    exclude_patterns=$(jq -r '.exclude // empty' "$law_json" 2>/dev/null)

    if [[ -n "$exclude_patterns" ]] && [[ "$exclude_patterns" != "null" ]]; then
        if matches_any_pattern "$file_path" "$exclude_patterns"; then
            return 1
        fi
    fi

    return 0
}

# Args: hook_type
get_affected_files() {
    local hook_type="$1"

    case "$hook_type" in
        pre-commit)
            git diff --cached --name-only
            ;;
        pre-push)
            if git rev-parse @{u} >/dev/null 2>&1; then
                git diff --name-only HEAD @{u}
            else
                git diff --name-only HEAD^..HEAD
            fi
            ;;
        post-commit)
            git diff --name-only HEAD^..HEAD
            ;;
        *)
            echo ""
            ;;
    esac
}

# Args: law_json_path, hook_type
check_law_scope() {
    local law_json="$1"
    local hook_type="$2"

    local affected_files
    affected_files=$(get_affected_files "$hook_type")

    if [[ -z "$affected_files" ]]; then
        # Hooks without file context can't filter by scope — run if no include patterns
        local include_patterns
        include_patterns=$(jq -r '.include // empty' "$law_json" 2>/dev/null)

        if [[ -z "$include_patterns" ]] || [[ "$include_patterns" == "null" ]] || [[ "$include_patterns" == "[]" ]]; then
            return 0
        else
            log_warn "Hook '$hook_type' has no file context, cannot filter by scope for $(jq -r '.id // .name' "$law_json"), running anyway"
            return 0
        fi
    fi

    local file_count=0
    local in_scope_count=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        ((file_count++))

        if check_file_scope "$file" "$law_json"; then
            ((in_scope_count++))
        fi
    done <<< "$affected_files"

    if [[ $in_scope_count -gt 0 ]]; then
        log_debug "Law scope: $in_scope_count/$file_count files affected"
        return 0
    else
        log_debug "Law scope: No affected files match law's include/exclude patterns, skipping"
        return 1
    fi
}

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

    if bash "$verify_script"; then
        logger_evaluation "$law_name" "verification" "passed"
        return 0
    else
        local exit_code=$?
        logger_violation "$law_name" "verification" "failed" "verification-script" "fix the issue reported by verify.sh"
        record_failure "$law_name"
        return $exit_code
    fi
}

verify_hook_laws() {
    local hook_type="$1"

    if [[ -z "$hook_type" ]]; then
        log_error "Hook type is required"
        return 1
    fi

    local law_list=$(find "$LAWS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ',' | sed 's/,$//')
    logger_hook_trigger "$hook_type" "$law_list"

    local overall_result=0

    for law_dir in "$LAWS_DIR"/*; do
        if [[ -d "$law_dir" ]]; then
            local law_name=$(basename "$law_dir")
            local law_json="$law_dir/law.json"

            if [[ -f "$law_json" ]]; then
                local enabled
                enabled=$(jq -r 'if has("enabled") then .enabled else "true" end' "$law_json" 2>/dev/null)

                if [[ "$enabled" != "true" ]]; then
                    continue
                fi

                local hooks
                hooks=$(jq -r '.hooks[]? // empty' "$law_json" 2>/dev/null)

                if echo "$hooks" | tr -d '\r' | grep -qx "${hook_type}"; then
                    if check_law_scope "$law_json" "$hook_type"; then
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

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [[ -z "$1" ]]; then
        log_error "Usage: $0 <law-name|hook-type>"
        exit 1
    fi

    if law_exists "$1"; then
        verify_law "$1"
    else
        verify_hook_laws "$1"
    fi
fi
