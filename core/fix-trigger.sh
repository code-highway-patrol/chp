#!/usr/bin/env bash
# Fix Trigger - Invokes Claude to fix violations after verification failure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/logger.sh"

logger_init

# Usage: trigger_fix <law_name> <hook_type> [hook_args...]
trigger_fix() {
    local law_name="$1"
    local hook_type="$2"
    shift 2

    local law_dir="$LAWS_DIR/$law_name"
    local law_json="$law_dir/law.json"
    local guidance_md="$law_dir/guidance.md"

    if [[ ! -f "$law_json" ]]; then
        log_error "Law not found: $law_name"
        return 1
    fi

    # Check autoFix mode
    local auto_fix
    auto_fix=$(jq -r '.autoFix // "never"' "$law_json" 2>/dev/null)

    if [[ "$auto_fix" == "never" ]]; then
        log_debug "Law '$law_name' has autoFix: never, skipping fix flow"
        return 0
    fi

    if [[ ! -f "$guidance_md" ]]; then
        log_warn "No guidance.md found for law: $law_name, cannot auto-fix"
        return 0
    fi

    log_info "Auto-fix available for law '$law_name' (mode: $auto_fix)"

    # Export context for the agent
    export CHP_FIX_LAW_NAME="$law_name"
    export CHP_FIX_MODE="$auto_fix"
    export CHP_FIX_HOOK_TYPE="$hook_type"
    export CHP_FIX_LAW_DIR="$law_dir"
    export CHP_FIX_GUIDANCE="$guidance_md"

    # Get affected files for context
    local affected_files=""
    case "$hook_type" in
        pre-commit)
            affected_files=$(git diff --cached --name-only 2>/dev/null | tr '\n' ' ')
            ;;
        pre-push|post-commit)
            if git rev-parse @{u} >/dev/null 2>&1; then
                affected_files=$(git diff --name-only HEAD @{u} 2>/dev/null | tr '\n' ' ')
            else
                affected_files=$(git diff --name-only HEAD^..HEAD 2>/dev/null | tr '\n' ' ')
            fi
            ;;
    esac
    export CHP_FIX_FILES="$affected_files"

    # Log the fix trigger attempt before any early returns
    logger_log "fix_trigger" "law_name" "$law_name" "mode" "$auto_fix" "hook_type" "$hook_type"

    # Look for fixer agent prompt
    local fixer_prompt="$CHP_BASE/agents/fixer.md"
    if [[ ! -f "$fixer_prompt" ]]; then
        log_warn "Fixer agent prompt not found at $fixer_prompt"
        return 0
    fi

    # Read and output the fixer prompt for Claude to see
    cat "$fixer_prompt"

    return 0
}

# If run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [[ $# -lt 2 ]]; then
        log_error "Usage: $0 <law_name> <hook_type> [hook_args...]"
        exit 1
    fi

    trigger_fix "$@"
    exit $?
fi
