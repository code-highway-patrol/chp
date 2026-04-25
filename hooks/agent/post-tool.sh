#!/bin/bash
# CHP Post-Tool Hook
# Installed to .claude/hooks/post-tool.sh
# Runs after each tool invocation completes

# CHP-MANAGED

# Calculate CHP_BASE from .claude/hooks going up to repo root
CHP_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Log tool execution for audit purposes
if [ -n "$TOOL_NAME" ]; then
    echo "[CHP POST-TOOL] Tool executed: $TOOL_NAME"
fi

# Source dispatcher for any post-tool law validations
source "$CHP_BASE/core/dispatcher.sh" post-tool "$@"

# Log completion
if [ -n "$TOOL_NAME" ]; then
    echo "[CHP POST-TOOL] Completed: $TOOL_NAME"
fi

# Always allow continuation
exit 0
