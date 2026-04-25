#!/bin/bash
# Tightening logic for law violations

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Record a failure for a law and trigger tightening
record_failure() {
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

    # Increment failure count
    local failures
    failures=$(get_law_meta "$law_name" "failures")
    failures=$((failures + 1))

    # Increment tightening level
    local tightening_level
    tightening_level=$(get_law_meta "$law_name" "tightening_level")
    tightening_level=$((tightening_level + 1))

    # Update law.json
    jq --arg failures "$failures" \
       --arg tightening_level "$tightening_level" \
       '.failures = ($failures | tonumber) |
        .tightening_level = ($tightening_level | tonumber)' \
       "$law_json" > "${law_json}.tmp" && \
    mv "${law_json}.tmp" "$law_json"

    log_info "Law '$law_name' failed (failure #$failures, tightening level $tightening_level)"

    return 0
}

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    record_failure "$1"
fi
