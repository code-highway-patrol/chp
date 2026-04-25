#!/bin/bash
# CHP Pre-Tool Hook
# Installed to .claude/hooks/pre-tool.sh
# Runs before each tool invocation - can block tool execution

# CHP-MANAGED

# Calculate CHP_BASE from .claude/hooks going up to repo root
CHP_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$CHP_BASE/core/dispatcher.sh" pre-tool "$@"

exit $?
