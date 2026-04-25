#!/bin/bash
# Central Hook Dispatcher - Routes hook events to registered laws

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/hook-registry.sh"
source "$SCRIPT_DIR/verifier.sh"

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
        mapfile -t law_names < <(jq -r '.[]' <<<"$laws" | tr -d '\r')
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
        if "$verify_script" "${hook_args[@]}"; then
            log_debug "Law '$law_name' passed"
            ((passed++))
        else
            local exit_code=$?
            log_error "Law '$law_name' failed with exit code $exit_code"
            ((failed++))

            if command -v record_failure >/dev/null 2>&1; then
                record_failure "$law_name"
            fi
        fi
    done

    echo ""
    log_info "Hook '$hook_type' complete: passed: $passed, failed: $failed"

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
