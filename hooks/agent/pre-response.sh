#!/usr/bin/env bash
# CHP pre-response Hook — installed to .claude/hooks/pre-response
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" pre-response "$@"
