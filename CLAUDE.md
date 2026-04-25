# CHP - Code Highway Patrol

A two-layer code law enforcement system for Claude Code projects. CHP enforces organizational rules ("laws") on code through suggestion and automated verification with self-improving exclusion rules.

## Core Concept

Users define laws (rules about code quality, security, style) in a single text file. When code is generated, CHP:
1. Checks it against the laws
2. If a violation is found, adds an exclusion rule and regenerates
3. Retries up to 3 times before notifying the user

## Law File

All laws live in `laws/chp-laws.txt`. Each law follows this format:

```
# === Law: <unique-id> ===
intent: <what this law enforces>
violation: <regex pattern that triggers violation>
exclusion: <optional regex for false positives>
reaction: block|warn|auto_fix
```

## Skills

| Skill | Purpose |
|-------|---------|
| `chp:scan-repo` | Scan codebase for violations |
| `chp:write-laws` | Create new laws |
| `chp:refine-laws` | Adjust existing laws |
| `chp:onboard` | Understand project guardrails |
