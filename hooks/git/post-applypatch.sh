#!/usr/bin/env bash
# CHP post-applypatch Hook — installed to .git/hooks/post-applypatch
# CHP-MANAGED

CHP_BASE="${CHP_BASE:-__CHP_BASE_DEFAULT__}"
exec "$CHP_BASE/core/dispatcher.sh" post-applypatch "$@"
