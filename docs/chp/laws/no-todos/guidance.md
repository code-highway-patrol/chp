# Law: no-todos

**Severity:** error
**Created:** 2026-04-25T05:35:44Z
**Hooks:** pre-commit, pre-push, pre-tool
**Failures:** 0

## Purpose

Prevents TODO, FIXME, HACK, XXX, and NOTE comments from being committed. These comments represent incomplete work, known issues, or temporary solutions that should be addressed before code is merged.

## Guidance

**Do not commit TODO comments.** Instead:
1. Create a ticket/issue for the work
2. Complete the work before committing
3. Use a feature branch to track in-progress work

### Examples

#### Good Practice ✅

```javascript
// File completed with full implementation
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + item.price, 0);
}

// Reference external tracking
// See issue #42 for future performance optimization
```

#### Bad Practice ❌ (will fail verification)

```javascript
function calculateTotal(items) {
    // TODO: Add tax calculation
    // FIXME: This doesn't handle edge cases
    return items.reduce((sum, item) => sum + item.price, 0);
}

// HACK: Quick fix for the demo
// XXX: Need to refactor this later
// NOTE: This is a temporary solution
```

## Detection Patterns

The following comment patterns are blocked (case-insensitive):
- `TODO`
- `FIXME`
- `HACK`
- `XXX`
- `NOTE`

## Remediation

If this law fails:

1. **Review the violation** - Check which file contains the TODO comment
2. **Choose an action:**
   - Complete the work and remove the TODO
   - Create a ticket and reference it instead
   - Move the work to a separate branch
3. **Remove the TODO comment** from your code
4. **Verify the fix:**
   ```bash
   ./commands/chp-law test no-todos
   ```
5. **Commit your changes**

## Exceptions

For legitimate documentation that uses these words:
- Use alternative phrasing: "See ticket #123" instead of "TODO #123"
- Keep documentation in separate README files (not in code)
- Use issue tracker comments for project notes

---

*This guidance will be automatically strengthened if violations occur.*

---

**Violation recorded:** 2026-04-25T09:02:03Z (Total: 1)

This law has been violated 1 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:03:25Z (Total: 2)

This law has been violated 2 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**
