#!/usr/bin/env bash
# CHP post-response Hook — installed to .claude/hooks/post-response
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" post-response "$@"
