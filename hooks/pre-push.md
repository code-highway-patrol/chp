---
name: pre-push
description: Run full CHP analysis before pushing to remote
trigger:
  event: pre-push
  enabled: true
---

# CHP Pre-Push Hook

Run comprehensive Code Highway Patrol analysis before pushing to remote repository.

## Configuration

Configure in `.claude/settings.json`:

```json
{
  "hooks": {
    "pre-push": {
      "enabled": true,
      "scope": "full",
      "failOn": ["error", "warning"],
      "maxWarnings": 10
    }
  }
}
```

## Behavior

1. Run full codebase analysis
2. Check all files against registered CHP laws
3. Aggregate findings across entire project
4. Block push if threshold exceeded

## Scope Levels

- **full**: Analyze entire codebase
- **incremental**: Analyze only changed files since last push
- **affected**: Analyze files affected by current branch changes

## Exit Codes

- `0`: All checks passed, push allowed
- `1`: Issues found exceeding threshold
- `2`: Configuration or runtime error

## Output Format

```
CHP Pre-Push Analysis
=====================

Analyzing 142 files...
Found 15 issues (3 errors, 12 warnings)

Errors:
  src/auth.js:45 - Hardcoded API key
  lib/db.js:123 - SQL injection risk
  api/routes.js:67 - Missing auth check

Warnings (showing first 5 of 12):
  src/utils.js:89 - Complex function
  ...

Push blocked: 3 errors found.
Run 'chp check' for details or use --no-verify to bypass.
```
