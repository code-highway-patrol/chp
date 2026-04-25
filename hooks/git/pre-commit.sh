#!/bin/bash
# CHP Pre-Commit Hook
# Installed to .git/hooks/pre-commit
# Runs before a commit is created

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-commit "$@"

# Exit with dispatcher's exit code
exit $?
