#!/usr/bin/env bash
# Pre-push enforcement: when pushing to main, ensure plugin manifest versions
# were bumped in the push range. If not, auto-bump + commit + abort with a
# retry message (pre-push can't append commits to an in-flight push).
#
# Reads pre-push stdin: "<local_ref> <local_sha> <remote_ref> <remote_sha>" per line.
# Exits 0 if no enforcement needed (or version already bumped).
# Exits 1 if it bumped + committed (push must be retried).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_PLUGIN_JSON=".claude-plugin/plugins/chp/plugin.json"
CODEX_PLUGIN_JSON=".codex-plugin/plugins/chp/.codex-plugin/plugin.json"

if [[ ! -f "$REPO_ROOT/$CLAUDE_PLUGIN_JSON" || ! -f "$REPO_ROOT/$CODEX_PLUGIN_JSON" ]]; then
    exit 0
fi

if [[ "${CHP_SKIP_VERSION_BUMP:-0}" == "1" ]]; then
    exit 0
fi

ZERO_SHA="0000000000000000000000000000000000000000"
needs_bump=0
local_sha_for_bump=""

while read -r local_ref local_sha remote_ref remote_sha; do
    [[ -z "$remote_ref" ]] && continue
    [[ "$remote_ref" != "refs/heads/main" ]] && continue
    [[ "$local_sha" == "$ZERO_SHA" ]] && continue

    local_version=$(git -C "$REPO_ROOT" show "$local_sha:$CLAUDE_PLUGIN_JSON" 2>/dev/null | jq -r '.version // ""' 2>/dev/null || echo "")

    if [[ "$remote_sha" == "$ZERO_SHA" ]]; then
        remote_version=""
    else
        remote_version=$(git -C "$REPO_ROOT" show "$remote_sha:$CLAUDE_PLUGIN_JSON" 2>/dev/null | jq -r '.version // ""' 2>/dev/null || echo "")
    fi

    if [[ -z "$local_version" ]]; then
        echo "🚦 CHP: $CLAUDE_PLUGIN_JSON missing .version on push to main" >&2
        exit 1
    fi

    if [[ "$local_version" == "$remote_version" ]]; then
        needs_bump=1
        local_sha_for_bump="$local_sha"
    fi
done

if [[ "$needs_bump" -eq 0 ]]; then
    exit 0
fi

if ! git -C "$REPO_ROOT" diff --quiet || ! git -C "$REPO_ROOT" diff --cached --quiet; then
    echo "🚦 CHP: plugin version not bumped, but working tree is dirty — stage/stash and retry" >&2
    exit 1
fi

current_branch=$(git -C "$REPO_ROOT" symbolic-ref --short HEAD 2>/dev/null || echo "")
if [[ "$current_branch" != "main" ]]; then
    echo "🚦 CHP: pushing main from a different branch ($current_branch) — bump manually with: scripts/bump-version.sh" >&2
    exit 1
fi

new_version=$("$REPO_ROOT/scripts/bump-version.sh")

git -C "$REPO_ROOT" add "$CLAUDE_PLUGIN_JSON" "$CODEX_PLUGIN_JSON"
CHP_SKIP_VERSION_BUMP=1 git -C "$REPO_ROOT" commit -m "publish: bump plugin version to v$new_version" >/dev/null

echo "🚦 CHP: bumped plugin version to v$new_version and created commit" >&2
echo "🚦 CHP: re-run 'git push' to publish the bump" >&2
exit 1
