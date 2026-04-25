#!/bin/bash
# CHP Post-Rewrite Hook
# Installed to .git/hooks/post-rewrite
# Runs after commands that rewrite git history (rebase, commit --amend)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-rewrite "$@"

# Always allow rewrite to succeed
exit 0
