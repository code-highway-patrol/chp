---
name: setup
description: Configure CHP hooks to run before every tool use for real-time law enforcement
---

# CHP Setup

## When to Use

- User asks to "set up CHP", "configure hooks", "enable real-time enforcement"
- User has installed CHP and wants it to actively enforce laws before every action
- This is typically the first step after installing the plugin

## Prerequisites

- CHP plugin is installed and enabled
- `laws/chp-laws.txt` exists in the project

## Process

### Step 1: Check Current Hook Configuration

Read the user's project-level settings file at `.claude/settings.json` (if it exists).

### Step 2: Determine If Hook Is Already Configured

If the file exists AND contains a `PreToolUse` hook with `bin/chp-context`, tell the user CHP is already set up and no action is needed.

### Step 3: If Not Configured, Prompt to Add It

Tell the user:
```
CHP is installed but the real-time enforcement hook is not configured.

To enforce laws before every action, CHP needs to add a PreToolUse hook to your settings.

This will:
  - Inject active laws into context before EVERY tool use (Read, Write, Edit, Bash, etc.)
  - Make violations preventable at authoring time, not just detectable after the fact

No existing settings will be overwritten — only the hooks section will be added.

Add the enforcement hook now?
```

### Step 4: If User Confirms, Write the Hook

Read existing `.claude/settings.json` if present. Merge the hooks section in:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": { "type": "all" },
        "hooks": [
          {
            "type": "command",
            "command": "bin/chp-context"
          }
        ]
      }
    ]
  }
}
```

- If `settings.json` doesn't exist, create it with just the hooks section
- If it exists but has no `hooks` key, add the `hooks` section
- If it already has a `hooks` key with other hooks, add to the existing `PreToolUse` array rather than replacing

### Step 5: Confirm Success

After writing, verify the file was updated correctly and inform the user:
```
Hook configured. CHP will now inject active laws before every tool use.

This session will pick up the new hooks automatically. Future sessions will also use them.
```

## Notes

- The hook uses `matcher: { "type": "all" }` to fire on every tool — this is intentional for law enforcement
- Settings are project-local (`.claude/settings.json`), not plugin-local — each project that uses CHP needs this setup
- The hook only affects the project where it's configured; it doesn't globally change Claude Code behavior