#!/bin/bash
# CHP Pre-Push Hook
# Installed to .git/hooks/pre-push
# Runs before pushes are sent to remote

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-push "$@"

exit $?
