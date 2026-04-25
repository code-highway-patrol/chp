#!/bin/bash
# CHP Post-Checkout Hook
# Installed to .git/hooks/post-checkout
# Runs after a checkout operation

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-checkout "$@"

# Always allow checkout to succeed
