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

1. Read `laws/chp-laws.txt` in the project root
2. Summarize each active law: name, intent, reaction type
3. Group laws by category (security, quality, style)
4. Highlight any `block`-level laws the user must know about

## How CHP Works

CHP uses a `PostToolUse` agent hook. Every time a file is written or edited, a subagent:
1. Reads `laws/chp-laws.txt`
2. Reads the file that was just written
3. Subjectively judges whether any law's **intent** was violated
4. If violated, the main agent rewrites the code and tightens the law

Laws improve over time — each violation makes the law's intent sharper and harder to break again.

## Output Format

Present a clear summary:

```
This project enforces N laws:

Security (block):
  - no-hardcoded-secrets: No hardcoded API keys, passwords, tokens, or secrets

Quality (block):
  - no-console-log: No console.log in production code
  - no-debug-code: No debugger statements or debug-only code

Style (warn):
  - no-todo-comments: No TODO/FIXME/HACK comments
```

## Follow-Up

- Suggest `/chp:scan-repo` to check current compliance
- Suggest `/chp:write-laws` to add new rules
- Suggest `/chp:refine-laws` to adjust existing rules
