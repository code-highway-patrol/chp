#!/bin/bash
# CHP Post-Tool Hook
# Installed to .claude/hooks/post-tool.sh
# Runs after each tool invocation completes

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-tool "$@"

# Always allow continuation
