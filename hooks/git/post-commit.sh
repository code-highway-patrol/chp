#!/bin/bash
# CHP Post-Commit Hook
# Installed to .git/hooks/post-commit
# Runs after a commit has been made

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-commit "$@"

# Always allow commit to succeed
exit 0
