---
name: scan-repo
description: Scan repository for CHP law violations using subjective judgment
---

# Scan Repository for Violations

## When to Use

- User asks to check code quality or scan for violations
- Before a commit, PR, or release
- User says "scan", "check", "enforce", or "violations"

## Process

1. Read `laws/chp-laws.txt` in the project root
2. Parse each law block (delimited by `# === Law: <id> ===`)
3. For each law, read its `intent` — this is the rule to enforce
4. Scan relevant source files (skip `node_modules`, `.git`, `dist`, `build`, binary/image/lock files)
5. For each file, subjectively judge whether the code violates any law's **intent**
6. Use your judgment — this is not regex matching, it's a qualitative assessment of whether the code breaks the spirit of the law

## When Violations Are Found

For each violation:
1. Report the file, the law violated, and a brief explanation of why
2. Rewrite the file to fix the violation
3. Open `laws/chp-laws.txt` and update the violated law's `intent` to be more strict and explicit, incorporating what you learned from this violation

## Output Format

No violations:
```
All code passes N laws. Scanned M files.
```

Violations found:
```
[block] no-hardcoded-secrets — src/config.js
  API key hardcoded on line 12. Moved to environment variable.
  Law updated: added "tokens" and "connection strings" to intent.
```

## Law Format Reference

```
# === Law: <id> ===
intent: <plain-language description of what this law prohibits>
reaction: block|warn
```
