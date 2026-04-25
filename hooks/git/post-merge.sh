#!/bin/bash
# CHP Post-Merge Hook
# Installed to .git/hooks/post-merge
# Runs after a merge has been completed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-merge "$@"

# Always allow merge to succeed
exit 0
