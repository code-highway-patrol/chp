# Required Scope Fields for CHP Laws

**Date:** 2026-04-25
**Status:** Approved
**Issue:** Laws don't specify what file scope they apply to, causing all laws to run on all staged files by default.

## Problem

CHP laws currently run against all staged files by default. The `verifier.sh` runtime supports `include`/`exclude` glob arrays in `law.json`, but:
1. The schema doesn't define these fields
2. Validation doesn't require them
3. The `chp:write-laws` skill doesn't prompt for them
4. No existing law declares scope

This means every law's `verify.sh` must implement its own file filtering internally, which is inconsistent and inefficient.

## Solution

Make `include`/`exclude` first-class, required fields in `law.json` for all laws that run on git hooks (pre-commit, pre-push, post-commit, commit-msg, etc.). Agent-only laws (pre-tool, post-tool, pre-response, post-response) are exempt since they don't have file context.

## Design

### 1. Schema & Validation

**law.schema.json** — add `include` and `exclude` as optional array properties:

```json
"include": {
  "type": "array",
  "items": { "type": "string" },
  "description": "Glob patterns for files this law applies to. Required for git-hook laws."
},
"exclude": {
  "type": "array",
  "items": { "type": "string" },
  "description": "Glob patterns exempt from this law."
}
```

**validate_law_json()** in `core/common.sh` — add conditional validation:
- If any hook in `.hooks[]` is a git hook, require `include` to be present and non-empty
- Agent-only hooks are exempt from the scope requirement
- No changes to `verifier.sh` — it already reads top-level `.include`/`.exclude` correctly

### 2. Migrate Existing Laws

Add `include` arrays to existing laws based on what they actually check:

| Law | `include` | Rationale |
|-----|-----------|-----------|
| `no-console-log` | `["**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx", "**/*.mjs"]` | JS/TS source files |
| `no-api-keys` | `["**/*"]` | Secrets can be in any file type |
| `no-todos` | `["**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx", "**/*.py", "**/*.go", "**/*.rs", "**/*.java"]` | Source code files (md/json already excluded by check's skip_extensions) |
| `no-alerts` | `["**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx"]` | Browser JS only |
| `mandarin-only` | _(exempt)_ | Agent-only hooks, no file context |
| `commit-metrics` | _(exempt)_ | post-commit only, no file scanning |
| `test-scope` | `["**/*.ts"]` | Already documented as TypeScript-only |

### 3. CLI & Skill Updates

**chp:write-laws skill** — when creating a law with git hooks, prompt for include patterns before generating law.json. If user doesn't specify, default to `["**/*"]` with a warning that specific scoping improves performance.

**chp-law create** — add `--include` and `--exclude` flags:
```bash
chp-law create my-law --hooks=pre-commit --include="**/*.js,**/*.ts"
```
When creating a git-hook law without `--include`, emit a warning and default to `["**/*"]`.

**chp-law update** — allow updating include/exclude arrays:
```bash
chp-law update my-law --include="**/*.ts" --exclude="**/*.test.ts"
```

## Implementation Notes

- The `verifier.sh` runtime already supports top-level `include`/`exclude` — no changes needed
- Scope filtering happens before `verify.sh` runs, so laws only see relevant files
- Laws that truly apply to everything use `["**/*"]`
- Agent-only laws skip the scope requirement since `check_law_scope()` already handles hooks without file context

## Success Criteria

1. All git-hook laws have a non-empty `include` array
2. `validate_law_json()` rejects git-hook laws without `include`
3. `chp-law create` prompts or warns about scope when creating git-hook laws
4. Existing laws are migrated with appropriate scopes
5. No changes needed to `verifier.sh` — runtime already handles it
