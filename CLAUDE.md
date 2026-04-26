# STOP — READ THIS BEFORE WRITING ANY CODE

If you are an AI agent working in this repository, these are hard rules. You will be blocked on commit if you violate them. No exceptions.

---

## DO NOT

- **DO NOT write `console.log()`** — This is the most-violated law (11 failures). Use `logger.info()`, `logger.error()`, or `logger.debug()`. Remove all debug logging before committing. The pre-commit hook scans staged diffs for `console.log` and will block you.

- **DO NOT hardcode API keys, tokens, or secrets** — No `sk-`, `AIza`, `AKIA`, `ghp_`, `xoxb-`, `xoxp-` prefixes in source files. Use `process.env.*` or environment variables. The pre-commit hook catches these patterns.

- **DO NOT leave pending-task, fix-me, workaround, XXX, or NOTE comments** — This law has 15 failures. Either finish the work or create a ticket and reference it by number. `// See issue #42` is fine. `// fix this later` style comments are not.

- **DO NOT use `alert()`** — Use toast notifications, modal dialogs, or proper error boundaries instead.

- **DO NOT add non-Mandarin text to documentation files** — The `mandarin-only` law requires documentation to be in Mandarin.

---

## Auto-Fix

Some CHP laws support automatic fixing of violations. When a law fails verification:

- **`autoFix: "ask"`** — Claude will show you the proposed fix and ask for confirmation
- **`autoFix: "auto"`** — Claude will apply the fix automatically and show what changed
- **`autoFix: "never"`** — No auto-fix (default, current behavior)

To manually trigger fixes: `chp-fix`

---

## Project Context

This is **CHP (Code Highway Patrol)** — a static analysis framework that enforces rules ("laws") through git hooks and agent hooks. The core runtime is Bash. The CLI is Node.js.

### Key Paths

```
core/dispatcher.sh        # Central hook router — receives events, runs law verify.sh scripts
core/hook-registry.sh     # Manages hook-to-law mappings in .chp/hook-registry.json
core/verifier.sh          # Scope checking for law enforcement
core/tightener.sh         # Auto-strengthens guidance after violations
docs/chp/laws/<name>/     # Each law = law.json + verify.sh + guidance.md
hooks/git/                # Git hook templates (pre-commit, pre-push, etc.)
hooks/agent/              # Agent hook templates (pre-tool, post-response, etc.)
commands/                 # CLI commands: chp-status, chp-law, chp-hooks, chp-audit, chp-scan
agents/                   # Agent prompts: chief.md, officer.md, detective.md
.chp/                     # Runtime state (registry, logs)
tests/                    # Bash test suite — run with `npm test`
```

### Agent Roles

- **Chief** — Creates/manages laws, coordinates Officer + Detective
- **Officer** — Runs verify.sh, blocks commits on violations
- **Detective** — Generates guidance, tightens context after failures

### Tech Stack

- Bash (core runtime, requires `jq`)
- Node.js >= 18 (CLI with Commander.js + Chalk)
- JSON for config (law.json, hook-registry.json)

### Creating a New Law

1. `mkdir docs/chp/laws/<name>` — add `law.json`, `verify.sh`, `guidance.md`
2. `verify.sh` must exit 0 on pass, 1 on violation
3. The dispatcher auto-discovers from `law.json` hooks array, or register via `chp-law`
4. Hook templates in `hooks/git/` or `hooks/agent/` call `core/dispatcher.sh`

---

Every law listed above runs on every commit. If you write code that violates them, your commit will be rejected. Fix it before staging.
