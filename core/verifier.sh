#!/bin/bash
# Verification runner for CHP laws

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/tightener.sh"

# Verify a single law
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

    # Check if law is enabled
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

    # Run the verification script
    if bash "$verify_script"; then
        return 0
    else
        local exit_code=$?
        # Record the failure and trigger tightening
        record_failure "$law_name"
        return $exit_code
    fi
}

# Verify all laws for a specific hook
verify_hook_laws() {
    local hook_type="$1"

    if [[ -z "$hook_type" ]]; then
        log_error "Hook type is required"
        return 1
    fi

    local overall_result=0

    # Find all laws that apply to this hook
    for law_dir in "$LAWS_DIR"/*; do
        if [[ -d "$law_dir" ]]; then
            local law_name=$(basename "$law_dir")
            local law_json="$law_dir/law.json"

            if [[ -f "$law_json" ]]; then
                # Check if this law is enabled
                local enabled
                enabled=$(jq -r 'if has("enabled") then .enabled else "true" end' "$law_json" 2>/dev/null)

                if [[ "$enabled" != "true" ]]; then
                    # Skip disabled laws
                    continue
                fi

                # Check if this law applies to the hook
                local hooks
                hooks=$(jq -r '.hooks[]? // empty' "$law_json" 2>/dev/null)

                if echo "$hooks" | grep -q "^${hook_type}$"; then
                    # Verify this law
                    if ! verify_law "$law_name"; then
                        overall_result=1
                    fi
                fi
            fi
        fi
    done

    return $overall_result
}

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [[ -z "$1" ]]; then
        log_error "Usage: $0 <law-name|hook-type>"
        exit 1
    fi

    # Check if first arg is a law name or hook type
    if law_exists "$1"; then
        verify_law "$1"
    else
        verify_hook_laws "$1"
    fi
fi
