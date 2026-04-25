#!/bin/bash
# CHP Pre-Build Hook
# Installed to .chp/cicd-hooks/pre-build
# Runs before build — blocking

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" pre-build "$@"
