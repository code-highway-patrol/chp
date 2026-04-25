---
name: post-analysis
description: Process and store CHP analysis results for historical tracking
trigger:
  event: post-analysis
  enabled: true
---

# CHP Post-Analysis Hook

Process and store analysis results for trend tracking and continuous improvement.

## Behavior

This hook runs after CHP analysis to:
1. Store analysis results in local cache
2. Update trend metrics over time
3. Identify recurring violations
4. Suggest law updates based on patterns

## Stored Data

- Analysis timestamp and scope
- Total findings by severity
- Violations per law
- Files with most issues
- Trend indicators (improving/worsening)

## Usage

Results are stored in `.claude/cache/chp-metrics.json`:

```json
{
  "lastAnalysis": "2026-04-24T20:00:00Z",
  "trend": "improving",
  "violations": {
    "total": 15,
    "byLaw": {
      "js-security": 3,
      "js-style": 8,
      "js-complexity": 4
    }
  },
  "topFiles": [
    {"path": "src/auth.js", "issues": 5},
    {"path": "lib/db.js", "issues": 3}
  ]
}
```

## Notifications

Hook can trigger notifications when:
- New critical issues are introduced
- Trend significantly worsens
- A file exceeds issue threshold
