# Law: Commit Metrics

**Severity:** Info
**Action:** Non-blocking metrics collection

## What this means

This law tracks commit metrics to provide insights into development activity.

## Data Collected

- Total number of commits
- Total files changed across commits

## Location

Metrics stored in: `.chp/commit-metrics.json`

## Viewing Metrics

```bash
cat .chp/commit-metrics.json
```

## Disabling

To disable metrics collection:

```bash
./commands/chp-hooks disable post-commit
```

## Technical Details

This law runs on the `post-commit` hook, which fires after a commit is successfully created. It:

1. Initializes the metrics file if it doesn't exist
2. Increments the commit counter
3. Counts the number of files changed in the commit
4. Updates the total files changed counter
5. Displays a summary to the user

The law is non-blocking (always exits 0) and does not affect the commit process.
