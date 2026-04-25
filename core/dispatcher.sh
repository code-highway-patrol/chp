#!/usr/bin/env bash
# Central Hook Dispatcher - Routes hook events to registered laws

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/hook-registry.sh"
source "$SCRIPT_DIR/verifier.sh"
source "$SCRIPT_DIR/check-runner.sh"

if [ -f "$SCRIPT_DIR/tightener.sh" ]; then
    source "$SCRIPT_DIR/tightener.sh"
fi

get_hook_context() {
    local hook_type="$1"

    case "$hook_type" in
        pre-commit)
            echo "git diff --cached --name-only"
            ;;
        pre-push)
            if git rev-parse @{u} >/dev/null 2>&1; then
                echo "git diff --name-only HEAD @{u}"
            else
                echo "git diff --name-only HEAD^..HEAD"
            fi
            ;;
        commit-msg)
            echo ".git/COMMIT_EDITMSG"
            ;;
        pre-tool)
            echo "tool_context"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Record failures per check from JSONL output, falling back to law-level
_record_check_failures() {
    local law_name="$1"
    local stdout="$2"

    local has_check_results=false
    if [[ -n "$stdout" ]]; then
        while IFS= read -r line; do
            local check_id status
            check_id=$(echo "$line" | jq -r '.check_id // empty' 2>/dev/null)
            status=$(echo "$line" | jq -r '.status // empty' 2>/dev/null)
            if [[ -n "$check_id" ]]; then
                has_check_results=true
                if [[ "$status" == "FAIL" ]]; then
                    record_failure "$law_name" "$check_id"
                fi
            fi
        done <<< "$stdout"
    fi

    if ! $has_check_results; then
        record_failure "$law_name"
    fi
}

# Args: $1=hook_type, $@=hook_args
# Returns: 0=all passed, 1=blocking failure, 2=dispatcher error
dispatch_hook() {
    local hook_type="$1"
    shift
    local hook_args=("$@")

    if [ -z "$hook_type" ]; then
        log_error "Hook type is required"
        return 2
    fi

    log_debug "Dispatching hook: $hook_type"

    if ! is_hook_enabled "$hook_type"; then
        log_debug "Hook '$hook_type' is disabled, skipping"
        return 0
    fi

    # Discover laws: prefer registry, fall back to scanning law.json files
    local law_names=()

    local laws
    laws=$(get_hook_laws "$hook_type")
    if [ -n "$laws" ] && [ "$laws" != "[]" ]; then
        while IFS= read -r line; do
            law_names+=("$line")
        done < <(jq -r '.[]' <<<"$laws" | tr -d '\r')
    fi

    # If registry was empty/stale, discover from law.json files directly
    if [ ${#law_names[@]} -eq 0 ]; then
        for law_dir in "$LAWS_DIR"/*; do
            [ ! -d "$law_dir" ] && continue
            local law_json="$law_dir/law.json"
            [ ! -f "$law_json" ] && continue
            if jq -r '.hooks[]?' "$law_json" 2>/dev/null | tr -d '\r' | grep -qx "$hook_type"; then
                law_names+=("$(basename "$law_dir")")
            fi
        done
    fi

    if [ ${#law_names[@]} -eq 0 ]; then
        log_debug "No laws found for hook '$hook_type'"
        return 0
    fi

    log_debug "Found ${#law_names[@]} law(s) registered for hook '$hook_type'"

    local passed=0
    local failed=0
    local -a passing_contexts=()

    for law_name in "${law_names[@]}"; do
        local law_dir="$LAWS_DIR/$law_name"
        local law_json="$law_dir/law.json"
        local verify_script="$law_dir/verify.sh"

        log_debug "Processing law: $law_name"

        if [ ! -d "$law_dir" ]; then
            log_warn "Law directory not found: $law_dir"
            continue
        fi

        if [ ! -f "$law_json" ]; then
            log_warn "law.json not found for law: $law_name"
            continue
        fi

        local enabled
        enabled=$(jq -r 'if has("enabled") then .enabled else "true" end' "$law_json" 2>/dev/null)

        if [[ "$enabled" != "true" ]]; then
            log_debug "Law '$law_name' is disabled, skipping"
            continue
        fi

        if ! check_law_scope "$law_json" "$hook_type"; then
            log_debug "Law '$law_name' has no affected files in scope, skipping"
            continue
        fi

        if [ ! -f "$verify_script" ]; then
            log_warn "verify.sh not found for law: $law_name"
            continue
        fi

        if [ ! -x "$verify_script" ]; then
            log_warn "verify.sh not executable for law: $law_name, attempting to execute anyway"
        fi

        log_debug "Running verify script for law: $law_name"
        local verify_exit=0
        local verify_stdout=""
        if [ -n "$CHP_TOOL_INPUT" ]; then
            verify_stdout=$(echo "$CHP_TOOL_INPUT" | "$verify_script" "${hook_args[@]}" 2>/dev/null)
            verify_exit=$?
        else
            verify_stdout=$("$verify_script" "${hook_args[@]}" 2>/dev/null)
            verify_exit=$?
        fi
        if [ $verify_exit -eq 0 ]; then
            log_debug "Law '$law_name' passed"
            ((passed++))
            # Accumulate additionalContext from passing laws
            if [ -n "$verify_stdout" ] && [[ "$hook_type" == "pre-tool" ]]; then
                passing_contexts+=("$verify_stdout")
            fi
        else
            log_error "Law '$law_name' failed with exit code $verify_exit"
            ((failed++))

            # For pre-tool hooks, output only the block JSON and stop
            if [[ "$hook_type" == "pre-tool" || "$hook_type" == "pre-write" ]]; then
                echo "$verify_stdout"
                if command -v record_failure >/dev/null 2>&1; then
                    _record_check_failures "$law_name" "$verify_stdout" >&2
                fi
                return 1
            fi

            if command -v _record_check_failures >/dev/null 2>&1; then
                _record_check_failures "$law_name" "$verify_stdout"
            elif command -v record_failure >/dev/null 2>&1; then
                record_failure "$law_name"
            fi
        fi
    done

    # For pre-tool hooks with no failures, output accumulated context
    if [[ "$hook_type" == "pre-tool" ]] && [ ${#passing_contexts[@]} -gt 0 ]; then
        printf '%s\n' "${passing_contexts[@]}"
    fi

    log_info "Hook '$hook_type' complete: passed: $passed, failed: $failed" >&2

    # Pre-tool and pre-write hooks always block on failure
    local should_block=false
    if [[ "$hook_type" == "pre-tool" || "$hook_type" == "pre-write" ]]; then
        should_block=true
    elif is_hook_blocking "$hook_type"; then
        should_block=true
    fi

    if $should_block && [ $failed -gt 0 ]; then
        log_error "Blocking hook '$hook_type' had $failed failure(s)"
        return 1
    fi

    return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <hook_type> [hook_args...]"
        exit 2
    fi

    dispatch_hook "$@"
    exit $?
fi
