---
name: onboard
description: Understand what CHP laws are enforced in this project
---

# CHP Onboarding

## When to Use

- User is new to the project
- User asks "what rules exist?", "what's enforced?", or "what guardrails are in place?"
- Starting work on an unfamiliar codebase

## Process

1. Read `laws/chp-laws.txt`
2. Summarize each active law: name, intent, reaction type
3. Group laws by category (security, quality, style)
4. Highlight any `block`-level laws the user must know about

## Output Format

Present a clear summary:

```
This project enforces N laws:

Security (block):
  - no-api-keys: No hardcoded API keys in source code
  - no-hardcoded-passwords: No hardcoded passwords

Quality (block):
  - no-console-log: No console.log in production code
  - no-debug-code: No debugger statements

Style (warn):
  - no-todo-comments: No TODO/FIXME/HACK comments
```

## Follow-Up

- Suggest `chp:scan-repo` to check current compliance
- Suggest `chp:write-laws` if the user wants to add rules
- Suggest `chp:refine-laws` if any law seems wrong
