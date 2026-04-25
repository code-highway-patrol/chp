---
name: chp-audit
description: Scan codebase for CHP violations and assess code health
---

# CHP Codebase Audit

Scan the entire repository for CHP law violations and get a comprehensive report on code health.

## When to Invoke

Invoke this skill when:
- User asks "how's our code quality?"
- User asks "are there violations?" or "do we have any issues?"
- Pre-commit or PR review time
- Onboarding to a new codebase
- Periodic code health check
- Before releasing or deploying

## Running the Audit

Use the `chp-scan` command to scan all tracked files:

```bash
# Scan all laws against all files
./commands/chp-scan

# Scan for a specific law only
./commands/chp-scan --law=<law-name>
```

## Interpreting Results

### Output Format

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
```

### Prioritization Strategy

Fix violations in this order:

1. **Error severity** - Blocks commits, must be fixed
2. **High historical failure count** - Recurring problem
3. **High current violation count** - Widespread issue

### Example Prioritization

```
Results:
  no-api-keys (error) - 1 violation        # FIX FIRST (blocking)
  no-console-log (error) - 7 violations    # FIX SECOND (widespread)
  max-line-length (warn) - 12 violations   # FIX THIRD (non-blocking)
```

## Fixing Violations

### Process

1. **Review the violation report** - Note which files violate
2. **Read the law's guidance** - Understand what to fix
   ```bash
   cat docs/chp/laws/<law-name>/guidance.md
   ```
3. **Fix the issues** - Edit the violating files
4. **Re-scan to verify**
   ```bash
   ./commands/chp-scan --law=<law-name>
   ```
5. **Test the specific law after fixing**
   ```bash
   ./commands/chp-law test <law-name>
   ```
6. **Commit your changes**
   ```bash
   git add .
   git commit -m "fix: resolve CHP law violations"
   ```

### Bulk Fixes

For laws with many violations (e.g., 50+ console.log statements):

1. Fix in batches of 10-20 files
2. Re-scan after each batch: `./commands/chp-scan --law=<law-name>`
3. Don't introduce new violations while fixing

## Integration with Workflows

### Pre-Commit

Add to your workflow before committing:

```bash
# Quick scan before committing
./commands/chp-scan

# Fix any violations, then commit
git commit
```

### PR Reviews

Before creating a PR:

```bash
# Scan for violations in your branch
./commands/chp-scan

# Include results in PR description
```

### CI/CD

Add to CI pipeline:

```yaml
- name: Check CHP violations
  run: ./commands/chp-scan
```

## Notes

- The scanner is read-only - no files are modified
- Disabled laws are skipped during scanning
- Results are current snapshot - historical failures are in law.json

## Related Skills

- **chp:investigate** - Debug specific violations when you need deeper understanding
