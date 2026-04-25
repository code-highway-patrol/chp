#!/bin/bash
# Parallel Law Execution Runner
#
# This module provides parallel execution of laws for improved performance.
# It runs multiple verify.sh scripts concurrently and aggregates their results.

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Source hook-registry.sh for law directory resolution
if [ -f "$SCRIPT_DIR/hook-registry.sh" ]; then
    source "$SCRIPT_DIR/hook-registry.sh"
fi

# Source tightener.sh if available (for failure recording)
if [ -f "$SCRIPT_DIR/tightener.sh" ]; then
    source "$SCRIPT_DIR/tightener.sh"
fi

# Run multiple laws in parallel
#
# Args:
#   $1 - hook_type: The type of hook being dispatched
#   $@ - hook_args: Additional arguments to pass to verify.sh scripts
#
# Returns:
#   0 - All laws passed
#   1 - Any law failed
run_laws_parallel() {
    local hook_type="$1"
    shift
    local hook_args=("$@")

    # Get laws registered for this hook
    local laws
    laws=$(get_hook_laws "$hook_type")

    # Parse laws into array
    local law_names=()
    if [ -n "$laws" ]; then
        mapfile -t law_names < <(jq -r '.[]' <<<"$laws" | tr -d '\r')
    fi

    # If no laws registered, nothing to do
    if [ ${#law_names[@]} -eq 0 ]; then
        log_debug "No laws registered for hook '$hook_type'"
        return 0
    fi

    log_debug "Running ${#law_names[@]} law(s) in parallel for hook '$hook_type'"

    # Arrays to track results and background jobs
    local -A law_exit_codes
    local pids=()
    local failed=0
    local passed=0

    # Launch all verify scripts in background
    for law_name in "${law_names[@]}"; do
        local law_dir="$LAWS_DIR/$law_name"
        local verify_script="$law_dir/verify.sh"

        # Check if law directory exists
        if [ ! -d "$law_dir" ]; then
            log_warn "Law directory not found: $law_dir"
            continue
        fi

        # Check if verify.sh exists
        if [ ! -f "$verify_script" ]; then
            log_warn "verify.sh not found for law: $law_name"
            continue
        fi

        log_debug "Starting verify script for law: $law_name (parallel)"

        # Run verify script in background
        "$verify_script" "${hook_args[@]}" &
        local pid=$!
        pids+=($pid)
        law_exit_codes[$pid]=$law_name
    done

    # Wait for all background jobs to complete
    for pid in "${pids[@]}"; do
        local law_name="${law_exit_codes[$pid]}"
        if wait $pid; then
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
    log_info "Hook '$hook_type' parallel run complete: passed: $passed, failed: $failed"

    if [ $failed -gt 0 ]; then
        return 1
    fi

    return 0
}