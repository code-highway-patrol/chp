---
trigger: always_on
---

# Code Highway Patrol (CHP) is enforced in this workspace

This project ships with CHP, a static-analysis layer that enforces "laws" via Cascade Hooks. Before you write code, run a command, or invoke an MCP tool, CHP's verifiers run and can BLOCK the action with a clear error message.

## What gets blocked

- `console.log` and other forbidden debug calls
- Hard-coded API keys, tokens, and secrets (`sk-`, `AKIA`, `ghp_`, `xoxb-`, etc.)
- `// TODO`, `// FIXME`, `// XXX`, `// HACK`-style placeholder comments
- `alert()` calls in user-facing code
- Other project-specific laws under `docs/chp/laws/`

When CHP blocks an action, the rejection message tells you which law failed and how to fix it. Apply the fix and try again — don't try to bypass the hook.

## How to read CHP's response

A blocked `pre_write_code` looks like a non-zero exit from the hook with a message on stderr. Cascade surfaces that in the chat. Read the message: it names the law, the file, and the violating pattern. Re-do the edit without the violation rather than working around the check.

## Where the laws live

Each law has a directory under `docs/chp/laws/<name>/` containing `law.json`, `verify.sh`, and `guidance.md`. The `guidance.md` files explain the rule in detail and tend to be tightened over time as violations recur.

If you need to add a new law, use the `chp-write-laws` skill.

## Updates

CHP self-updates lazily. The dispatcher checks for new commits on the upstream repo once per day; if behind, it prints a banner suggesting `chp upgrade`. If `--auto-apply` was passed during install, it pulls automatically (only when the working tree is clean).
