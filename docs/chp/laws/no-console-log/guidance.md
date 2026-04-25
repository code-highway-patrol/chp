# Law: no-console-log

**Severity:** error
**Created:** 2026-04-25T04:05:10Z
**Failures:** 0

## Purpose

This law prevents `console.log()` statements from being committed to the repository. Console.log statements are often used for debugging but should not be present in production code. They can:

- Expose sensitive information in browser consoles
- Impact performance in production environments
- Clutter console output, making legitimate logs harder to find
- Create inconsistent debugging experiences across environments

## What Gets Checked

The pre-commit hook scans all staged files (except documentation and config files) for:
- `console.log(...)` patterns in the staged diff
- Only checks lines that are being added or modified
- Skips files with extensions: `.md`, `.json`, `.txt`, `.sh`, `.yml`, `.yaml`, `.lock`, `.gitignore`

## How to Comply

### Acceptable Alternatives

#### 1. Use a Proper Logging Library
```javascript
// Instead of:
console.log('User logged in', user);

// Use a logging library:
logger.info('User logged in', { userId: user.id });
```

#### 2. Use Debug Flags with Proper Libraries
```javascript
// Use debug library with environment-based toggling:
import debug from 'debug';
const log = debug('app:auth');

log('Authentication attempt'); // Only logs when DEBUG env var is set
```

#### 3. Remove Debug Statements Before Committing
```javascript
// During development:
// console.log('API response:', data); // Comment out or remove

// Before committing, remove or uncomment the line
```

#### 4. Use Proper Error Handling
```javascript
// Instead of:
console.log('Error fetching data:', error);

// Use proper error handling:
logger.error('Failed to fetch user data', {
  error: error.message,
  stack: error.stack,
  userId: userId
});
```

### Examples

#### Bad Practice (will fail verification)
```javascript
// Direct console.log calls
console.log('Debugging user state');
console.log('API returned:', response);

// Even with useful messages
console.log('Processing payment for order:', orderId);
```

#### Good Practice
```javascript
// Using proper logging
import logger from './lib/logger';

logger.info('Processing payment', { orderId });
logger.debug('User state', { state: userState });

// Error handling
try {
  await processPayment(orderId);
} catch (error) {
  logger.error('Payment processing failed', { orderId, error: error.message });
  throw error;
}
```

## Detection Patterns

The verification script searches for the literal pattern `console.log` in:
- JavaScript files (`.js`, `.jsx`)
- TypeScript files (`.ts`, `.tsx`)
- Any other code files that are staged for commit

It does NOT detect:
- `console.error()` (use sparingly and appropriately)
- `console.warn()` (use for warnings)
- `console.debug()` (use debug libraries instead)
- Comments containing "console.log" (e.g., `// TODO: remove console.log`)

## Remediation

If this law fails during a commit:

1. **Identify the violation**: The hook will show which files contain `console.log`
2. **Find the statements**: Search for `console.log` in the indicated files
3. **Choose a solution**:
   - Remove the statement if it's just debugging
   - Replace with proper logging if it's important
   - Comment it out with a TODO if you need it temporarily
4. **Stage your changes**: `git add <files>`
5. **Commit again**: The verification will run automatically

## Why This Exists

This is an example law demonstrating the CHP (Code Handbook and Policies) system. It shows how to:
- Enforce code quality standards through automated checks
- Provide clear guidance when violations occur
- Scale governance across a team without manual code reviews

The principle applies to many similar patterns:
- `debugger` statements
- `TODO` comments without tickets
- Hardcoded API keys or secrets
- Deprecated function calls

---

*This guidance will be automatically strengthened if violations occur.*

---

**Violation:** 2026-04-24T14:30:00Z
**Context:** Found console.log in src/app.js line 45
**Pattern:** `console.log('User data:', user);`
**Remediation:** Replaced with logger.info()

---

**Violation:** 2026-04-24T15:45:00Z
**Context:** Found console.log in src/utils/api.js line 123
**Pattern:** `console.log('API response:', data);`
**Remediation:** Replaced with logger.debug()

---

**Violation:** 2026-04-24T16:20:00Z
**Context:** Found console.log in src/components/Header.jsx line 78
**Pattern:** `console.log('Header mounted');`
**Remediation:** Removed debug statement

---

**Violation recorded:** 2026-04-25T04:19:16Z (Total: 4)

This law has been violated 4 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T04:19:55Z (Total: 5)

This law has been violated 5 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T04:23:34Z (Total: 6)

This law has been violated 6 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**

---

**Violation recorded:** 2026-04-25T04:27:06Z (Total: 7)

This law has been violated 7 time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**
