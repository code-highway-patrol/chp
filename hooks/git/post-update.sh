#!/bin/bash
# CHP Post-Update Hook
# Installed to .git/hooks/post-update
# Runs on remote repository after updates have been pushed

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-update "$@"

# Always allow update to succeed
exit 0
