#!/bin/bash
# CHP Update Hook
# Installed to .git/hooks/update
# Runs on remote repository when updates are pushed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" update "$@"

exit $?
