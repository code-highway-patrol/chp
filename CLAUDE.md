# CHP - Code Highway Patrol

A hybrid code law enforcement plugin for Claude Code. Laws are enforced through deterministic regex checks (fast, automatic) or subjective agent review (nuanced, AI-powered). All violations are collected into a report.

## IMPORTANT: Follow the Laws

Before generating or editing any code, obey every law listed below. Treat each law's intent as a **hard constraint** on all code you produce. Prevent violations at authoring time rather than relying on post-hoc checks. The canonical source is `laws/chp-laws.txt` — if it has been updated since this file was last synced, defer to the laws file.

### Active Laws

| ID | Intent | Reaction |
|----|--------|----------|
| `no-console-log` | No `console.log` statements in production code. Use a proper logging library or remove debug output entirely. | **block** |
| `no-hardcoded-secrets` | No hardcoded API keys, passwords, tokens, or secrets in source code. All sensitive values must come from environment variables or a secrets manager. | **block** |
| `no-todo-comments` | No TODO, FIXME, HACK, or XXX comments left in code. Resolve them or track them in an issue tracker. | **warn** |
| `no-debug-code` | No debug code left in production. This includes `debugger` statements, `console.debug` calls, and any code that exists solely for debugging purposes. | **block** |

**When writing or editing code, you MUST:**
- Never use `console.log()`, `console.debug()`, or `debugger` — use a proper logger instead.
- Never hardcode secrets, API keys, passwords, or tokens — always reference environment variables.
- Never leave `TODO:`, `FIXME:`, `HACK:`, or `XXX:` comments — resolve them or file an issue.
- Never include code whose sole purpose is debugging.

## Core Concept

Users define laws in `laws/chp-laws.txt`. Each law has an intent and optionally a `check:` regex pattern.

- **Deterministic laws** (have `check:`): Scanned automatically via regex. Zero inference cost.
- **Subjective laws** (no `check:`): Reviewed by an agent subagent using judgment against the law's intent.

Violations are flagged in `.chp/report.json` and can be viewed as a clean HTML dashboard at `.chp/report.html`.

## Law Format

```
# === Law: <id> ===
intent: <plain-language description>
check: <optional regex pattern for deterministic detection>
reaction: block|warn
```

## Dashboard

The dashboard at `http://localhost:5177` auto-launches via hook on the first tool use of every session. It can also be started manually with `python bin/chp-server`.

## Skills

| Skill | Purpose |
|-------|---------|
| `chp:dashboard` | Launch the web UI |
| `chp:scan-repo` | Full codebase scan with HTML report |
| `chp:write-laws` | Create new laws (auto-classifies as deterministic or subjective) |
| `chp:refine-laws` | Adjust existing laws |
| `chp:onboard` | Understand project guardrails |
