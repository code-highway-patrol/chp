#!/bin/bash
# CHP Commit-Message Hook
# Installed to .git/hooks/commit-msg
# Validates the commit message

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" commit-msg "$@"

exit $?
