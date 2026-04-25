# CHP - Code Highway Patrol

A hybrid code law enforcement plugin for Claude Code. Laws are enforced through deterministic regex checks (fast, automatic) or subjective agent review (nuanced, AI-powered). All violations are collected into a report.

## IMPORTANT: Follow the Laws

Before generating or editing any code, read `laws/chp-laws.txt` and obey every law defined there. Treat each law's `intent:` as a hard constraint on all code you produce. Do not write code that would violate any law — prevent violations at authoring time rather than relying on post-hoc checks.

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
