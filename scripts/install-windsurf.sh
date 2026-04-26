#!/usr/bin/env bash
# CHP installer for Windsurf — one-line install for the full Code Highway Patrol experience.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/code-highway-patrol/chp/main/scripts/install-windsurf.sh | bash
#
#   bash install-windsurf.sh [--no-auto-apply] [--no-workspace] [--chp-dir PATH]
#
# Flags:
#   --no-auto-apply    Disable auto-pull. Default is to auto-pull on hook fires
#                      (when working tree clean). CHP runs from inside other
#                      agents — there is no CHP CLI to surface a notification.
#   --no-workspace     Skip writing .windsurf/* in the current repo (global only).
#   --chp-dir PATH     Use this existing CHP checkout instead of cloning. Useful for dev.
#
# What it does:
#   • Clones (or updates) the CHP toolkit at ~/.chp
#   • npm install
#   • Merges the chp MCP server entry into ~/.codeium/windsurf/mcp_config.json
#   • If run inside a git repo: writes .windsurf/hooks.json, .windsurf/skills/chp-*/SKILL.md,
#     and .windsurf/rules/chp.md so Cascade Hooks fire CHP's dispatcher

set -euo pipefail

CHP_REPO="${CHP_REPO:-https://github.com/code-highway-patrol/chp.git}"
CHP_DIR="${CHP_DIR:-$HOME/.chp}"
WINDSURF_DIR="$HOME/.codeium/windsurf"
MCP_CONFIG="$WINDSURF_DIR/mcp_config.json"

AUTO_APPLY=true
WRITE_WORKSPACE=true
EXPLICIT_CHP_DIR=false

while [ $# -gt 0 ]; do
    case "$1" in
        --no-auto-apply) AUTO_APPLY=false ;;
        --auto-apply) AUTO_APPLY=true ;;  # accepted for back-compat; now the default
        --no-workspace) WRITE_WORKSPACE=false ;;
        --chp-dir)
            CHP_DIR="$2"
            EXPLICIT_CHP_DIR=true
            shift ;;
        --help|-h)
            sed -n '2,20p' "$0"
            exit 0 ;;
        *) echo "Unknown flag: $1" >&2; exit 2 ;;
    esac
    shift
done

# ── prereqs ────────────────────────────────────────────────────────────────

if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
    echo "🚔 CHP requires bash 4+. macOS users: brew install bash, then re-run." >&2
    exit 1
fi

for cmd in git jq node npm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "🚔 CHP requires '$cmd' but it's not installed." >&2
        exit 1
    fi
done

echo "🚔 Installing Code Highway Patrol for Windsurf..."

# ── toolkit clone/update ───────────────────────────────────────────────────

if [ "$EXPLICIT_CHP_DIR" = true ]; then
    if [ ! -d "$CHP_DIR" ]; then
        echo "  ✗ --chp-dir specified but $CHP_DIR does not exist" >&2
        exit 1
    fi
    echo "  → Using existing CHP checkout at $CHP_DIR (skipping clone)"
elif [ ! -d "$CHP_DIR/.git" ]; then
    echo "  → Cloning CHP toolkit to $CHP_DIR"
    mkdir -p "$(dirname "$CHP_DIR")"
    git clone --quiet "$CHP_REPO" "$CHP_DIR"
else
    echo "  → Updating CHP toolkit at $CHP_DIR"
    if [ -n "$(git -C "$CHP_DIR" status --porcelain --untracked-files=no)" ]; then
        echo "    (working tree has local changes — skipping pull)"
    else
        git -C "$CHP_DIR" fetch --quiet origin main
        git -C "$CHP_DIR" pull --quiet --ff-only origin main || true
    fi
fi

# ── npm install ────────────────────────────────────────────────────────────

if [ ! -d "$CHP_DIR/node_modules" ] || [ "$CHP_DIR/package.json" -nt "$CHP_DIR/node_modules" ]; then
    echo "  → Installing npm dependencies"
    (cd "$CHP_DIR" && npm install --silent --no-fund --no-audit)
else
    echo "  → npm dependencies up to date"
fi

# ── ensure scripts are executable ──────────────────────────────────────────

find "$CHP_DIR" \( -name "*.sh" -o -path "*/commands/chp-*" -o -path "*/bin/*" \) -type f \
    -exec chmod +x {} \; 2>/dev/null || true

# ── MCP server config (global, ~/.codeium/windsurf/mcp_config.json) ────────

echo "  → Configuring Windsurf MCP server"
mkdir -p "$WINDSURF_DIR"

if [ ! -f "$MCP_CONFIG" ] || [ ! -s "$MCP_CONFIG" ]; then
    echo '{"mcpServers":{}}' > "$MCP_CONFIG"
fi

if ! jq empty "$MCP_CONFIG" >/dev/null 2>&1; then
    echo "  ✗ $MCP_CONFIG is not valid JSON. Fix or delete it and re-run." >&2
    exit 1
fi

tmp=$(mktemp)
jq --arg path "$CHP_DIR/lib/mcp-server.js" \
   --arg root "$CHP_DIR" \
   '.mcpServers.chp = {
        "command": "node",
        "args": [$path],
        "env": {"CHP_ROOT": $root}
    }' "$MCP_CONFIG" > "$tmp"
mv "$tmp" "$MCP_CONFIG"

# ── auto-apply flag ────────────────────────────────────────────────────────
#
# Default is auto-apply (CHP runs from inside other agents — Cascade, Claude
# Code, Codex — so a notify-only banner has no shell prompt to act on). The
# legacy .chp/auto-apply opt-in marker is no longer used; opt-out via
# .chp/no-auto-apply.

mkdir -p "$CHP_DIR/.chp"
rm -f "$CHP_DIR/.chp/auto-apply"  # legacy marker, no longer read
if [ "$AUTO_APPLY" = true ]; then
    rm -f "$CHP_DIR/.chp/no-auto-apply"
    echo "  → Auto-apply enabled (default) — toolkit updates pull automatically when working tree is clean"
else
    touch "$CHP_DIR/.chp/no-auto-apply"
    echo "  → Auto-apply disabled — updates require running '$CHP_DIR/commands/chp-upgrade'"
fi

# ── workspace setup (project-scoped, committed to user's repo) ─────────────

if [ "$WRITE_WORKSPACE" = true ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    echo "  → Configuring workspace at $REPO_ROOT"

    mkdir -p "$REPO_ROOT/.windsurf/skills" "$REPO_ROOT/.windsurf/rules"

    # hooks.json — wires Cascade events to CHP's dispatcher
    cat > "$REPO_ROOT/.windsurf/hooks.json" <<EOF
{
  "hooks": {
    "pre_write_code": [
      { "command": "\$HOME/.chp/hooks/agent/cascade-dispatch.sh pre_write_code", "show_output": true }
    ],
    "pre_run_command": [
      { "command": "\$HOME/.chp/hooks/agent/cascade-dispatch.sh pre_run_command", "show_output": true }
    ],
    "pre_mcp_tool_use": [
      { "command": "\$HOME/.chp/hooks/agent/cascade-dispatch.sh pre_mcp_tool_use", "show_output": true }
    ],
    "pre_user_prompt": [
      { "command": "\$HOME/.chp/hooks/agent/cascade-dispatch.sh pre_user_prompt", "show_output": false }
    ],
    "post_cascade_response": [
      { "command": "\$HOME/.chp/hooks/agent/cascade-dispatch.sh post_cascade_response", "show_output": false }
    ]
  }
}
EOF

    # Skills — copy from the canonical Claude plugin skills folder
    SKILL_SRC="$CHP_DIR/.claude-plugin/plugins/chp/skills"
    if [ -d "$SKILL_SRC" ]; then
        for skill_dir in "$SKILL_SRC"/*/; do
            skill_name=$(basename "$skill_dir")
            dest="$REPO_ROOT/.windsurf/skills/chp-$skill_name"
            mkdir -p "$dest"
            cp "$skill_dir/SKILL.md" "$dest/SKILL.md"
        done
    fi

    # Rule
    if [ -f "$CHP_DIR/assets/windsurf-rule.md" ]; then
        cp "$CHP_DIR/assets/windsurf-rule.md" "$REPO_ROOT/.windsurf/rules/chp.md"
    fi

    # Git hooks (reuse CHP's existing installer if available)
    if [ -x "$CHP_DIR/core/installer.sh" ]; then
        echo "  → Installing git hooks (pre-commit, pre-push)"
        (cd "$REPO_ROOT" && CHP_BASE="$CHP_DIR" "$CHP_DIR/core/installer.sh" install pre-commit pre-push 2>/dev/null) || true
    fi

    echo "  → Workspace files written. Commit \`.windsurf/\` so teammates pick them up."
fi

# ── final message ──────────────────────────────────────────────────────────

cat <<EOF

✓ CHP installed for Windsurf

  Toolkit:    $CHP_DIR
  MCP config: $MCP_CONFIG
  Auto-apply: $AUTO_APPLY

Next steps:
  1. Restart Windsurf so it picks up the new MCP server.
  2. To upgrade later, re-run this script (or run: $CHP_DIR/commands/chp-upgrade).
  3. Workspace hooks fire on every Cascade tool call — try editing a file with
     console.log, you should see CHP block the write.

EOF
