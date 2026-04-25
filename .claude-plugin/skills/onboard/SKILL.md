---
name: chp:onboard
description: Understand what CHP guardrails are in place for a project
---

# CHP Project Onboarding

Understand what CHP guardrails and traffic laws are enforced in this project.

## When to Invoke

Invoke this skill when:
- You're new to the project
- You ask "what rules are enforced here?"
- You're starting work on an unfamiliar codebase
- You need to understand project constraints
- You want to know what guardrails are in place

## Understanding CHP

CHP (Code Health Protocol) provides **two layers** of enforcement:

### 1. Suggestive Layer
- Context files in `docs/chp/` guide you to follow rules
- Active before you make mistakes
- Helps you self-correct

### 2. Verification Layer
- Scripts in `docs/chp/laws/*/verify.sh` check for violations
- Catches violations when they happen
- Can block commits, pushes, or other actions

## Quick Overview

### Check System Status

```bash
./commands/chp-status
```

This shows:
- Detected hook systems (Git, Agent, CI/CD)
- Active laws with their status
- Installed hooks
- Hook registry mappings

### List All Laws

```bash
./commands/chp-law list
```

This shows each law with:
- Severity level (error, warn, info)
- Failure count
- Enabled status

## Understanding Each Law

For each law, read its guidance:

```bash
cat docs/chp/laws/<law-name>/guidance.md
```

The guidance explains:
- **Purpose** - What the law protects
- **What it checks** - Patterns it looks for
- **Good practice** - Compliant examples
- **Bad practice** - Non-compliant examples
- **Remediation** - How to fix violations

## Law Categories

### Security Laws
Protect against security vulnerabilities:
- `no-api-keys` - No hardcoded API keys
- `no-secrets` - No secrets in code
- `no-hardcoded-credentials` - Use environment variables

### Quality Laws
Maintain code quality:
- `no-console-log` - Remove debug statements
- `max-function-length` - Keep functions manageable
- `require-documentation` - Document public APIs

### Style Laws
Enforce consistency:
- `import-ordering` - Consistent import statements
- `naming-conventions` - Follow naming standards

### Workflow Laws
Process requirements:
- `test-coverage` - Maintain test coverage
- `no-skip-tests` - Don't skip tests in commits

## What Happens on Violation?

### Error Severity
- Action is **blocked**
- You must fix before proceeding
- Failure count increments
- Guidance may auto-tighten

### Warn Severity
- Warning is logged
- Action proceeds
- Still tracked for visibility

### Info Severity
- Informational only
- No blocking
- For awareness

## Hooks Explained

Hooks are **trigger points** where laws run:

### Git Hooks
- `pre-commit` - Before committing
- `pre-push` - Before pushing to remote
- `commit-msg` - Validate commit messages

### Agent Hooks
- `pre-prompt` - Before agent processes request
- `pre-tool` - Before agent uses a tool
- `post-response` - After agent responds

### CI/CD Hooks
- `pre-build` - Before building
- `post-build` - After build completes
- `pre-deploy` - Before deploying

Check which hooks are installed:
```bash
./commands/chp-hooks list
```

## Getting Started Workflow

### 1. First Time Setup

```bash
# See what's enforced
./commands/chp-status

# List all laws
./commands/chp-law list

# Read guidance for each active law
for law in docs/chp/laws/*/guidance.md; do
    echo "=== $(basename $(dirname $law)) ==="
    cat $law
    echo ""
done
```

### 2. Before Starting Work

Use `chp:plan-check` to see which laws apply to your planned work.

### 3. While Working

- Laws run automatically on configured hooks
- If blocked, use `chp:investigate` to debug
- Read the law's guidance for remediation

### 4. When Blocked

```bash
# See what blocked you
./commands/chp-audit <law-name>

# Understand what to fix
cat docs/chp/laws/<law-name>/guidance.md

# Test after fixing
./commands/chp-law test <law-name>
```

## Common Questions

**Q: Can I disable a law?**
A: Use `./commands/chp-law disable <law-name>` but discuss with team first.

**Q: What if a law is wrong?**
A: Use `chp:refine-laws` to adjust it, or discuss with the team.

**Q: How do I suggest a new law?**
A: Use `chp:write-laws` to create one, or discuss with the team.

**Q: Do laws run on every file?**
A: Only on files affected by the hook (e.g., staged files for pre-commit).

## Resources

- **All laws:** `docs/chp/laws/`
- **System status:** `./commands/chp-status`
- **Law management:** `./commands/chp-law`
- **Hook management:** `./commands/chp-hooks`

## Summary

1. Run `./commands/chp-status` for overview
2. Run `./commands/chp-law list` to see all laws
3. Read `guidance.md` for each active law
4. Use `chp:plan-check` before starting work
5. Use `chp:investigate` when blocked
6. Use `chp:refine-laws` to adjust laws if needed
