#!/bin/bash
# CHP Pre-Rebase Hook
# Installed to .git/hooks/pre-rebase
# Runs before a rebase operation

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-rebase "$@"

exit $?
