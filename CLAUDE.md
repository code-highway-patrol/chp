# CHP - Code Highway Patrol

A self-improving code law enforcement plugin for Claude Code. CHP enforces project rules ("laws") through subjective AI judgment with automatic law tightening.

## Core Concept

Users define laws as plain-language intents in `laws/chp-laws.txt`. A PostToolUse agent hook fires after every file write. A subagent reads the laws, reads the written file, and subjectively judges whether any law's intent was violated. If so:
1. The main agent rewrites the file to fix the violation
2. The main agent updates the violated law in `laws/chp-laws.txt` to be more strict and explicit

Laws get sharper over time. The more violations caught, the more specific and enforceable the intents become.

## Law File

All laws live in `laws/chp-laws.txt` in the project root. Each law has an `intent` (the primary enforcement mechanism) and a `reaction` type:

```
# === Law: <id> ===
intent: <plain-language description of what this law prohibits>
reaction: block|warn
```

The `intent` field is what the agent evaluates against. Write it like a rule you'd explain to a teammate.

## Skills

| Skill | Purpose |
|-------|---------|
| `chp:scan-repo` | Scan full codebase for violations |
| `chp:write-laws` | Create new laws |
| `chp:refine-laws` | Adjust existing laws |
| `chp:onboard` | Understand project guardrails |
