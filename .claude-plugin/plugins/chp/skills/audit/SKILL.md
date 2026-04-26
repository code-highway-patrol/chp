---
name: audit
description: Scan codebase for CHP violations and assess code health. Triggers on "audit", "scan", "check code", "code quality", "violations", "issues", "health check", "how's the code", "any problems", "review codebase", "scan for issues".
---

# CHP Codebase Audit

Scan the entire repository for CHP law violations and get a comprehensive report on code health.

## When to Invoke

Invoke this skill when:
- User asks "how's our code quality?", "how's the codebase?"
- User asks "are there violations?", "do we have any issues?", "what's broken?"
- User says "audit the code", "scan for problems", "check for violations"
- Pre-commit or PR review time
- Onboarding to a new codebase
- Periodic code health check
- Before releasing or deploying
- User wants to know the current state of the codebase

## Running the Audit

### Basic Scan

```bash
# Scan all laws against all tracked files
./commands/chp-scan
```

Output format:
```
==================================
  CHP Repository Scanner
  Mode: DRY-RUN (read-only)
==================================

Scanning for violations of: no-console-log

  Law: no-console-log
  Severity: error
  Historical failures: 7
  Current violations: 3
  Violating files:
    - src/debug.js
    - lib/logger.js
    - app/index.js

==================================
SUMMARY: 3 laws scanned, 12 violations found
```

### Filtered Scans

```bash
# Scan for a specific law only
./commands/chp-scan --law=no-console-log

# Scan only specific files or directories
./commands/chp-scan src/ lib/

# Scan with severity filter
./commands/chp-scan --severity=error    # Only blocking violations
./commands/chp-scan --severity=warn     # Warnings and errors
```

### Output Formats

```bash
# JSON output for parsing
./commands/chp-scan --json

# Verbose with full details
./commands/chp-scan --verbose

# Quiet (exit code only, for scripts)
./commands/chp-scan --quiet
```

## Interpreting Results

### Understanding Severity

| Severity | Meaning | Action Required |
|----------|---------|-----------------|
| **error** | Blocks commits, must fix | Immediate action |
| **warn** | Logged but passes | Should fix soon |
| **info** | Informational only | Optional |

### Prioritization Strategy

Fix violations in this order:

1. **Error severity** — Blocks commits, must fix first
2. **High historical failure count** — Recurring problem
3. **High current violation count** — Widespread issue

Example prioritized output:
```
Priority Queue:
  [1] no-api-keys (error) - 1 violation        # FIX FIRST (blocking)
  [2] no-console-log (error) - 7 violations    # FIX SECOND (widespread)
  [3] max-line-length (warn) - 12 violations   # FIX THIRD (non-blocking)
```

## Fixing Violations

### Process

1. **Review the violation report**
   ```bash
   ./commands/chp-scan --law=no-console-log
   ```

2. **Read the law's guidance**
   ```bash
   cat docs/chp/laws/no-console-log/guidance.md
   ```

3. **Fix the issues**
   Edit the violating files to comply with the law

4. **Re-scan to verify**
   ```bash
   ./commands/chp-scan --law=no-console-log
   ```

5. **Test the specific law**
   ```bash
   ./commands/chp-law test no-console-log
   ```

6. **Commit your changes**
   ```bash
   git add .
   git commit -m "fix: resolve CHP law violations"
   ```

### Bulk Fixes

For laws with many violations (50+):

1. **Fix in batches** of 10-20 files
2. **Re-scan after each batch**
   ```bash
   ./commands/chp-scan --law=<law-name>
   ```
3. **Don't introduce new violations** while fixing

### Example Fix Session

```bash
# 1. Initial scan
./commands/chp-scan
# Output: 47 console.log violations

# 2. Fix first batch (src/*.js)
# ... edit files ...

# 3. Re-scan
./commands/chp-scan --law=no-console-log
# Output: 32 violations remaining

# 4. Continue until done
./commands/chp-scan
# Output: 0 violations
```

## CI/CD Integration

### GitHub Actions

```yaml
name: CHP Audit
on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check CHP violations
        run: ./commands/chp-scan --severity=error
      # Fail build on error violations
```

### GitLab CI

```yaml
chp-audit:
  script:
    - ./commands/chp-scan --severity=error
  allow_failure: false
```

### Pre-commit Hook

Add to your workflow before committing:

```bash
# Quick scan before committing
./commands/chp-scan

# Fix any violations, then commit
git commit
```

### PR Description Template

Include audit results in PR descriptions:

```markdown
## CHP Audit Results

\`\`\`
./commands/chp-scan
\`\`\`

- [ ] All error violations fixed
- [ ] Warning violations noted
```

## Workflow Integration

### Pre-Commit Workflow

```bash
# 1. Make your changes
git checkout -b feature/xyz

# 2. Quick scan
./commands/chp-scan

# 3. Fix violations
# ... edit files ...

# 4. Verify
./commands/chp-scan

# 5. Commit
git commit -m "feat: xyz"
```

### PR Review Workflow

```bash
# 1. Scan your branch
./commands/chp-scan

# 2. Include results in PR
./commands/chp-scan --json > pr-audit.json

# 3. Address review comments
# ... edit files ...

# 4. Final scan before merge
./commands/chp-scan
```

## Advanced Usage

### Generate Reports

```bash
# Save audit to file
./commands/chp-scan > audit-$(date +%Y%m%d).txt

# Compare audits over time
diff audit-20260401.txt audit-20260426.txt
```

### Filter by File Pattern

```bash
# Only scan TypeScript files
./commands/chp-scan --include="**/*.ts"

# Exclude test files
./commands/chp-scan --exclude="**/*.test.ts,**/*.spec.ts"
```

### Export Metrics

```bash
# Get violation counts by law
./commands/chp-scan --json | jq '.laws | map({name: .name, count: .violations})'
```

## Notes

- The scanner is **read-only** — no files are modified
- Disabled laws are **skipped** during scanning
- Results are a **current snapshot** — historical failures are in law.json
- Exit code 0 means no error violations found
- Exit code 1 means at least one error violation found

## Related Skills

- **chp:investigate** — Debug specific violations when you need deeper understanding
- **chp:status** — See what laws are enforced and how they work
- **chp:write-laws** — Create or adjust laws that have too many false positives
