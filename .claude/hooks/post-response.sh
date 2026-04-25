#!/bin/bash
# CHP Post-Response Hook
# Installed to .claude/hooks/post-response.sh
# Runs after response is sent to user

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-response "$@"

# Always allow continuation
exit 0
