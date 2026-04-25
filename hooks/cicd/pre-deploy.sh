#!/bin/bash
# CHP Pre-Deploy Hook
# Installed to .chp/cicd-hooks/pre-deploy.sh
# Runs before deployment starts - blocking (can block deployment on failure)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" pre-deploy "$@"

