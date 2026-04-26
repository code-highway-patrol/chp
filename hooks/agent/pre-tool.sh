#!/usr/bin/env bash
# CHP Pre-Tool Hook
# Installed to .claude/hooks/pre-tool.sh
# Runs before each tool invocation - can block tool execution

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" pre-tool "$@"
