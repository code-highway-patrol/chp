#!/usr/bin/env bash
# CHP post-prompt Hook — installed to .claude/hooks/post-prompt
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" post-prompt "$@"
