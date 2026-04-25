#!/bin/bash
# Central Hook Dispatcher - Routes hook events to registered laws
#
# This module is responsible for dispatching hook events (like pre-commit, pre-tool)
# to the laws that should run when those hooks are triggered. It uses the hook
# registry to find which laws to execute.

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/hook-registry.sh"
source "$SCRIPT_DIR/verifier.sh"

# Source tightener.sh if available (for failure recording)
if [ -f "$SCRIPT_DIR/tightener.sh" ]; then
    source "$SCRIPT_DIR/tightener.sh"
fi

# Get the git command for retrieving context based on hook type
get_hook_context() {
    local hook_type="$1"

    case "$hook_type" in
        pre-commit)
            echo "git diff --cached --name-only"
            ;;
        pre-push)
            # Check if upstream branch exists, fall back to comparing against nothing
            if git rev-parse @{u} >/dev/null 2>&1; then
                echo "git diff --name-only HEAD @{u}"
            else
                echo "git diff --name-only HEAD^..HEAD"
            fi
            ;;
        commit-msg)
            echo ".git/COMMIT_EDITMSG"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Dispatch a hook event to all registered laws
#
# Args:
#   $1 - hook_type: The type of hook being dispatched (e.g., pre-commit, pre-tool)
#   $@ - hook_args: Additional arguments to pass to verify.sh scripts
#
# Returns:
#   0 - All laws passed or hook is non-blocking
#   1 - A blocking hook had failures
#   2 - Dispatcher error (invalid input, etc.)
dispatch_hook() {
    local hook_type="$1"
    shift
    local hook_args=("$@")

    # Validate hook type
    if [ -z "$hook_type" ]; then
        log_error "Hook type is required"
        return 2
    fi

    log_debug "Dispatching hook: $hook_type"

    # Check if hook is enabled
    if ! is_hook_enabled "$hook_type"; then
        log_debug "Hook '$hook_type' is disabled, skipping"
        return 0
    fi

    # Get laws registered for this hook
    local laws
    laws=$(get_hook_laws "$hook_type")

    # Parse laws into array efficiently
    local law_names=()
    if [ -n "$laws" ]; then
        mapfile -t law_names < <(jq -r '.[]' <<<"$laws" | tr -d '\r')
    fi

    # If no laws registered, nothing to do
    if [ ${#law_names[@]} -eq 0 ]; then
        log_debug "No laws registered for hook '$hook_type'"
        return 0
    fi

    log_debug "Found ${#law_names[@]} law(s) registered for hook '$hook_type'"

    # Track results
    local passed=0
    local failed=0

    # Execute each law's verify.sh
    for law_name in "${law_names[@]}"; do
        local law_dir="$LAWS_DIR/$law_name"
        local law_json="$law_dir/law.json"
        local verify_script="$law_dir/verify.sh"

        log_debug "Processing law: $law_name"

        # Check if law directory exists
        if [ ! -d "$law_dir" ]; then
            log_warn "Law directory not found: $law_dir"
            continue
        fi

        # Check if law.json exists
        if [ ! -f "$law_json" ]; then
            log_warn "law.json not found for law: $law_name"
            continue
        fi

        # Check if law is enabled
        local enabled
        enabled=$(jq -r 'if has("enabled") then .enabled else "true" end' "$law_json" 2>/dev/null)

        if [[ "$enabled" != "true" ]]; then
            log_debug "Law '$law_name' is disabled, skipping"
            continue
        fi

        # Check if any affected files are within the law's scope
        if ! check_law_scope "$law_json" "$hook_type"; then
            log_debug "Law '$law_name' has no affected files in scope, skipping"
            continue
        fi

        # Check if verify.sh exists
        if [ ! -f "$verify_script" ]; then
            log_warn "verify.sh not found for law: $law_name"
            continue
        fi

        # Ensure verify.sh is executable
        if [ ! -x "$verify_script" ]; then
            log_warn "verify.sh not executable for law: $law_name, attempting to execute anyway"
        fi

        # Run the verify script with hook arguments
        log_debug "Running verify script for law: $law_name"
        if "$verify_script" "${hook_args[@]}"; then
            log_debug "Law '$law_name' passed"
            ((passed++))
        else
            local exit_code=$?
            log_error "Law '$law_name' failed with exit code $exit_code"
            ((failed++))

            # Record failure if tightener is available
            if command -v record_failure >/dev/null 2>&1; then
                record_failure "$law_name"
            fi
        fi
    done

    # Output summary
    echo ""
    log_info "Hook '$hook_type' complete: passed: $passed, failed: $failed"

    # Check if hook is blocking
    if is_hook_blocking "$hook_type"; then
        if [ $failed -gt 0 ]; then
            log_error "Blocking hook '$hook_type' had failures"
            return 1
        fi
    fi

    return 0
}

# Main entry point
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    # When run directly, take hook_type as first argument
    # and pass remaining arguments to dispatch_hook
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <hook_type> [hook_args...]"
        exit 2
    fi

    dispatch_hook "$@"
    exit $?
fi
