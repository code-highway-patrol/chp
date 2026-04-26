#!/usr/bin/env bash
# CHP pre-auto-gc Hook — installed to .git/hooks/pre-auto-gc
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" pre-auto-gc "$@"
