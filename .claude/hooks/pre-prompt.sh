#!/bin/bash
# CHP Pre-Prompt Hook
# Installed to .claude/hooks/pre-prompt.sh
# Runs before each user prompt is processed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-prompt "$@"

exit $?
