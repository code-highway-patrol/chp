# Law: no-alerts

**Severity:** warn
**Created:** 2026-04-25T07:52:32Z
**Failures:** 0

## Purpose

This law prevents the use of `alert()` in JavaScript/TypeScript files. Alert dialogs block execution and provide poor user experience.

## Guidance

Use proper UI feedback mechanisms instead of alert():
- Toast notifications for non-critical messages
- Modal dialogs for confirmations
- Console logging for debugging
- Proper error boundaries for error handling

### Examples

#### Good Practice
```typescript
// Use toast notifications
showToast("File saved successfully");

// Use modal for confirmation
confirmDialog("Are you sure you want to delete?");

// Use console for debugging
console.debug("API response:", data);
```

#### Bad Practice (will fail verification)
```javascript
// Don't use alert
alert("File saved!");

// Don't use alert for errors
alert("Error: " + errorMessage);
```

## Remediation

If this law fails:
1. Find the `alert()` call in your staged files
2. Replace with appropriate UI component (toast, modal, etc.)
3. Re-run the verification
4. Commit your changes

---

*This guidance will be automatically strengthened if violations occur.*
