#!/usr/bin/env bash
# CHP-Codex Bridge - Translates Codex hook protocol to CHP dispatcher calls
# Installed to .codex/hooks/chp-bridge.sh
# Called by Codex hooks defined in .codex/config.toml
#
# Codex sends JSON on stdin, expects JSON on stdout for decisions.
# This bridge parses Codex input, calls CHP's dispatcher.sh,
# and translates results back to Codex's expected format.

# CHP-MANAGED

CODEX_INPUT=$(cat)
CHP_EVENT="$1"

# Resolve project root (bridge is at .codex/hooks/ → project root is ../..)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DISPATCHER="$PROJECT_ROOT/core/dispatcher.sh"

# Bail if dispatcher not found
if [[ ! -f "$DISPATCHER" ]]; then
    exit 0
fi

case "$CHP_EVENT" in
    pre-tool)
        export CHP_TOOL_INPUT=$(echo "$CODEX_INPUT" | jq -c '.tool_input // empty' 2>/dev/null)
        export CHP_TOOL_NAME=$(echo "$CODEX_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

        verify_stdout=$("$DISPATCHER" pre-tool 2>/dev/null)
        verify_exit=$?

        if [[ $verify_exit -ne 0 ]]; then
            reason="${verify_stdout:-CHP law violation detected}"
            jq -n --arg reason "$reason" '{
                hookSpecificOutput: {
                    hookEventName: "PreToolUse",
                    permissionDecision: "deny",
                    permissionDecisionReason: $reason
                }
            }'
        elif [[ -n "$verify_stdout" ]]; then
            jq -n --arg ctx "$verify_stdout" '{
                hookSpecificOutput: {
                    hookEventName: "PreToolUse",
                    additionalContext: $ctx
                }
            }'
        fi
        ;;

    post-tool)
        export CHP_TOOL_INPUT=$(echo "$CODEX_INPUT" | jq -c '.tool_input // empty' 2>/dev/null)
        export CHP_TOOL_NAME=$(echo "$CODEX_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

        "$DISPATCHER" post-tool >/dev/null 2>&1
        ;;

    pre-prompt)
        export CHP_PROMPT=$(echo "$CODEX_INPUT" | jq -r '.prompt // empty' 2>/dev/null)

        verify_stdout=$("$DISPATCHER" pre-prompt 2>/dev/null)
        verify_exit=$?

        if [[ $verify_exit -ne 0 ]]; then
            reason="${verify_stdout:-CHP law violation detected}"
            jq -n --arg reason "$reason" '{
                hookSpecificOutput: {
                    hookEventName: "UserPromptSubmit",
                    permissionDecision: "deny",
                    permissionDecisionReason: $reason
                }
            }'
        elif [[ -n "$verify_stdout" ]]; then
            jq -n --arg ctx "$verify_stdout" '{
                hookSpecificOutput: {
                    hookEventName: "UserPromptSubmit",
                    additionalContext: $ctx
                }
            }'
        fi
        ;;

    post-response)
        verify_stdout=$("$DISPATCHER" post-response 2>/dev/null)
        verify_exit=$?

        if [[ $verify_exit -ne 0 ]]; then
            reason="${verify_stdout:-CHP law violation detected}"
            jq -n --arg reason "$reason" '{
                hookSpecificOutput: {
                    hookEventName: "Stop",
                    decision: "block",
                    reason: $reason
                }
            }'
        fi
        ;;

    *)
        ;;
esac

exit 0
