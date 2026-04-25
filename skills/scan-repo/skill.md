---
name: scan-repo
description: Scan repository for CHP law violations
---

# Scan Repository for Violations

## When to Use

- User asks to check code quality or scan for violations
- Before a commit, PR, or release
- User says "scan", "check", "enforce", or "violations"

## Process

1. Read `laws/chp-laws.txt` from the project root
2. Parse each law block (delimited by `# === Law: <id> ===`)
3. For each law, extract: `intent`, `violation` (regex), `exclusion` (regex, optional), `reaction`
4. Scan relevant source files (skip `node_modules`, `.git`, `dist`, `build`, binary files, images, lock files)
5. For each file, test each line against each law's `violation` regex
6. Skip lines that match any of the law's `exclusion` patterns
7. Collect and report all violations

## Auto-Tightening (for `block` or `auto_fix` reactions)

When a violation is found during code generation:

1. Attempt to fix the violating code
2. If the violation was a false positive, add an `exclusion:` line to the law in `laws/chp-laws.txt`
3. Re-check — repeat up to 3 attempts
4. If all 3 fail, report to the user and stop

## Output Format

No violations:
```
All code passes N laws. Scanned M files.
```

Violations found:
```
[block] no-api-keys — src/config.js:12
  Hardcoded API key detected
[warn] no-todo-comments — src/utils.ts:45
  TODO comment found
```

## Law Format Reference

```
# === Law: <id> ===
intent: <what this law enforces>
violation: <regex>
exclusion: <optional regex to skip false positives>
reaction: block|warn|auto_fix
```
