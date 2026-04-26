#!/usr/bin/env bash
# CHP commit-msg Hook — installed to .git/hooks/commit-msg
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" commit-msg "$@"
