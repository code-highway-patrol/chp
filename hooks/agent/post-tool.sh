#!/bin/bash
# CHP Post-Tool Hook
# Installed to .claude/hooks/post-tool.sh
# Runs after each tool invocation completes

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-tool "$@"

# Always allow continuation
exit 0
