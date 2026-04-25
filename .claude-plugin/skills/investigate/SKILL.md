---
name: investigate
description: Debug why an action was blocked by CHP and understand violation history
---

# CHP Investigation

Debug why an action was blocked by CHP and understand what went wrong.

## When to Invoke

Invoke this skill when:
- A git hook failed with a CHP violation
- A CI/CD pipeline failed
- A tool call was blocked
- You see an error message mentioning "CHP violation"
- You ask "why did this fail?" or "what law blocked this?"

## Investigation Process

### 1. Identify the Blocking Law

Check the error output for the law name. It usually appears as:
```
❌ Error: CHP law <law-name> violated
```
or
```
Verification failed for law: <law-name>
```

### 2. Run Audit on the Law

Use the `chp-audit` command to see the full violation history:

```bash
./commands/chp-audit <law-name>
```

This shows:
- Total violation count
- Tightening level (how strict the law has become)
- Historical violation timestamps

### 3. Read the Law's Guidance

Understand what the law is checking:

```bash
cat docs/chp/laws/<law-name>/guidance.md
```

The guidance document explains:
- What the law checks for
- Good vs bad practice examples
- How to remediate violations

### 4. Understand the Fix

Check the verification script to see what triggered:

```bash
cat docs/chp/laws/<law-name>/verify.sh
```

Look for the `log_error` messages - these explain what pattern was detected.

### 5. Fix and Retest

After making changes:

```bash
# Test the specific law
./commands/chp-law test <law-name>

# Or retry the original action that failed
git commit  # if pre-commit failed
```

## Example

```
Scenario: You try to commit and get blocked
Error: "❌ API key detected in staged files"

1. Identify law: no-api-keys
2. Run audit: ./commands/chp-audit no-api-keys
3. Read guidance: cat docs/chp/laws/no-api-keys/guidance.md
4. Fix: Move API key to .env, add to .gitignore
5. Test: ./commands/chp-law test no-api-keys
6. Retry: git commit
```

## Common Issues

**"Law not found"** - The law name in the error might be different. Run `./commands/chp-law list` to see all laws.

**"Verification passes but commit still fails"** - There might be multiple laws blocking. Check each one.

**"This is a false positive"** - Use `chp:refine-laws` to adjust the law's verification logic.
