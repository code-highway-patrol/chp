# no-console-log Law Guidance

## What This Law Enforces

This law prevents `console.log()` statements from being committed to the repository.

## Why This Matters

Debug logging statements left in production code:
- Clutter console output and make debugging harder
- May expose sensitive information in browser consoles
- Create noise in server logs
- Are the most-violated CHP law (11 failures)

## How to Fix

Replace `console.log()` with proper logging:

```javascript
// ❌ BAD
console.log('User logged in', user);
console.error('API error:', error);

// ✅ GOOD
logger.info('User logged in', { userId: user.id });
logger.error('API error:', { error: error.message, stack: error.stack });
```

## Auto-Fix Behavior

This law has `autoFix: "ask"` enabled. When violations are detected:
1. CHP will show you the diff of proposed changes
2. You'll be prompted to confirm before any changes are applied
3. Auto-fix replaces `console.log()` with `logger.info()`
4. Auto-fix replaces `console.error()` with `logger.error()`
5. Auto-fix replaces `console.warn()` with `logger.warn()`

## Exceptions

Files in these directories are excluded:
- `node_modules/`
- `dist/`, `build/`, `.next/`
- `coverage/`

Add more exclusions in `law.json` if needed for specific files or patterns.

---

**Violation recorded:** 2026-04-26T03:39:07Z (Total: 1)

This law has been violated 1 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-26T03:39:11Z (Total: 2)

This law has been violated 2 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-26T03:45:36Z (Total: 3)

This law has been violated 3 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-26T03:55:42Z (Total: 4)

This law has been violated 4 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-26T03:56:45Z (Total: 5)

This law has been violated 5 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**
