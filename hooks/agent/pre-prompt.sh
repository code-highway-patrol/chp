#!/bin/bash
# CHP Pre-Prompt Hook
# Installed to .claude/hooks/pre-prompt.sh
# Runs before each user prompt is processed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" pre-prompt "$@"

# Always allow continuation
