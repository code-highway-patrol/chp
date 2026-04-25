---
name: onboard
description: Understand what CHP laws are enforced in this project
---

# CHP Onboarding

## When to Use

- User is new to the project
- User asks "what rules exist?" or "what guardrails are in place?"

## Process

1. Check for `laws/chp-laws.txt` in the project root
2. If the file doesn't exist, tell the user they need to create it (either manually or via `/chp:write-laws`) and show the law format
3. If it exists, summarize each law: name, intent, reaction type, and whether it's deterministic or subjective
4. Group by category (security, quality, style)

## How CHP Works

CHP uses two enforcement mechanisms that run after every file write:

1. **Deterministic checks** — Laws with a `check:` regex pattern are scanned automatically by a script. Fast, zero inference cost. Violations are tagged AUTO in reports.
2. **Subjective review** — Laws without a `check:` field are evaluated by an agent using judgment. Catches nuanced violations that regex can't. Tagged REVIEW in reports.

All violations go into `.chp/report.json`. Run `/chp:scan-repo` to generate a full HTML report at `.chp/report.html`.

## Output Format

```
This project enforces N laws:

Deterministic (auto-checked):
  [block] no-console-log: No console.log in production code
  [warn]  no-todo-comments: No TODO/FIXME/HACK comments
  [block] no-debug-code: No debugger statements

Subjective (agent-reviewed):
  [block] no-hardcoded-secrets: No hardcoded API keys, passwords, or tokens
```
