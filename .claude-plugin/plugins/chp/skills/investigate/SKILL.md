---
name: investigate
description: Debug why CHP blocked an action, understand violations, and fix them. Triggers on "why blocked", "why failed", "violation", "blocked", "law failed", "chp error", "debug law", "fix violation", "what happened", "investigate".
---

# CHP Investigation

Debug why an action was blocked by CHP, understand what went wrong, and fix it.

## When to Invoke

Invoke this skill when:
- A git hook failed with a CHP violation
- A CI/CD pipeline failed
- A tool call was blocked
- You see an error mentioning "CHP violation" or "law violated"
- You ask "why did this fail?", "what blocked this?", "what's wrong?"
- You need to understand a violation message
- Something worked before but now fails

## Quick Diagnosis

### Step 1: Find the Blocking Law

Check the error output for the law name:

```
❌ CHP violation: no-api-keys
Verification failed for law: no-console-log
Error: Law 'no-secrets' blocked this action
```

**No law name in output?** List all laws to find candidates:
```bash
./commands/chp-law list
```

### Step 2: Understand What Failed

Read the law's guidance to understand what it checks:
```bash
cat docs/chp/laws/<law-name>/guidance.md
```

This explains:
- What the law detects
- Why it's enforced
- How to fix violations

### Step 3: See the Violation Details

Run the audit command to see full violation history:
```bash
./commands/chp-audit <law-name>
```

Output shows:
```
Law: no-api-keys
Severity: error
Total violations: 7
Tightening level: 3
Recent violations:
  2026-04-26 10:23:45 - sk_1234... detected in src/config.ts
  2026-04-26 09:15:32 - AIza0... detected in lib/api.ts
```

### Step 4: Find the Exact Problem

Check the verification script to see what pattern matched:
```bash
cat docs/chp/laws/<law-name>/verify.sh
```

Look for `log_error` messages — these show what triggered:
```bash
log_error "API key pattern detected: sk_[a-zA-Z0-9]{32,}"
```

## Common Violation Patterns

### API Keys / Secrets
```
Pattern: sk_[a-zA-Z0-9]{32,}
Found in: src/config.ts line 12
Fix: Move to environment variable, add to .gitignore
```

### Console Logging
```
Pattern: console\.log\(
Found in: src/debug.js line 45
Fix: Use logger.info() instead
```

### Hardcoded Credentials
```
Pattern: (password|api_key|secret)\s*=\s*['"]
Found in: config/database.json line 8
Fix: Use environment variables
```

### Missing Tests
```
Assertion: test_file_exists
Missing: tests/payments/checkout.test.ts
Required for: src/payments/checkout.ts
Fix: Create test file
```

## Fixing Violations

### Process

1. **Identify the violating file** — Check the audit output or verify.sh log
2. **Understand the fix** — Read guidance.md for remediation steps
3. **Apply the fix** — Edit the violating file
4. **Test the law** — Verify the fix worked
   ```bash
   ./commands/chp-law test <law-name>
   ```
5. **Retry the action** — Commit, push, or retry whatever failed

### Example: Fixing API Key Violation

```bash
# 1. Run audit
./commands/chp-audit no-api-keys
# Output: sk_1234... in src/config.ts:12

# 2. Read guidance
cat docs/chp/laws/no-api-keys/guidance.md

# 3. Fix the code
# Before: const apiKey = 'sk_1234...'
# After:  const apiKey = process.env.API_KEY

# 4. Test
./commands/chp-law test no-api-keys
# Output: ✓ All checks passed

# 5. Retry commit
git commit
```

## False Positives

### Detecting False Positives

A violation might be a false positive if:
- The pattern matches something that's not actually a violation
- The code is exempt but the law doesn't know it
- The pattern is too broad

### Handling False Positives

**Option 1: Fix the pattern** (preferred)
```bash
# Edit verify.sh to narrow the pattern
# Before: grep -q 'console\.log'
# After:  grep -q 'console\.log' | grep -v 'console\.error'
```

**Option 2: Exclude the file**
```bash
# Add to law.json
"exclude": ["**/examples/**", "**/debug/**"]
```

**Option 3: Disable the law** (temporary)
```bash
./commands/chp-law disable <law-name>
```

### Report the False Positive

If a law has consistent false positives:
1. Document the case in guidance.md
2. Adjust the pattern in verify.sh
3. Run `chp:review-laws` to sync all files

## Multiple Blocking Laws

When multiple laws block an action:

```bash
# See all violations at once
./commands/chp-scan

# Fix in priority order:
# 1. error severity (blocking)
# 2. warn severity (non-blocking but tracked)
# 3. info severity (informational)
```

## Escalation Path

### Can't Fix the Violation?

If the law seems wrong or too restrictive:

1. **Check the law's intent** — Read `law.json` to understand why it exists
2. **Discuss with team** — Laws reflect team standards
3. **Adjust the law** — Use `chp:write-laws` to modify patterns, severity, or scope
4. **Disable temporarily** — `chp-law disable` while you decide

### Law Blocking Valid Work?

If a law blocks something that should be allowed:
1. Is there an existing exemption? Check `exclude` in law.json
2. Should there be an exemption? Add file patterns to `exclude`
3. Is the pattern too broad? Narrow it in verify.sh
4. Is the severity wrong? Change `error` to `warn` in law.json

## Reference: All Investigation Commands

| Command | Purpose |
|---------|---------|
| `./commands/chp-audit <law>` | Show violation history |
| `./commands/chp-law list` | List all laws |
| `./commands/chp-law test <law>` | Test a law |
| `cat docs/chp/laws/<law>/guidance.md` | Read what the law checks |
| `cat docs/chp/laws/<law>/verify.sh` | See detection logic |
| `./commands/chp-scan` | Scan for all violations |
