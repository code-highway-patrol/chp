# Law: Test Scope

**Severity:** Warn
**Action:** Logs warning, does not block

## What this means
This is a test law for verifying CHP's scope filtering system. It only applies to TypeScript files and checks for `TODO` comments within them.

## How to comply
- Remove `TODO` comments from TypeScript files
- Replace with issue references: `// See issue #42`

## Detection
Scans for pattern: `TODO` in files matching `**/*.ts`

## Scope
- **Include:** `**/*.ts` (TypeScript files only)
- **Exclude:** None
