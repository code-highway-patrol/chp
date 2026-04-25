#!/usr/bin/env bash
# Agent checker — subjective checks that output prompts for AI judgment

# Usage: check_agent <hook_type> <config_json> <context_file>
# config_json: {"prompt": "Are these variable names meaningful?"}
# Returns: PASS:{json} with additionalContext for agent hooks, or SKIP for git hooks

check_agent() {
    local hook_type="$1"
    local config_json="$2"
    local context_file="$3"

    local prompt
    prompt=$(echo "$config_json" | jq -r '.prompt // empty')

    if [[ -z "$prompt" ]]; then
        echo "SKIP:agent:no-prompt"
        return 0
    fi

    # Agent hooks: pre-tool, post-tool, pre-prompt, post-prompt, pre-response, post-response
    case "$hook_type" in
        pre-tool|post-tool|pre-prompt|post-prompt|pre-response|post-response)
            # Output PASS with additionalContext containing the prompt
            local result_json
            result_json=$(jq -n \
                --arg prompt "$prompt" \
                '{additionalContext: $prompt}')
            echo "PASS:${result_json}"
            return 0
            ;;
        *)
            # Git hooks: skip silently (can't judge subjectively without an AI)
            echo "SKIP:agent:non-agent-context"
            return 0
            ;;
    esac
}
