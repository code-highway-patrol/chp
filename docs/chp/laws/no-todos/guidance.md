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

---

**Violation recorded:** 2026-04-25T09:43:48Z (Total: 3)

This law has been violated 3 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:44:24Z (Total: 4)

This law has been violated 4 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:45:09Z (Total: 5)

This law has been violated 5 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:46:01Z (Total: 6)

This law has been violated 6 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:46:22Z (Total: 7)

This law has been violated 7 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:46:46Z (Total: 8)

This law has been violated 8 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:47:26Z (Total: 9)

This law has been violated 9 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:49:00Z (Total: 10)

This law has been violated 10 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:49:21Z (Total: 11)

This law has been violated 11 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:49:42Z (Total: 12)

This law has been violated 12 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:50:13Z (Total: 13)

This law has been violated 13 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:51:28Z (Total: 14)

This law has been violated 14 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T09:53:14Z (Total: 15)

This law has been violated 15 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T19:59:09Z (Total: 16)

This law has been violated 16 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:01:06Z (Total: 17)

This law has been violated 17 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:02:14Z (Total: 18)

This law has been violated 18 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:02:52Z (Total: 19)

This law has been violated 19 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:04:33Z (Total: 20)

This law has been violated 20 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:06:24Z (Total: 21)

This law has been violated 21 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:07:23Z (Total: 22)

This law has been violated 22 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:07:27Z (Total: 23)

This law has been violated 23 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:09:46Z (Total: 24)

This law has been violated 24 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:11:49Z (Total: 25)

This law has been violated 25 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T20:12:04Z (Total: 26)

This law has been violated 26 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T21:22:04Z (Total: 27)

This law has been violated 27 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**
