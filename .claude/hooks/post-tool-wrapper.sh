#!/bin/bash
# CHP Post-Tool Hook Wrapper
# Reads JSON input from Claude Code harness and calls the CHP dispatcher

# Read JSON input from stdin
HOOK_INPUT=$(cat)

# Extract relevant fields using jq
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$HOOK_INPUT" | jq -r '.tool_input.content // empty')
TOOL_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_output // empty')

# Export for verify.sh scripts
export CHP_HOOK_TYPE="post-tool"
export CHP_TOOL_NAME="$TOOL_NAME"
export CHP_FILE_PATH="$FILE_PATH"
export CHP_CONTENT="$CONTENT"
export CHP_TOOL_OUTPUT="$TOOL_OUTPUT"

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Call the CHP dispatcher with the tool context
exec "$PROJECT_ROOT/core/dispatcher.sh" post-tool "$TOOL_NAME" "$FILE_PATH" "$CONTENT"
