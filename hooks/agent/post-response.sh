#!/usr/bin/env bash
# CHP Post-Response Hook
# Installed to .claude/hooks/post-response.sh
# Runs after response is sent to user

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-response "$@"

# Always allow continuation
