# CHP for Windsurf

Code Highway Patrol delivers the same enforcement experience in Windsurf that it does in Claude Code and Codex — Cascade gets blocked the moment it tries to write `console.log`, commit a hard-coded API key, or run a command that violates a law.

Windsurf has no plugin marketplace, so install is one bash command. See [INSTALL.md](./INSTALL.md) for full instructions.

```bash
curl -sSL https://raw.githubusercontent.com/code-highway-patrol/chp/main/scripts/install-windsurf.sh | bash
```

## What you get

- **Cascade Hooks** wired to CHP's dispatcher — agent actions get verified before they execute
- **Cascade Skills** (`chp-audit`, `chp-investigate`, `chp-status`, `chp-write-laws`, `chp-review-laws`, `chp-decompose-laws`)
- **MCP server** exposing `chp_analyze`, `chp_check`, `chp_create_law`, `chp_validate`
- **Cascade rule** at `.windsurf/rules/chp.md` so the agent understands CHP's enforcement model
- **Git hooks** (pre-commit, pre-push) for the commit-time safety net

All laws live in `docs/chp/laws/<name>/`. The same `verify.sh` files enforce the same rules across every editor — Windsurf is just another front-end.

## Auto-update

Brew-style: the dispatcher does a throttled `git fetch` once per 24h. If new commits exist, you get a banner in chat suggesting `chp upgrade`. Pass `--auto-apply` at install time to skip the prompt and pull automatically.

## Files

- [INSTALL.md](./INSTALL.md) — install, uninstall, troubleshooting
- [mcp-server.json](./mcp-server.json) — reference MCP tool/resource schema (also the source of truth for what the MCP server exposes)

## Why no plugin manifest?

Windsurf has no plugin system in the Claude Code / Codex sense. There's no `plugin.json` schema for Windsurf, no marketplace catalog format, and no first-party install command. Cascade's extensibility is delivered through `.windsurf/hooks.json` (workspace), `.windsurf/skills/` (workspace), `.windsurf/rules/` (workspace), and `~/.codeium/windsurf/mcp_config.json` (user-global). The installer writes those files directly.
