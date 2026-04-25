#!/bin/bash
# CHP Post-Commit Hook
# Installed to .git/hooks/post-commit
# Runs after a commit has been made

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-commit "$@"

# Always allow commit to succeed
