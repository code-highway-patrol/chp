#!/usr/bin/env bash
# CHP Post-Prompt Hook
# Installed to .claude/hooks/post-prompt.sh
# Runs after each user prompt is processed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-prompt "$@"

# Always allow continuation
