# Auto-Fix Feature Design

**Created:** 2026-04-25
**Status:** Draft

## Overview

Enable Claude to automatically fix violations detected by CHP laws. When a law fails verification, Claude reads the law's `guidance.md` and proposes a fix. The user can review and accept, or the fix can be applied automatically depending on configuration.

## Goals

- Reduce manual remediation time for common violations
- Leverage Claude's code understanding to generate context-aware fixes
- Maintain transparency — user always sees what changes
- Keep the system opt-in per-law

## Architecture

```
┌─────────────────┐     ┌────────────────┐     ┌─────────────────┐
│   User Action   │────▶│   Dispatcher   │────▶│   Verifier      │
│  (git commit)   │     │  (dispatcher)  │     │  (verify.sh)    │
└─────────────────┘     └────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   Violation     │
                                               │   detected      │
                                               └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌────────────────┐     ┌─────────────────┐
│   Fixed code    │◀───│   Claude       │◀───│  Offer to fix?  │
│  (re-staged)    │     │  (agent fixes) │     │  (show diff)    │
└─────────────────┘     └────────────────┘     └─────────────────┘
```

### Key Principle

Claude is the fixer. Bash scripts are just plumbing.

## Components

### 1. Law Configuration (`law.json`)

Add `autoFix` field to law schema:

```json
{
  "name": "no-console-log",
  "autoFix": "ask",
  "checks": [...]
}
```

**Values:**
- `"never"` — No auto-fix (default, current behavior)
- `"ask"` — Show diff, wait for user confirmation (y/n)
- `"auto"` — Apply immediately, still show what changed

### 2. Schema Update (`law.schema.json`)

```json
{
  "autoFix": {
    "type": "string",
    "enum": ["never", "ask", "auto"],
    "default": "never",
    "description": "Whether Claude should attempt to auto-fix violations."
  }
}
```

### 3. Fix Trigger (`core/fix-trigger.sh`)

Lightweight bash script that:
- Reads recent violations from `.chp/violations.log`
- Filters by `autoFix !== "never"`
- Sets up context for Claude (law name, guidance, files)
- Invokes Claude agent

### 4. Agent Prompt (`agents/fixer.md`)

Prompt that instructs Claude to:
- Read the law's `guidance.md`
- Understand the violation
- Generate a fix proposal
- Show the diff
- Apply on confirmation

### 5. Optional CLI (`commands/chp-fix`)

Convenience command for manual use:

```bash
chp fix                    # Show pending fixes, ask to apply
chp fix --apply           # Auto-apply all "auto" mode fixes
chp fix --law no-console-log  # Fix specific law
chp fix --dry-run         # Show what would be fixed
```

### 6. Hook Integration

Add `fix` hook type to `law.schema.json`:

```json
{
  "hooks": {
    "type": "array",
    "items": {
      "type": "string",
      "enum": [
        "pre-commit",
        "pre-push",
        "post-commit",
        "commit-msg",
        "pre-tool",
        "post-tool",
        "pre-write",
        "post-response",
        "fix"
      ]
    }
  }
}
```

## Data Flow

### When a violation occurs:

1. **Violation detected** — `verify.sh` returns non-zero
2. **Failure recorded** — `dispatcher.sh` calls `record_failure`
3. **Fix check** — dispatcher reads `law.json` for `autoFix` mode
4. **If `autoFix !== "never"`** — invoke fix trigger
5. **Fix trigger** — `core/fix-trigger.sh` sets up context and invokes Claude
6. **Claude receives** — law name, violation details, `guidance.md` content
7. **Claude proposes** — shows diff and asks "Apply? (y/n)"
8. **If user confirms** — Claude applies fix via Edit/Write tools
9. **Re-stage** — `git add` the fixed files
10. **Re-verify** — run `verify.sh` again to confirm fix worked

### Mode-specific behavior:

- **`autoFix: "auto"`** — Skip confirmation, apply immediately
- **`autoFix: "ask"`** — Show diff, wait for `y/n`
- **`autoFix: "never"`** — Skip fix flow entirely

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Fix fails | Report "Couldn't auto-fix — manual intervention required", show guidance |
| Fix makes it worse | Report "Fix applied but verification still fails", don't re-stage |
| Multiple violations | Offer fixes for each law sequentially |
| Conflicting fixes | Don't auto-fix, report "Conflicting guidance — manual review required" |
| No agent available | Skip fix flow, show violation + "Auto-fix requires Claude agent" |
| User declines | Respect choice, continue with normal error flow |

## Testing

### 1. Bash Unit Tests

Test the plumbing without invoking Claude:

```bash
test_fix_trigger_skips_when_autoFix_never() {
  # Mock law.json with autoFix: "never"
  # Verify fix-trigger.sh exits without invoking Claude
}

test_fix_trigger_invokes_for_auto_mode() {
  # Mock law.json with autoFix: "auto"
  # Verify fix-trigger.sh sets up Claude invocation correctly
}
```

### 2. Integration Tests (Real Agent)

Run actual Claude to test the full flow:

```bash
test_console_log_auto_fix() {
  # Create test law with autoFix: "ask"
  # Stage file with console.log
  # Run pre-commit hook
  # Verify violation detected, fix offered, fix applied
}
```

### 3. Mode Tests

Test all three modes:

```bash
test_auto_mode() {
  # Verify fix applies without prompt
}

test_ask_mode() {
  # Verify fix waits for confirmation
}

test_never_mode() {
  # Verify fix flow is skipped
}
```

## Implementation Phases

1. **Schema update** — Add `autoFix` field to `law.schema.json`
2. **Fix trigger** — Implement `core/fix-trigger.sh`
3. **Agent prompt** — Create `agents/fixer.md`
4. **Dispatcher integration** — Wire fix trigger into violation flow
5. **CLI command** — Implement `chp-fix` (optional)
6. **Tests** — Unit and integration tests
7. **Documentation** — Update CLAUDE.md and user docs

## Migration

- Existing laws default to `autoFix: "never"` — no behavior change
- Laws can be updated to enable auto-fix by adding the field
- No breaking changes to existing laws or hooks
