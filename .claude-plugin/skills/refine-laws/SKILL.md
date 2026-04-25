---
name: refine-laws
description: Tune existing CHP laws based on new requirements or feedback
---

# CHP Law Refinement

Adjust and tune existing CHP laws when they need updating due to false positives, new requirements, or changing team standards.

## When to Invoke

Invoke this skill when:
- A law has too many false positives
- A law needs new violation patterns
- You want to change a law's severity
- A law's hooks need adjustment
- A law is outdated or no longer relevant
- Team standards have changed

## Law Structure

Each law has three components:

```
docs/chp/laws/<law-name>/
├── law.json       # Metadata (severity, hooks, enabled status)
├── verify.sh      # Verification logic (what to check)
└── guidance.md    # Human-readable documentation
```

## Refinement Scenarios

### Scenario 1: Reduce False Positives

**Problem:** Law flags things that shouldn't be violations

**Example:** `no-console-log` flags `console.error` which you need for error tracking

**Solution:** Edit `verify.sh` to exclude the pattern

```bash
# Edit the verification script
vim docs/chp/laws/no-console-log/verify.sh

# Change the pattern to exclude console.error
# Before: grep -q 'console\.log'
# After: grep -q 'console\.log' | grep -v 'console\.error'
```

**Test the change:**
```bash
./commands/chp-law test no-console-log
```

### Scenario 2: Change Severity

**Problem:** Law is too strict or too lenient

**Example:** `max-function-length` should warn, not error

**Solution:** Edit `law.json`

```bash
# Edit the metadata
vim docs/chp/laws/max-function-length/law.json

# Change severity
# Before: "severity": "error"
# After: "severity": "warn"
```

**Test the change:**
```bash
./commands/chp-law test max-function-length
```

### Scenario 3: Add New Violation Pattern

**Problem:** Law needs to catch additional patterns

**Example:** `no-api-keys` should also catch `Bearer` tokens

**Solution:** Edit `verify.sh` to add the pattern

```bash
vim docs/chp/laws/no-api-keys/verify.sh

# Add to the patterns array
patterns+=("Bearer [A-Za-z0-9\\-._~+/]+=*")  # JWT tokens
```

**Test the change:**
```bash
./commands/chp-law test no-api-keys
```

### Scenario 4: Adjust Hooks

**Problem:** Law runs at the wrong time

**Example:** `test-coverage` should run on pre-push, not pre-commit

**Solution:** Edit `law.json`

```bash
vim docs/chp/laws/test-coverage/law.json

# Change hooks array
# Before: "hooks": ["pre-commit"]
# After: "hooks": ["pre-push"]
```

Reinstall hooks:
```bash
./commands/chp-hooks disable pre-commit
./commands/chp-hooks enable pre-push
```

### Scenario 5: Update Guidance

**Problem:** Documentation doesn't match current behavior

**Solution:** Edit `guidance.md`

```bash
vim docs/chp/laws/<law-name>/guidance.md

# Update examples, remediation steps, or context
```

### Scenario 6: Reset Failure Count

**Problem:** Law has high failure count from past issues, now fixed

**Solution:** Reset the counter

```bash
./commands/chp-law reset <law-name>
```

This resets `failures` to 0 and `tightening_level` to 0 in `law.json`.

## Testing Changes

Always test after refining a law:

```bash
# Test the verification script
./commands/chp-law test <law-name>

# If changing patterns, test with a file that should violate
echo "console.log('test')" > /tmp/test.js
./commands/chp-scan --law=<law-name>

# Verify the law still works as expected
```

## Disabling vs Deleting

### Disable Temporarily

When a law needs to be paused but might be re-enabled:

```bash
./commands/chp-law disable <law-name>
```

The law remains but won't enforce. Re-enable later:
```bash
./commands/chp-law enable <law-name>
```

### Delete Permanently

When a law is no longer needed:

```bash
./commands/chp-law delete <law-name>
```

This removes the law directory and unregisters it from all hooks.

## Before Refining

1. **Understand why the law exists** - Read the full guidance
2. **Check with team** - Laws represent team standards
3. **Consider the impact** - Changes affect everyone
4. **Document the change** - Update guidance.md with rationale

## After Refining

1. **Test thoroughly** - Use `chp-law test`
2. **Update guidance** - Document what changed and why
3. **Communicate** - Let team know about the change
4. **Monitor** - Watch for new violations/failures

## Example Workflow

```
1. Notice no-console-log flags console.error
2. Use chp:refine-laws
3. Edit verify.sh to exclude console.error
4. Test: ./commands/chp-law test no-console-log
5. Update guidance.md to document the exception
6. Commit: git commit -m "refine(no-console-log): allow console.error for error tracking"
```
