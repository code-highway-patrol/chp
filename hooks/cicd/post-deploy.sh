#!/bin/bash
# CHP Post-Deploy Hook
# Installed to .chp/cicd-hooks/post-deploy.sh
# Runs after deployment completes - may trigger rollback but always exits cleanly

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-deploy "$@"

# May trigger rollback but always exits cleanly
exit 0
