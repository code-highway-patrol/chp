---
name: status
description: Understand what CHP guardrails are in place and which laws apply to your work
---

# CHP Status

See what CHP laws are enforced in this project and which ones apply to what you're about to do.

## When to Invoke

Invoke this skill when:
- You're new to the project or working in an unfamiliar area
- You're about to implement a feature or make changes
- You ask "what rules does this project enforce?" or "what should I watch out for?"
- A hook failed and you need to understand the enforcement model

## Quick Check

### See Everything

```bash
./commands/chp-status
```

Shows: detected hook systems, active laws, installed hooks, hook registry.

### List All Laws

```bash
./commands/chp-law list
```

Shows each law with severity, failure count, and enabled status.

Example output:
```
  no-api-keys | severity: error | failures: 1 | enabled
  no-console-log | severity: error | failures: 7 | enabled
  max-function-length | severity: warn | failures: 0 | enabled
```

### Read a Law's Details

```bash
cat docs/chp/laws/<law-name>/guidance.md
```

Explains what the law checks, good vs bad examples, and how to comply.

To see the exact verification logic:
```bash
cat docs/chp/laws/<law-name>/verify.sh
```

## How Enforcement Works

CHP uses two layers:

**Suggestive layer** — Context docs in `docs/chp/` that guide you before you make mistakes. Active proactively.

**Verification layer** — Shell scripts in `docs/chp/laws/*/verify.sh` that catch violations when they happen. Can block commits, pushes, and other actions.

### Severity Levels

| Severity | What happens |
|----------|-------------|
| **error** | Action is **blocked**. Must fix before proceeding. Failure count increments. |
| **warn** | Warning logged. Action proceeds. Still tracked. |
| **info** | Informational only. No blocking. |

### Hooks

Hooks are trigger points where laws run:

- **Git:** `pre-commit`, `pre-push`, `commit-msg`, `post-commit`, `post-merge`, and more
- **Agent:** `pre-tool`, `post-tool`, `pre-prompt`, `post-response`
- **CI/CD:** `pre-build`, `post-build`, `pre-deploy`, `post-deploy`

Check installed hooks: `./commands/chp-hooks list`

## Previewing Laws Before Work

Before starting a task, check which laws are likely relevant:

| Work Type | Commonly Relevant Laws |
|-----------|----------------------|
| API changes | no-api-keys, no-secrets |
| Frontend | no-console-log, component-naming |
| Database | no-hardcoded-credentials, require-transaction |
| Config files | no-secrets, proper-env-vars |
| Tests | test-coverage, no-skip-tests |

For each relevant law:
1. Read the guidance: `cat docs/chp/laws/<law-name>/guidance.md`
2. Plan to comply from the start rather than fixing after

## When You Get Blocked

If a law blocks your action, use `chp:investigate` to debug what happened and how to fix it.

If a law seems wrong or too restrictive, use `chp:write-laws` to adjust it.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `./commands/chp-status` | System overview |
| `./commands/chp-law list` | List all laws |
| `cat docs/chp/laws/<name>/guidance.md` | Read law guidance |
| `cat docs/chp/laws/<name>/verify.sh` | Read verification logic |
| `./commands/chp-hooks list` | See installed hooks |
