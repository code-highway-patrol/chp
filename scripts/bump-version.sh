#!/usr/bin/env bash
# Bump the patch version in both Claude Code and Codex plugin manifests.
# Codex caches installs by version string — without a bump, `codex plugin
# marketplace upgrade` keeps serving the cached copy. Claude Code's marketplace
# falls back to commit SHA, but we bump it too so both surfaces stay in sync.
#
# Usage: scripts/bump-version.sh [--dry-run]
# Emits the new version on stdout.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugins/chp/plugin.json"
CODEX_PLUGIN_JSON="$REPO_ROOT/.codex-plugin/plugins/chp/.codex-plugin/plugin.json"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "bump-version: jq is required" >&2
    exit 1
fi

for f in "$CLAUDE_PLUGIN_JSON" "$CODEX_PLUGIN_JSON"; do
    if [[ ! -f "$f" ]]; then
        echo "bump-version: missing manifest: $f" >&2
        exit 1
    fi
done

current=$(jq -r '.version // "0.0.0"' "$CLAUDE_PLUGIN_JSON")
codex_current=$(jq -r '.version // "0.0.0"' "$CODEX_PLUGIN_JSON")

if [[ "$current" != "$codex_current" ]]; then
    echo "bump-version: version drift between manifests (claude=$current codex=$codex_current); using max" >&2
    if [[ "$(printf '%s\n%s\n' "$current" "$codex_current" | sort -V | tail -1)" == "$codex_current" ]]; then
        current="$codex_current"
    fi
fi

IFS='.' read -r major minor patch <<<"$current"
patch=$((patch + 1))
new_version="${major}.${minor}.${patch}"

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "$new_version"
    exit 0
fi

tmp=$(mktemp)
jq --arg v "$new_version" '.version = $v' "$CLAUDE_PLUGIN_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_PLUGIN_JSON"
tmp=$(mktemp)
jq --arg v "$new_version" '.version = $v' "$CODEX_PLUGIN_JSON" > "$tmp" && mv "$tmp" "$CODEX_PLUGIN_JSON"

echo "$new_version"
