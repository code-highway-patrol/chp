#!/bin/bash
# CHP post-tool Hook Wrapper
# Reads JSON input from Claude Code harness and calls the CHP dispatcher

HOOK_INPUT=$(cat)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$HOOK_INPUT" | jq -r '.tool_input.content // empty')
TOOL_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_output // empty')

export CHP_HOOK_TYPE="post-tool"
export CHP_TOOL_NAME="$TOOL_NAME"
export CHP_FILE_PATH="$FILE_PATH"
export CHP_CONTENT="$CONTENT"
export CHP_TOOL_OUTPUT="$TOOL_OUTPUT"

# Resolve CHP_BASE: env var, then settings.json, then relative fallback
if [[ -n "$CHP_BASE" ]]; then
    : # CHP_BASE already set
elif [[ -f "$HOME/.claude/settings.json" ]]; then
    CHP_BASE=$(jq -r '.extraKnownMarketplaces["chp-local"].source.path // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi

# Final fallback to relative path (only works if CHP core is in project root)
if [[ -z "$CHP_BASE" ]] || [[ ! -f "$CHP_BASE/core/dispatcher.sh" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    if [[ -f "$PROJECT_ROOT/core/dispatcher.sh" ]]; then
        CHP_BASE="$PROJECT_ROOT"
    fi
fi

if [[ -z "$CHP_BASE" ]] || [[ ! -f "$CHP_BASE/core/dispatcher.sh" ]]; then
    echo "Error: Cannot find CHP dispatcher (core/dispatcher.sh)" >&2
    echo "Set CHP_BASE environment variable or ensure CHP is installed" >&2
    exit 1
fi

exec "$CHP_BASE/core/dispatcher.sh" post-tool "$TOOL_NAME" "$FILE_PATH" "$CONTENT"
