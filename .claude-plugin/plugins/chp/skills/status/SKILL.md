---
name: status
description: Understand what CHP guardrails are in place and which laws apply to your work. Triggers on "status", "what laws", "what rules", "what guards", "enforcement", "guardrails", "what's enforced", "show laws", "list laws", "active laws", "what protections", "what checks", "what constraints".
---

# CHP Status

See what CHP laws are enforced in this project and understand which ones apply to what you're about to do.

## When to Invoke

- You're new to the project or working in an unfamiliar area
- You're about to implement a feature or make changes
- User asks "what rules does this project enforce?", "what should I watch out for?"
- User says "show me the laws", "what's enforced", "what protections are in place"
- A hook failed and you need to understand the enforcement model
- Before starting work in a new area of the codebase
- User wants to understand the project's constraints or guardrails

## Quick Overview

### See Everything at Once

```bash
./commands/chp-status
```

Shows:
- Detected hook systems (Git, AI agent, CI/CD)
- Active laws with severity levels
- Installed hooks
- Hook registry configuration

Example output:
```
========================================
  Code Highway Patrol — System Status
========================================

Project: /Users/justi/dev/my-project
CHP Version: 1.0.0

Hook Systems:
  ✗ Git hooks not installed (run: chp-hooks install)
  ✓ AI agent hooks active

Laws Enforced: 8
  no-api-keys        (error)   enabled
  no-console-log     (error)   enabled
  no-alerts          (warn)    enabled
  no-todos           (warn)    enabled
  test-scope         (error)   enabled
  max-line-length    (info)    enabled

Installed Hooks: 2
  pre-tool    → 6 laws
  post-tool   → 1 law
```

### List All Laws

```bash
./commands/chp-law list
```

Shows each law with severity, failure count, and enabled status:
```
  no-api-keys      | severity: error | failures: 1 | enabled
  no-console-log   | severity: error | failures: 7 | enabled
  max-line-length  | severity: warn  | failures: 0 | enabled
```

### Read Law Details

```bash
# Read the guidance (what it checks, why, how to comply)
cat docs/chp/laws/<law-name>/guidance.md

# Read the verification logic (exact patterns detected)
cat docs/chp/laws/<law-name>/verify.sh

# Read the law metadata (hooks, severity, scope)
cat docs/chp/laws/<law-name>/law.json
```

## How Enforcement Works

CHP uses two layers to protect your codebase:

### Suggestive Layer

Context documents in `docs/chp/` that guide you **before** you make mistakes. These are proactively shown to agents and developers.

Example: A law might have a guidance document that explains "Use environment variables for API keys" — this context is available before code is written.

### Verification Layer

Shell scripts in `docs/chp/laws/*/verify.sh` that **catch violations** when they happen. These run automatically at trigger points and can block commits, pushes, and other actions.

Example: When you try to commit code with an API key, the verify.sh script detects it and blocks the commit.

### Severity Levels

| Severity | What Happens | When to Use |
|----------|--------------|-------------|
| **error** | Action is **blocked**. Must fix before proceeding. | Security issues, breaking patterns |
| **warn** | Warning logged. Action proceeds. Still tracked. | Style issues, should-fix patterns |
| **info** | Informational only. No blocking. | Documentation, awareness |

### Hooks

Hooks are trigger points where laws run:

**Git Hooks:**
- `pre-commit` — Before creating a commit
- `pre-push` — Before pushing to remote
- `commit-msg` — Before accepting commit message
- `post-commit` — After commit is created
- And 10+ more git lifecycle hooks

**AI Agent Hooks:**
- `pre-tool` — Before an AI agent uses a tool
- `post-tool` — After an AI agent uses a tool
- `pre-prompt` — Before sending prompt to AI
- `post-response` — After AI responds

**CI/CD Hooks:**
- `pre-build` — Before building
- `post-build` — After build completes
- `pre-deploy` — Before deploying
- `post-deploy` — After deployment completes

Check installed hooks:
```bash
./commands/chp-hooks list
```

See available hooks:
```bash
./commands/chp-hooks detect
```

## Previewing Laws Before Work

Before starting a task, check which laws are likely relevant:

### By Work Type

| Work Type | Commonly Relevant Laws |
|-----------|----------------------|
| **API changes** | no-api-keys, no-secrets, no-hardcoded-credentials |
| **Frontend** | no-console-log, no-alerts, component-naming |
| **Database** | no-hardcoded-credentials, require-transaction, no-secrets |
| **Config files** | no-secrets, proper-env-vars, no-api-keys |
| **Tests** | test-scope, test-coverage, no-skip-tests |
| **Auth** | no-secrets, no-hardcoded-credentials, secure-session |
| **Payment** | test-coverage, no-secrets, pci-compliance |

### By File Type

| File Type | Laws That Commonly Apply |
|-----------|--------------------------|
| `**/*.ts`, `**/*.js` | no-console-log, no-alerts, no-api-keys |
| `**/*.json` | no-secrets, no-api-keys |
| `**/config/**` | no-secrets, proper-env-vars |
| `**/test/**` | test-scope, no-skip-tests |
| `**/*.env` | (should be gitignored) |

### For Each Relevant Law

1. **Read the guidance**
   ```bash
   cat docs/chp/laws/<law-name>/guidance.md
   ```

2. **Understand what it checks**
   ```bash
   cat docs/chp/laws/<law-name>/verify.sh
   ```

3. **Plan to comply from the start**
   Rather than fixing violations after, plan to comply from the beginning

## Understanding a Blocked Action

When a law blocks your action:

### Step 1: Identify the Blocking Law

The error message will show which law blocked:
```
❌ CHP violation: no-api-keys
Error: Law 'no-secrets' blocked this action
```

### Step 2: Understand Why It Blocked

```bash
# Read what the law checks
cat docs/chp/laws/<law-name>/guidance.md

# See what pattern matched
cat docs/chp/laws/<law-name>/verify.sh
```

### Step 3: Fix the Violation

Edit the violating code to comply with the law.

### Step 4: Retry

```bash
# Test the law
./commands/chp-law test <law-name>

# Retry the original action
git commit  # if pre-commit failed
```

## Quick Reference

| Command | Purpose |
|---------|---------|
| `./commands/chp-status` | System overview |
| `./commands/chp-law list` | List all laws |
| `./commands/chp-hooks list` | See installed hooks |
| `./commands/chp-hooks detect` | See available hooks |
| `cat docs/chp/laws/<name>/guidance.md` | Read law guidance |
| `cat docs/chp/laws/<name>/verify.sh` | Read verification logic |
| `cat docs/chp/laws/<name>/law.json` | Read law metadata |

## Before Starting Work Checklist

When you're about to start work:

```bash
# 1. See what's enforced
./commands/chp-status

# 2. List all laws
./commands/chp-law list

# 3. For relevant laws, read guidance
cat docs/chp/laws/<law-name>/guidance.md

# 4. Plan to comply from the start
```

This saves time — you won't have to fix violations later.

## Related Skills

- **chp:investigate** — Debug why a specific action was blocked
- **chp:audit** — Scan the codebase for current violations
- **chp:write-laws** — Adjust laws that seem wrong or too restrictive
