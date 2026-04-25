#!/usr/bin/env bash
# Tightening logic for law violations

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly." >&2
    echo "Usage: source core/tightener.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/law-mutate.sh"

record_failure() {
    local law_name="$1"
    local check_id="${2:-}"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    mutate_failure "$law_name" "$check_id"

    local failures
    failures=$(get_law_meta "$law_name" "failures")
    local tightening_level
    tightening_level=$(get_law_meta "$law_name" "tightening_level")

    if [[ -n "$check_id" ]]; then
        log_warn "Law '$law_name' check '$check_id' failed (failure #$failures, tightening level $tightening_level)"
    else
        log_warn "Law '$law_name' failed (failure #$failures, tightening level $tightening_level)"
    fi

    logger_init
    logger_violation "$law_name" "tightening" "failed" "violation-trend" "address the pattern causing repeated violations"

    return 0
}

reset_failures() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    mutate_reset "$law_name"

    log_info "Law '$law_name' reset (failures and tightening level cleared)"

    return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    record_failure "$1"
fi
