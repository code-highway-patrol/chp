#!/bin/bash
# CHP Post-Build Hook
# Installed to CI/CD pipeline after build
# Runs after build process completes

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-build "$@"

# Always allow continuation
