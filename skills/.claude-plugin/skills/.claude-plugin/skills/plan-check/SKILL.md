---
name: plan-check
description: Preview which CHP laws apply before implementing changes
---

# CHP Plan Check

Preview which CHP laws apply to your planned work before you start implementing. Avoid surprises by understanding guardrails upfront.

## When to Invoke

Invoke this skill when:
- You're about to implement a feature
- You're planning architectural changes
- You ask "what should I watch out for?"
- You're in the planning phase before coding
- Starting work on a new area of the codebase

## Checking Applicable Laws

### List All Active Laws

```bash
./commands/chp-law list
```

Output shows:
```
  no-api-keys | severity: error | failures: 1 | enabled
  no-console-log | severity: error | failures: 7 | enabled
  max-function-length | severity: warn | failures: 0 | enabled
```

### Check System Status

```bash
./commands/chp-status
```

Output shows:
- Which hooks are installed
- Which laws have recent failures
- Hook-to-law mappings

## Understanding What Laws Check

### Read Law Guidance

For each relevant law, read its guidance:

```bash
cat docs/chp/laws/<law-name>/guidance.md
```

This explains:
- What the law checks for
- Good vs bad practice examples
- How to comply

### Check Verification Logic

To understand exactly what triggers violations:

```bash
cat docs/chp/laws/<law-name>/verify.sh
```

Look for:
- Patterns being matched
- File types being checked
- Conditions that trigger failures

## Example Scenarios

### Scenario 1: Adding a New API Endpoint

**Planned work:** Add user authentication endpoint

**Check laws:**
```bash
./commands/chp-law list
```

**Relevant laws to review:**
- `no-api-keys` - Don't commit API keys
- `max-function-length` - Keep handler functions short

**Read guidance:**
```bash
cat docs/chp/laws/no-api-keys/guidance.md
cat docs/chp/laws/max-function-length/guidance.md
```

**Plan accordingly:**
- Use environment variables for API keys
- Split handler into smaller functions if needed

### Scenario 2: Refactoring Database Queries

**Planned work:** Optimize slow database queries

**Check laws:**
```bash
./commands/chp-law list
```

**Relevant laws to review:**
- `no-hardcoded-credentials` - Don't hardcode DB passwords
- `require-transaction` - Use transactions for multi-statement operations

**Plan accordingly:**
- Use connection strings from environment
- Wrap multi-statement operations in transactions

### Scenario 3: Adding Frontend Components

**Planned work:** Create new React components

**Check laws:**
```bash
./commands/chp-law list
```

**Relevant laws to review:**
- `no-console-log` - Don't leave console.log in production code
- `component-naming` - Use consistent naming conventions

**Plan accordingly:**
- Use proper logging instead of console.log
- Follow naming conventions from the start

## Making Changes After Planning

If you discover a law is too restrictive or doesn't fit your use case:

1. **Don't disable it immediately** - Understand why it exists first
2. **Read the full guidance** - There might be a compliant approach
3. **Use `chp:refine-laws`** - If genuinely needed, adjust the law
4. **Discuss with team** - Laws represent team standards

## Quick Reference

| Work Type | Commonly Relevant Laws |
|-----------|----------------------|
| API changes | no-api-keys, no-secrets |
| Frontend | no-console-log, component-naming |
| Database | no-hardcoded-credentials, require-transaction |
| Config files | no-secrets, proper-env-vars |
| Tests | test-coverage, no-skip-tests |
