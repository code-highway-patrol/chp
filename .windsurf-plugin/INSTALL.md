# Installing CHP for Windsurf

Windsurf does not have a plugin marketplace, so CHP installs via a single bash command. The installer wires up Cascade Hooks (the agent-side enforcement layer), Cascade Skills, the MCP server, and git hooks — the full CHP experience, same as Claude Code and Codex.

## One-line install

Run from the root of any project where you want CHP enforcement:

```bash
curl -sSL https://raw.githubusercontent.com/code-highway-patrol/chp/main/scripts/install-windsurf.sh | bash
```

Then **restart Windsurf** so it picks up the new MCP server.

### Flags

```bash
# Default: auto-pull updates on hook fires (when working tree is clean)
curl -sSL .../install-windsurf.sh | bash

# Notify-only mode — don't auto-pull, just print a banner
curl -sSL .../install-windsurf.sh | bash -s -- --no-auto-apply

# Global install only — don't write .windsurf/* in current repo
curl -sSL .../install-windsurf.sh | bash -s -- --no-workspace
```

CHP runs from inside other agents (Cascade, Claude Code, Codex), so there is no CHP CLI prompt to surface an update notification. Auto-pull is the default — the dispatcher fast-forwards `~/.chp` from `origin/main` once per 24h when the working tree is clean. Pass `--no-auto-apply` if you'd rather pin to a specific SHA and update manually with `chp upgrade`.

## What gets installed

### Global (one-time, at `~/.chp/`)

The CHP toolkit gets cloned to `~/.chp/`. Re-running the installer updates this clone.

The Windsurf MCP server config at `~/.codeium/windsurf/mcp_config.json` gets a `chp` entry merged in (existing entries are preserved). This exposes `chp_analyze`, `chp_check`, `chp_create_law`, and `chp_validate` as tools Cascade can call.

### Workspace (committed to your repo, at `<project>/.windsurf/`)

- `hooks.json` — wires `pre_write_code`, `pre_run_command`, `pre_mcp_tool_use`, `pre_user_prompt`, and `post_cascade_response` to CHP's dispatcher. Cascade fires these events before/after agent actions; CHP's verifiers run and can block actions by exiting with code 2.
- `skills/chp-{audit,investigate,status,write-laws,review-laws,decompose-laws}/SKILL.md` — six Cascade Skills for working with CHP laws.
- `rules/chp.md` — a Cascade rule that tells Cascade about CHP's enforcement and how to read blocked-action messages.

Plus `.git/hooks/pre-commit` and `pre-push` get wired (same git hooks CHP installs anywhere).

**Commit `.windsurf/` to your repo** so teammates inherit the same enforcement when they clone.

## Updates

CHP self-checks for updates lazily. The cascade-dispatch hook does a throttled `git fetch` on `~/.chp/` once per 24h. If new commits exist:

- **Default (auto-apply):** new commits are pulled automatically on the next hook fire (only when working tree is clean). A `🚔 CHP auto-updated N commit(s) → <sha>` banner prints to stderr so the agent's tool output records what changed.
- **With `--no-auto-apply`:** dispatcher prints a notify-only banner and waits for `chp upgrade` to be run manually.

Manual upgrade (any time):

```bash
~/.chp/commands/chp-upgrade
```

## Uninstall

```bash
# Remove the toolkit
rm -rf ~/.chp

# Remove the MCP entry (preserves other servers)
jq 'del(.mcpServers.chp)' ~/.codeium/windsurf/mcp_config.json > /tmp/mcp.json
mv /tmp/mcp.json ~/.codeium/windsurf/mcp_config.json

# Per-project: remove .windsurf/ from any repo where you no longer want CHP
rm -rf .windsurf
```

## How CHP intercepts Cascade

When Cascade tries to write to a file, run a shell command, or call an MCP tool, Windsurf fires the corresponding `pre_*` hook event. Our `hooks.json` runs `~/.chp/hooks/agent/cascade-dispatch.sh` for that event, which:

1. Maps the Cascade event to a CHP hook name (e.g. `pre_write_code` → `pre-tool`)
2. Captures Cascade's JSON context from stdin into `CHP_TOOL_INPUT`
3. Runs `core/dispatcher.sh`, which finds laws registered for the hook and runs each `verify.sh`
4. If any law's verifier exits non-zero, the dispatcher exits 1, Cascade Hooks treats that as exit code ≥ 2 → blocks the action and shows the verifier's stderr to the user

Same dispatcher, same laws, same auto-tightening as Claude Code and Codex. The only Windsurf-specific bit is the event-name translation in `cascade-dispatch.sh`.

## Troubleshooting

**Hooks don't fire.** Make sure `.windsurf/hooks.json` exists at the *workspace root* (where you opened Windsurf), not buried in a subdirectory. Restart Windsurf after creating the file.

**MCP server not visible.** Check `~/.codeium/windsurf/mcp_config.json` has the `chp` entry, and restart Windsurf.

**`jq: command not found`.** The installer needs `jq`, `git`, `node`, `npm`, and bash 4+. On macOS: `brew install jq bash`.

**Update banner won't go away.** That means you installed with `--no-auto-apply` and there are unapplied commits. Run `~/.chp/commands/chp-upgrade`, or re-run the installer without `--no-auto-apply` to flip back to auto-pull.
