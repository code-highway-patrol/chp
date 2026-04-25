---
name: pre-commit
description: Run CHP analysis on staged files before commit
trigger:
  event: pre-commit
  enabled: true
---

# CHP Pre-Commit Hook

Run Code Highway Patrol analysis on staged files before allowing commit.

## Configuration

Configure in `.claude/settings.json`:

```json
{
  "hooks": {
    "pre-commit": {
      "enabled": true,
      "severity": "warning",
      "failOn": ["error"],
      "skipPatterns": ["*.min.js", "package-lock.json"]
    }
  }
}
```

## Behavior

1. Detect staged files using git
2. Filter files based on CHP law patterns
3. Run applicable checks on each file
4. Report findings and optionally block commit

## Exit Codes

- `0`: All checks passed, commit allowed
- `1`: Errors found (if failOn includes "error")
- `2`: Configuration or runtime error

## Output Format

```
CHP Pre-Commit Analysis
========================

✓ src/utils.js - No issues
✗ src/auth.js - 2 errors
  Line 45: Hardcoded API key (severity: error)
  Line 78: Missing error handling (severity: warning)

Found 2 issues. Commit blocked by errors.
Use --no-verify to bypass (not recommended).
```
