#!/bin/bash
# CHP Post-Deploy Hook
# Installed to .chp/cicd-hooks/post-deploy.sh
# Runs after deployment completes - may trigger rollback but always exits cleanly

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
exec "$PROJECT_ROOT/core/dispatcher.sh" post-deploy "$@"

# May trigger rollback but always exits cleanly
