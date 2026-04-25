#!/bin/bash
# CHP Pre-Response Hook
# Installed to .claude/hooks/pre-response.sh
# Runs before response is sent to user - can trigger regeneration

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-response "$@"

exit $?
