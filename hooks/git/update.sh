#!/usr/bin/env bash
# CHP update Hook — installed to .git/hooks/update
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" update "$@"
