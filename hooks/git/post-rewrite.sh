#!/usr/bin/env bash
# CHP Post-Rewrite Hook
# Installed to .git/hooks/post-rewrite
# Runs after commands that rewrite git history (rebase, commit --amend)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-rewrite "$@"

# Always allow rewrite to succeed
