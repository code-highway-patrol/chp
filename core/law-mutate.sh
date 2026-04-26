#!/bin/bash
# law-mutate.sh — Atomic mutation layer for CHP law files
# Ensures law.json, verify.sh, and guidance.md are always updated together.

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly." >&2
    echo "Usage: source core/law-mutate.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/law-builder.sh"

# validate_consistency <law_name>
# Read-only check that all three law files agree.
# Returns 0 if consistent, 1 if drifted.
validate_consistency() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "validate_consistency: law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "validate_consistency: law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    # Check all three files exist
    if [[ ! -f "$law_json" ]]; then
        log_error "validate_consistency: law.json missing for $law_name"
        return 1
    fi
    if [[ ! -f "$guidance_md" ]]; then
        log_error "validate_consistency: guidance.md missing for $law_name"
        return 1
    fi
    if [[ ! -f "$law_dir/verify.sh" ]]; then
        log_error "validate_consistency: verify.sh missing for $law_name"
        return 1
    fi

    # Check law.json name matches directory name
    local json_name
    json_name=$(jq -r '.name // empty' "$law_json" 2>/dev/null)
    if [[ "$json_name" != "$law_name" ]]; then
        log_error "validate_consistency: law.json name '$json_name' does not match directory '$law_name'"
        return 1
    fi

    # Check severity matches guidance.md header
    local json_severity guidance_severity
    json_severity=$(jq -r '.severity // empty' "$law_json" 2>/dev/null)
    guidance_severity=$(sed -n 's/^\*\*Severity:\*\* \(.*\)$/\1/p' "$guidance_md" | head -1)
    if [[ "$json_severity" != "$guidance_severity" ]]; then
        log_error "validate_consistency: severity drift — law.json='$json_severity' guidance.md='$guidance_severity'"
        return 1
    fi

    # Check failures matches guidance.md header
    local json_failures guidance_failures
    json_failures=$(jq -r '.failures // 0' "$law_json" 2>/dev/null)
    guidance_failures=$(sed -n 's/^\*\*Failures:\*\* \(.*\)$/\1/p' "$guidance_md" | head -1)
    if [[ "$json_failures" != "$guidance_failures" ]]; then
        log_error "validate_consistency: failures drift — law.json='$json_failures' guidance.md='$guidance_failures'"
        return 1
    fi

    # Check verify.sh contains check-runner reference if law has checks
    local checks_json
    checks_json=$(jq -c '.checks // []' "$law_json" 2>/dev/null)
    local check_count
    check_count=$(echo "$checks_json" | jq 'length')
    if [[ "$check_count" -gt 0 ]]; then
        if ! grep -q 'check-runner.sh' "$law_dir/verify.sh" 2>/dev/null; then
            log_error "validate_consistency: law has checks but verify.sh does not reference check-runner.sh"
            return 1
        fi
    fi

    return 0
}

# _sync_guidance_header <guidance_md> <field> <value>
# Updates a single header field in guidance.md using sed with atomic write.
_sync_guidance_header() {
    local guidance_md="$1"
    local field="$2"
    local value="$3"

    if [[ ! -f "$guidance_md" ]]; then
        log_error "_sync_guidance_header: file not found: $guidance_md"
        return 1
    fi

    local tmpfile
    tmpfile=$(mktemp_chp "chp_guidance_XXXXXX")

    sed "s|^\*\*$field:\*\* .*|**$field:** $value|" "$guidance_md" > "$tmpfile" && \
    mv "$tmpfile" "$guidance_md"
}

# _append_guidance_entry <guidance_md> <entry_text>
# Appends a changelog entry with timestamp to guidance.md.
_append_guidance_entry() {
    local guidance_md="$1"
    local entry_text="$2"

    if [[ ! -f "$guidance_md" ]]; then
        log_error "_append_guidance_entry: file not found: $guidance_md"
        return 1
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat >> "$guidance_md" <<EOF

---

**$entry_text** $timestamp
EOF
}

# mutate_field <law_name> <field> <value>
# Updates a field in law.json via jq, then syncs guidance.md header for
# severity/failures fields. Regenerates verify.sh if hooks change.
mutate_field() {
    local law_name="$1"
    local field="$2"
    local value="$3"

    if [[ -z "$law_name" ]]; then
        log_error "mutate_field: law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "mutate_field: law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    local tmpfile
    tmpfile=$(mktemp_chp "chp_law_json_XXXXXX")

    if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" == "true" || "$value" == "false" ]]; then
        jq --arg field "$field" --argjson val "$value" '.[$field] = $val' "$law_json" > "$tmpfile" && \
        mv "$tmpfile" "$law_json"
    else
        jq --arg field "$field" --arg val "$value" '.[$field] = $val' "$law_json" > "$tmpfile" && \
        mv "$tmpfile" "$law_json"
    fi

    # Sync guidance.md header for severity and failures
    case "$field" in
        severity)
            _sync_guidance_header "$guidance_md" "Severity" "$value"
            ;;
        failures)
            _sync_guidance_header "$guidance_md" "Failures" "$value"
            ;;
        hooks)
            # Regenerate verify.sh when hooks change
            local checks_json
            checks_json=$(jq -c '.checks // []' "$law_json" 2>/dev/null)
            local check_count
            check_count=$(echo "$checks_json" | jq 'length')
            if [[ "$check_count" -gt 0 ]]; then
                build_verify_with_checks "$law_name" > "$law_dir/verify.sh"
            fi
            ;;
    esac

    log_info "mutate_field: updated $field for law $law_name"
    return 0
}

# mutate_status <law_name> <enabled|disabled>
# Toggles enabled in law.json, appends status change to guidance.md.
mutate_status() {
    local law_name="$1"
    local status="$2"

    if [[ -z "$law_name" ]]; then
        log_error "mutate_status: law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "mutate_status: law does not exist: $law_name"
        return 1
    fi

    if [[ "$status" != "enabled" && "$status" != "disabled" ]]; then
        log_error "mutate_status: status must be 'enabled' or 'disabled', got: $status"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    local enabled_value="true"
    if [[ "$status" == "disabled" ]]; then
        enabled_value="false"
    fi

    local tmpfile
    tmpfile=$(mktemp_chp "chp_law_json_XXXXXX")

    jq --argjson enabled "$enabled_value" '.enabled = $enabled' "$law_json" > "$tmpfile" && \
    mv "$tmpfile" "$law_json"

    _append_guidance_entry "$guidance_md" "Status changed: $status"

    log_info "mutate_status: law $law_name $status"
    return 0
}

# mutate_failure <law_name> [check_id]
# Increments failures/tightening_level in law.json, syncs failures header
# in guidance.md, appends violation entry.
mutate_failure() {
    local law_name="$1"
    local check_id="${2:-}"

    if [[ -z "$law_name" ]]; then
        log_error "mutate_failure: law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "mutate_failure: law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    local failures tightening_level
    failures=$(get_law_meta "$law_name" "failures")
    failures=$((failures + 1))
    tightening_level=$(get_law_meta "$law_name" "tightening_level")
    tightening_level=$((tightening_level + 1))

    local tmpfile
    tmpfile=$(mktemp_chp "chp_law_json_XXXXXX")

    jq --argjson failures "$failures" \
       --argjson tightening_level "$tightening_level" \
       '.failures = $failures | .tightening_level = $tightening_level' \
       "$law_json" > "$tmpfile" && \
    mv "$tmpfile" "$law_json"

    # Sync failures header in guidance.md
    _sync_guidance_header "$guidance_md" "Failures" "$failures"

    # Append violation entry
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
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

    # Log the recorded failure. Severity stays as configured in law.json — this
    # message is bookkeeping for the auto-tightener, not a severity downgrade.
    if [[ -n "$check_id" ]]; then
        log_info "tightener: recorded failure for '$law_name'/'$check_id' (count: $failures, tightening: $tightening_level)"
    else
        log_info "tightener: recorded failure for '$law_name' (count: $failures, tightening: $tightening_level)"
    fi

    return 0
}

# mutate_reset <law_name>
# Sets failures/tightening_level to 0 in law.json, syncs failures header,
# truncates guidance.md violation history at first --- separator.
mutate_reset() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "mutate_reset: law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "mutate_reset: law does not exist: $law_name"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    local tmpfile
    tmpfile=$(mktemp_chp "chp_law_json_XXXXXX")

    jq '.failures = 0 | .tightening_level = 0' \
       "$law_json" > "$tmpfile" && \
    mv "$tmpfile" "$law_json"

    # Sync failures header
    _sync_guidance_header "$guidance_md" "Failures" "0"

    # Truncate violation history at first --- separator
    if grep -q "^---" "$guidance_md"; then
        local trunc_tmp
        trunc_tmp=$(mktemp_chp "chp_guidance_trunc_XXXXXX")
        sed -n '1,/^---$/p' "$guidance_md" > "$trunc_tmp"
        mv "$trunc_tmp" "$guidance_md"
    fi

    log_info "mutate_reset: law '$law_name' reset (failures and tightening level cleared)"
    return 0
}

# mutate_checks <law_name> <action> <check_json>
# Modifies checks array (add/remove/update), regenerates verify.sh via
# build_verify_with_checks, appends changelog entry.
# Actions: add, remove, update
mutate_checks() {
    local law_name="$1"
    local action="$2"
    local check_json="$3"

    if [[ -z "$law_name" ]]; then
        log_error "mutate_checks: law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "mutate_checks: law does not exist: $law_name"
        return 1
    fi

    if [[ "$action" != "add" && "$action" != "remove" && "$action" != "update" ]]; then
        log_error "mutate_checks: action must be add, remove, or update — got: $action"
        return 1
    fi

    read -r law_dir law_json guidance_md < <(get_law_paths "$law_name")

    # Resolve check_json: file path or inline JSON
    local checks_input
    if [[ -f "$check_json" ]]; then
        checks_input=$(cat "$check_json")
    else
        checks_input="$check_json"
    fi

    # Validate the input is valid JSON
    if ! echo "$checks_input" | jq -e . >/dev/null 2>&1; then
        log_error "mutate_checks: invalid JSON for check_json"
        return 1
    fi

    local check_id
    check_id=$(echo "$checks_input" | jq -r '.id // empty' 2>/dev/null)

    local tmpfile
    tmpfile=$(mktemp_chp "chp_law_json_XXXXXX")

    case "$action" in
        add)
            # Append check to the checks array
            jq --argjson check "$checks_input" \
               '.checks = (.checks // [] | . + [$check])' \
               "$law_json" > "$tmpfile" && \
            mv "$tmpfile" "$law_json"
            ;;
        remove)
            if [[ -z "$check_id" ]]; then
                log_error "mutate_checks: remove requires a check with an 'id' field"
                return 1
            fi
            jq --arg id "$check_id" \
               '.checks = (.checks // [] | map(select(.id != $id)))' \
               "$law_json" > "$tmpfile" && \
            mv "$tmpfile" "$law_json"
            ;;
        update)
            if [[ -z "$check_id" ]]; then
                log_error "mutate_checks: update requires a check with an 'id' field"
                return 1
            fi
            jq --arg id "$check_id" --argjson check "$checks_input" \
               '.checks = (.checks // [] | map(if .id == $id then $check else . end))' \
               "$law_json" > "$tmpfile" && \
            mv "$tmpfile" "$law_json"
            ;;
    esac

    # Regenerate verify.sh
    build_verify_with_checks "$law_name" > "$law_dir/verify.sh"

    # Append changelog entry
    _append_guidance_entry "$guidance_md" "Check ${action}d: ${check_id:-unknown}"

    log_info "mutate_checks: $action check '${check_id:-unknown}' for law $law_name"
    return 0
}
