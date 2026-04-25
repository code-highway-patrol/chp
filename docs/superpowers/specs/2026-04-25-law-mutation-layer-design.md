# Law Mutation Layer Design

## Problem

CHP laws consist of three files (`law.json`, `verify.sh`, `guidance.md`) that must stay in sync. Currently, mutation operations write to files independently:

- `disable_law()` / `enable_law()` — only touches `law.json`
- `update_law()` for severity, hooks — only touches `law.json`
- `update_law()` for check severity — only `law.json`
- `update_law()` with `--add-check` — `law.json` + `verify.sh`, but not `guidance.md`
- `record_failure()` — `law.json` + `guidance.md`, skips `verify.sh`
- Only `create_law()` touches all three (but uses a generic guidance template)

This means `guidance.md` silently drifts from reality whenever law configuration changes.

## Solution

A single sourced script (`core/law-mutate.sh`) that provides atomic mutation functions for law directories. All existing write paths delegate to it — nothing else writes to law files directly.

## Architecture

### Core Script: `core/law-mutate.sh`

Sourced (not executed directly). Provides these functions:

#### `mutate_field <law_name> <field> <value>`

Updates a single field in `law.json` and syncs the corresponding section in `guidance.md`.

- Writes the field to `law.json` via `jq`
- Updates the `**Severity:**` line in guidance.md when `severity` changes
- Updates the `**Failures:**` line in guidance.md when `failures` changes
- For fields not represented in guidance.md header (e.g. `hooks`, `enabled`), only law.json is updated
- Regenerates `verify.sh` if hooks change (since verify.sh contains hook-specific logic)

#### `mutate_checks <law_name> <action> <check_json>`

Modifies the checks array and regenerates both `verify.sh` and the detection section of `guidance.md`.

Actions: `add`, `remove`, `update`

- Updates `checks[]` in `law.json`
- Regenerates `verify.sh` via existing `build_verify_with_checks`
- Appends a "Detection updated" entry to `guidance.md` noting what changed

#### `mutate_status <law_name> <enabled|disabled>`

Toggles law enforcement status across all three files.

- Sets `enabled` in `law.json`
- Updates `guidance.md` header to show status
- No change to `verify.sh` (it reads `enabled` from `law.json` at runtime)

#### `mutate_failure <law_name> [check_id]`

Records a violation across all three files. Replaces the direct writes in `record_failure()`.

- Increments `failures` and `tightening_level` in `law.json`
- Appends violation entry to `guidance.md`
- No change to `verify.sh`

#### `mutate_reset <law_name>`

Clears failure state across all three files. Replaces `reset_failures()`.

- Sets `failures` and `tightening_level` to 0 in `law.json`
- Truncates `guidance.md` at the first `---` separator (removes violation history)

#### `validate_consistency <law_name>`

Read-only check that verifies all three files agree. Returns 0 if consistent, 1 if drifted.

Checks:
- `law.json` name field matches directory name
- `law.json` severity matches guidance.md `**Severity:**` line
- `law.json` failures matches guidance.md `**Failures:**` line
- `verify.sh` exists and sources `check-runner.sh`
- `law.json` checks array is non-empty (if verify.sh uses `run_checks`)

### Integration Points

#### `core/tightener.sh`

`record_failure()` and `reset_failures()` delegate to `mutate_failure` and `mutate_reset` instead of writing directly.

#### `commands/chp-law`

- `update_law()` — all `jq` writes replaced with `mutate_field` / `mutate_checks` calls
- `disable_law()` / `enable_law()` — replaced with `mutate_status` calls
- `create_law()` — already creates all three files; switch to using `mutate_*` after initial directory creation

#### `core/dispatcher.sh`

Add a consistency check before enforcement: call `validate_consistency` and log a warning if files have drifted.

### Guidance.md Sync Rules

The header block of guidance.md contains structured metadata:

```markdown
**Severity:** error
**Created:** 2026-04-25T04:05:10Z
**Failures:** 0
```

`mutate_field` updates these lines when the corresponding field changes. Uses `sed` to replace the line matching `**FieldName:** <old_value>` with the new value.

For check changes (`mutate_checks`), a brief changelog entry is appended:

```markdown
---

**Detection updated:** 2026-04-25T18:00:00Z
Added check: no-console-debug (pattern, warn)
```

### Error Handling

- All functions validate that the law exists before writing
- All functions validate that all three files exist before writing
- If any write fails, the function returns 1 without partial state (jq atomic write pattern: write to `.tmp`, then `mv`)
- `validate_consistency` is non-destructive — it only reports, never fixes

## Out of Scope

- Auto-fixing drifted files (validate only)
- Schema migration or versioning
- Changing the guidance.md template structure
- Modifying how the write-laws skill works (it already delegates to `chp-law create`)
