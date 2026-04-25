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
    local guidance_md="$law_dir/guidance.md"

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

    # Check for auto-disable threshold
    local threshold="${CHP_AUTO_DISABLE_THRESHOLD:-5}"
    if [[ "$failures" -ge "$threshold" ]]; then
        jq '.enabled = false' "$law_json" > "${law_json}.tmp" && \
        mv "${law_json}.tmp" "$law_json"
        log_error "[AUTO-DISABLED] Law '$law_name' exceeded failure threshold ($failures >= $threshold)"
    fi

    # Append violation history to guidance file
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat >> "$guidance_md" <<EOF

---

**Violation recorded:** $timestamp (Total: $failures)

This law has been violated $failures time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**
EOF

    log_warn "Law '$law_name' failed (failure #$failures, tightening level $tightening_level)"

    return 0
}

# Reset failures for a law
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

    local law_dir="$LAWS_DIR/$law_name"
    local law_json="$law_dir/law.json"
    local guidance_md="$law_dir/guidance.md"

    # Reset failure count and tightening level
    jq '.failures = 0 | .tightening_level = 0' \
       "$law_json" > "${law_json}.tmp" && \
    mv "${law_json}.tmp" "$law_json"

    # Truncate guidance file to remove violation history
    if grep -q "^---" "$guidance_md"; then
        sed -n '1,/^---$/p' "$guidance_md" > "$guidance_md.tmp"
        mv "$guidance_md.tmp" "$guidance_md"
    fi

    log_info "Law '$law_name' reset (failures and tightening level cleared)"

    return 0
}

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    record_failure "$1"
fi
