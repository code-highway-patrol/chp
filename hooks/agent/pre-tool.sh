#!/bin/bash
# CHP Pre-Tool Hook
# Installed to .claude/hooks/pre-tool.sh
# Runs before each tool invocation - can block tool execution

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-tool "$@"

exit $?
