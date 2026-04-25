---
name: chp:scan-repo
description: Scan entire repository for potential violations in dry-run mode
---

# CHP Repository Scanner

Scan the entire repository for potential violations of CHP traffic laws without making any modifications.

## Usage

Invoke this skill when:
- User wants to check codebase for violations
- User asks about code quality or compliance issues
- Pre-commit or general repository health check is needed
- User wants to see violation report before committing

## Scanning Process

1. **Load all enabled CHP traffic laws** from `docs/chp/laws/`
2. **Parse law metadata** (severity, enabled status, hooks)
3. **Scan all tracked files** (not just staged files)
4. **Collect violations** with file paths and context
5. **Generate violation report** with counts and severity

## Running the Scan

Use the `chp-scan` command:

```bash
# Scan all laws against all files
./commands/chp-scan

# Scan for specific law violations
./commands/chp-scan --law=no-console-log
```

## Output

The scanner provides:
- **Law name and description**
- **Severity level** (error, warning, info)
- **Historical failure count** (from law.json)
- **Current violation count** (from scan)
- **List of violating files** with paths
- **Total summary** of all violations

## Violation Types

- **speeding**: Code that's too complex or doing too much
- **reckless-driving**: Dangerous patterns (security risks, anti-patterns)
- **running-red-lights**: Skipping required steps (error handling, validation)
- **improper-lane-change**: Inconsistent patterns or abrupt style changes

## Dry-Run Mode

The scanner operates in **read-only mode**:
- No files are modified
- No git operations are performed
- Only reads file contents to detect violations
- Safe to run at any time

## Fixing Violations

When violations are found:

1. **Review the violation report**
   - Note which laws were violated
   - Identify specific files with violations
   - Check severity levels

2. **Fix the issues**
   - Edit the violating files
   - Remove or fix the problematic code
   - Follow the law's guidance document

3. **Verify the fix**
   ```bash
   ./commands/chp-scan
   # or for specific law:
   ./commands/chp-scan --law=<law-name>
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "fix: resolve CHP law violations"
   ```

## Example Output

```
==================================
  CHP Repository Scanner
  Mode: DRY-RUN (read-only)
==================================

Scanning for violations of: no-console-log

  Law: no-console-log
  Severity: error
  Historical failures: 3
  Current violations: 2
  Violating files:
    - src/debug.js
    - lib/logger.js

==================================
  Scan Summary
==================================
  Laws scanned: 1
  Total violations: 2

  To fix violations:
    1. Review violating files above
    2. Fix the issues
    3. Run chp-scan again to verify
    4. Commit your changes
```

## Available Laws

To see all available laws:

```bash
./commands/chp-law list
```

To view guidance for a specific law:

```bash
cat docs/chp/laws/<law-name>/guidance.md
```

## Integration with CI/CD

The scanner can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Scan for CHP violations
  run: ./commands/chp-scan
```

## Notes

- The scanner checks **all tracked files**, not just staged changes
- Disabled laws are **skipped** during scanning
- The scan is **fast** and can be run frequently
- Use specific law scanning to focus on particular issues
