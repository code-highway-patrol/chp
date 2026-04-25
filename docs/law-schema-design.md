# Law Schema Enhancements

## New Fields

### Scope Control
- `include?: string[]` - Glob patterns of files/directories this law applies to
- `exclude?: string[]` - Glob patterns to exempt from this law (overrides include)

### Metadata
- `tags?: string[]` - Categories for organizing/filtering laws (e.g., "security", "performance", "style")
- `priority?: number` - Higher priority wins when multiple laws conflict (default: 0)
- `author?: string` - Law owner/team
- `documentation?: string` - URL or path to extended documentation
- `version?: string` - Semantic version for tracking law evolution

### Lifecycle
- `createdAt?: string` - ISO 8601 timestamp
- `updatedAt?: string` - ISO 8601 timestamp
- `expiresAt?: string` - ISO 8601 timestamp for temporary laws

### Conditions
- `enabled?: boolean` - Quick disable without deleting (default: true)
- `environment?: string[]` - Environments where law applies (e.g., "production", "development")
- `dependsOn?: string[]` - Other law IDs that must be satisfied first

### Enforcement
- `severity?: 'error' | 'warn' | 'info'` - Already exists in JSON, add to TS interface
- `hooks?: HookType[]` - Already exists in JSON, add to TS interface
- `failures?: number` - Runtime tracking (not stored in schema)
- `tightening_level?: number` - Runtime tracking (not stored in schema)

## Example Law with New Fields

```json
{
  "id": "no-api-keys",
  "name": "no-api-keys",
  "intent": "Prevent API keys from being committed to the repository",
  "violations": [
    {
      "pattern": "fileContains(/sk_|AIza|AKIA/, content)",
      "fix": "Remove API key and use environment variable",
      "satisfies": "!fileContains(/sk_|AIza|AKIA/, content)"
    }
  ],
  "reaction": "block",
  "include": ["**/*.ts", "**/*.js", "**/*.json"],
  "exclude": ["**/examples/**", "**/*.example.json"],
  "tags": ["security", "secrets"],
  "priority": 100,
  "author": "security-team",
  "documentation": "/docs/security/api-key-handling.md",
  "version": "1.2.0",
  "createdAt": "2026-04-25T05:02:04Z",
  "updatedAt": "2026-04-25T05:02:04Z",
  "environment": ["production", "staging"],
  "enabled": true,
  "hooks": ["pre-commit", "pre-push", "pre-tool"],
  "severity": "error"
}
```

## Scope Matching Logic

1. If `include` is empty or undefined → law applies to all files
2. If `include` has patterns → file must match at least one pattern
3. If `exclude` has patterns → file must NOT match any pattern (overrides include)

```typescript
function matchesScope(filePath: string, law: Law): boolean {
  // Empty include means all files
  const matchesInclude = !law.include || law.include.length === 0 ||
    law.include.some(pattern => minimatch(filePath, pattern));

  const matchesExclude = law.exclude && law.exclude.length > 0 &&
    law.exclude.some(pattern => minimatch(filePath, pattern));

  return matchesInclude && !matchesExclude;
}
```
