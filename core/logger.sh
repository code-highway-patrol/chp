#!/bin/bash
# core/logger.sh - CHP Logging System

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly." >&2
    echo "Usage: source core/logger.sh" >&2
    exit 1
fi

CHP_LOG_DIR=".chp"
CHP_LOG_FILE="$CHP_LOG_DIR/citation.logs.jsonl"

logger_init() {
    mkdir -p "$CHP_LOG_DIR" 2>/dev/null
    touch "$CHP_LOG_FILE" 2>/dev/null
}

_json_escape() {
    local string="$1"
    jq -nr --arg v "$string" '$v'
}

# Usage: logger_log "event_type" "key1" "value1" "key2" "value2" ...
logger_log() {
    local event_type="$1"
    shift

    if [[ ! -f "$CHP_LOG_FILE" ]]; then
        return 0
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local entry="{\"timestamp\":\"$timestamp\",\"event_type\":\"$event_type\""

    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="$2"
        value=$(_json_escape "$value")
        entry="$entry,\"$key\":\"$value\""
        shift 2
    done

    entry="$entry}"
    echo "$entry" >> "$CHP_LOG_FILE" 2>/dev/null
}

# Args: law_id, action, result, pattern, fix, files (optional), hook_type (optional)
logger_violation() {
    local law_id="$1"
    local action="$2"
    local result="$3"
    local pattern="$4"
    local fix="$5"
    local files="${6:-}"
    local hook_type="${7:-}"

    logger_log "violation" \
        "law_id" "$law_id" \
        "action" "$action" \
        "result" "$result" \
        "pattern" "$pattern" \
        "fix" "$fix" \
        "files" "$files" \
        "hook_type" "$hook_type"
}

# Args: law_id, action, result, files (optional)
logger_evaluation() {
    local law_id="$1"
    local action="$2"
    local result="$3"
    local files="${4:-}"

    logger_log "evaluation" \
        "law_id" "$law_id" \
        "action" "$action" \
        "result" "$result" \
        "files" "$files"
}

# Args: hook_type, laws (comma-separated list)
logger_hook_trigger() {
    local hook_type="$1"
    local laws="$2"

    logger_log "hook_trigger" \
        "hook_type" "$hook_type" \
        "laws" "$laws"
}

# Args: hook_type, laws (comma-separated list), action (install/uninstall)
logger_hook_install() {
    local hook_type="$1"
    local laws="$2"
    local action="${3:-install}"

    logger_log "hook_install" \
        "hook_type" "$hook_type" \
        "laws" "$laws" \
        "action" "$action"
}

# Args: law_id, details (JSON string with action, hooks, etc.)
logger_law_change() {
    local law_id="$1"
    local details="$2"

    logger_log "law_change" \
        "law_id" "$law_id" \
        "details" "$details"
}
