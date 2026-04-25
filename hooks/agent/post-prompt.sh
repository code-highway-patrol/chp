#!/bin/bash
# CHP Post-Prompt Hook
# Installed to .claude/hooks/post-prompt.sh
# Runs after each user prompt is processed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-prompt "$@"

# Always allow continuation
exit 0
