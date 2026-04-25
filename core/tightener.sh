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

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    local failures
    failures=$(get_law_meta "$law_name" "failures")
    failures=$((failures + 1))

    local tightening_level
    tightening_level=$(get_law_meta "$law_name" "tightening_level")
    tightening_level=$((tightening_level + 1))

    jq --arg failures "$failures" \
       --arg tightening_level "$tightening_level" \
       '.failures = ($failures | tonumber) |
        .tightening_level = ($tightening_level | tonumber)' \
       "$law_json" > "${law_json}.tmp" && \
    mv "${law_json}.tmp" "$law_json"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local check_label=""
    if [[ -n "$check_id" ]]; then
        check_label=" (check: $check_id)"
    fi

    cat >> "$guidance_md" <<EOF

---

**Violation recorded:** $timestamp (Total: $failures)${check_label}

This law has been violated $failures time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**
EOF

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

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    jq '.failures = 0 | .tightening_level = 0' \
       "$law_json" > "${law_json}.tmp" && \
    mv "${law_json}.tmp" "$law_json"

    if grep -q "^---" "$guidance_md"; then
        sed -n '1,/^---$/p' "$guidance_md" > "$guidance_md.tmp"
        mv "$guidance_md.tmp" "$guidance_md"
    fi

    log_info "Law '$law_name' reset (failures and tightening level cleared)"

    return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    record_failure "$1"
fi
