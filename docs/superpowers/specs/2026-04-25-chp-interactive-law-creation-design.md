# CHP Interactive Law Creation Design

## Overview

Redesign the CHP law creation experience to be **conversational and intelligent**. The agent actively suggests law configurations based on user intent, asks questions only when context is unclear, and uses atomic CLI commands for all operations.

**Key insight:** Law creation should feel like working with a helpful assistant who understands what you want and suggests reasonable defaults, not like filling out a static form.

## Goals

1. **Conversational**: Agent suggests configurations based on intent, explains reasoning
2. **Adaptive**: Skip questions when intent is clear, ask when unclear
3. **Atomic CLI**: All operations are discrete, composable commands
4. **Skill-guided**: `chp:write-laws` and `chp:refine-laws` skills orchestrate the CLI

---

## CLI Structure

### Current State

```bash
chp-law create <name> [--hooks=<list>]  # Non-interactive, requires flags
chp-law list
chp-law delete <name>
chp-law test <name>
chp-law reset <name>
chp-law enable <name>
chp-law disable <name>
```

### New Design

```bash
# Create - interactive by default
chp-law create <name> [--flags]           # Interactive, flags skip questions

# Update - atomic modifications
chp-law update <name> --severity=<level>
chp-law update <name> --hooks=<list>
chp-law update <name> --add-hook=<hook>
chp-law update <name> --remove-hook=<hook>
chp-law update <name> --add-exception=<pattern>
chp-law update <name> --remove-exception=<pattern>
chp-law update <name> --set-guidance

# Existing commands (unchanged)
chp-law list
chp-law delete <name>
chp-law test <name>
chp-law reset <name>
chp-law enable <name>
chp-law disable <name>

# Preview
chp-law create <name> --dry-run           # Shows what will be created
```

---

## Interactive Create Flow

### Clear Intent - Minimal Prompting

When user intent is specific and quantifiable:

```bash
$ chp-law create no-console-log

Agent: I'll create a "no-console-log" law with these defaults:
  • Pattern: console\.log
  • Files: JavaScript, TypeScript
  • Severity: error (debug code shouldn't ship)
  • Hooks: pre-commit, pre-push (catch early)
  • Exceptions: none

  Look good? I'll add exceptions if you need them.

User: Yes, but allow console.error and console.warn

Agent: Updated. Creating law now...
  [Creates law with exceptions]

$ chp-law test no-console-log
✓ Law verification passed
```

### Unclear Intent - Ask Questions

When user intent is vague or broad:

```bash
$ chp-law create enforce-quality

Agent: What specifically should this enforce?
  A) File size limits (max lines per file)
  B) Function length (max lines per function)
  C) Documentation requirements (public APIs must be documented)
  D) Custom pattern

User: A

Agent: What's the max file size?
  A) 100 lines
  B) 300 lines
  C) 500 lines
  D) Custom limit

User: B

Agent: Which file types?
  A) All source files
  B) JavaScript only
  C) TypeScript only
  D) Custom extensions

[...continues questions until law is specified...]
```

### Flag-Based - Skip Questions

```bash
$ chp-law create no-console-log --severity=warn --hooks=pre-commit

Agent: Creating law with your specifications:
  • Severity: warn
  • Hooks: pre-commit
  • Using defaults for: pattern, files, exceptions

  Creating now...
  [Creates law]
```

---

## Update Commands

### Atomic Updates for Refinement

The `chp:refine-laws` skill uses these atomic commands:

```bash
# Change severity
chp-law update no-console-log --severity=warn

# Add a hook
chp-law update no-console-log --add-hook=pre-push

# Remove a hook
chp-law update no-console-log --remove-hook=pre-commit

# Add an exception pattern
chp-law update no-console-log --add-exception=console\.error

# Remove an exception
chp-law update no-console-log --remove-exception=console\.warn

# Update guidance documentation
chp-law update no-console-log --set-guidance

# Multiple updates at once
chp-law update no-console-log \
  --severity=warn \
  --add-exception=console.error \
  --remove-hook=pre-push
```

### Skill Orchestrates Updates

```
User: "This law is flagging too many false positives"

Agent: [Loads chp:refine-laws skill]
Agent: I can help. What's happening?
  A) Law catches things that shouldn't violate (false positives)
  B) Law severity is too harsh
  C) Law runs at the wrong time
  D) Need to add new violation patterns

User: A - it's catching console.error which we need

Agent: Got it. I'll add an exception for console.error.
  [Runs: chp-law update no-console-log --add-exception=console\.error]
  [Runs: chp-law test no-console-log]
  ✓ Exception added, law updated
```

---

## Dry Run Support

### Preview Before Creating

```bash
$ chp-law create no-console-log --dry-run

Agent: Here's what I'll create:
  
  Law: no-console-log
  • Pattern: console\.log
  • Files: *.js, *.ts, *.tsx
  • Severity: error
  • Hooks: pre-commit, pre-push
  • Exceptions: none
  
  Files created:
  • docs/chp/laws/no-console-log/law.json
  • docs/chp/laws/no-console-log/verify.sh
  • docs/chp/laws/no-console-log/guidance.md
  
  Hooks installed:
  • .git/hooks/pre-commit
  • .git/hooks/pre-push
  
  Create this law? (y/n)
```

### Dry Run with Flags

```bash
$ chp-law create no-console-log --severity=warn --dry-run

Agent: With your custom severity:
  
  Law: no-console-log
  • Severity: warn (you specified)
  • Hooks: pre-commit, pre-push
  • Everything else: default
  
  Proceed?
```

---

## Skill Behavior

### chp:write-laws Skill

**Triggers:**
- User says "create a law" or "enforce a rule"
- Agent detects quantifiable problem ("too many console.log statements")
- User mentions needing a guardrail for specific behavior

**Flow:**

1. **Understand intent** - What should the law enforce?
2. **Assess clarity** - Is intent specific enough to suggest defaults?
3. **Suggest or ask** - Propose configuration if clear, ask questions if unclear
4. **Show what will be created** - Always preview before creating
5. **Create the law** - Run `chp-law create` with appropriate flags
6. **Apply updates** - Run `chp-law update` for any additional specifications
7. **Test the law** - Run `chp-law test` to verify
8. **Next steps** - Guide user to edit verify.sh if needed

**Example:**

```
User: "I want to prevent API keys in commits"

Agent: [chp:write-laws triggers]
Agent: I'll create an "no-api-keys" law for you.

Here's what I recommend:
  • Pattern: Common API key formats (sk_*, AIza*, AKIA*, Bearer *)
  • Files: All file types (API keys can appear anywhere)
  • Severity: error (security risk)
  • Hooks: pre-commit, pre-push (block before sharing)
  
  Does this look right?

User: Yes, but also catch GitHub tokens

Agent: I'll add that pattern. Creating now...
  [Runs: chp-law create no-api-keys]
  [Runs: chp-law update no-api-keys --add-exception=ghp_[a-zA-Z0-9]{36}]
  [Runs: chp-law test no-api-keys]
  
✓ Law created. Edit verify.sh to adjust patterns if needed.
```

### chp:refine-laws Skill

**Triggers:**
- User says "this law has too many false positives"
- User wants to change severity, hooks, or patterns
- Law needs tuning based on new requirements

**Flow:**

1. **Identify what needs changing** - Ask or detect the issue
2. **Propose solution** - Suggest specific change
3. **Apply update** - Run appropriate `chp-law update` command
4. **Test the change** - Verify the updated law works
5. **Document** - Remind user to update guidance.md if needed

**Example:**

```
User: "The no-console-log law is too strict"

Agent: [chp:refine-laws triggers]
Agent: What's the issue?
  A) False positives (catching things that shouldn't violate)
  B) Severity too harsh
  C) Runs at wrong time
  D) Need to adjust what it catches

User: A - it's flagging console.error which we use for error tracking

Agent: I'll add an exception for console.error.
  [Runs: chp-law update no-console-log --add-exception=console\.error]
  [Runs: chp-law test no-console-log]
  
✓ Law updated. You may want to update guidance.md to document this exception.
```

---

## Command Reference

### chp-law create

```bash
chp-law create <name> [options]

Options:
  --severity=<level>     Skip severity question (error|warn|info)
  --hooks=<list>         Skip hooks question (comma-separated)
  --pattern=<regex>       Custom detection pattern
  --files=<extensions>    File types to scan (comma-separated)
  --exceptions=<list>    Exception patterns (comma-separated)
  --dry-run              Preview without creating
```

### chp-law update

```bash
chp-law update <name> [options]

Options:
  --severity=<level>         Change severity
  --hooks=<list>             Replace all hooks
  --add-hook=<hook>          Add a hook
  --remove-hook=<hook>       Remove a hook
  --add-exception=<pattern>  Add exception pattern
  --remove-exception=<pattern> Remove exception pattern
  --set-guidance             Prompt for new guidance text
```

### Other Commands

```bash
chp-law list                           # List all laws
chp-law test <name>                    # Test verification
chp-law delete <name>                  # Delete law
chp-law reset <name>                   # Reset failure count
chp-law enable <name>                  # Enable disabled law
chp-law disable <name>                 # Disable law
chp-status                              # System status
```

---

## Implementation Notes

### Prompt Detection

The skill should trigger on phrases like:
- "create a law"
- "enforce a rule"  
- "prevent X in commits"
- "I want to block Y"
- Agent detects quantifiable code quality issues

### Adaptive Questioning

**Skip questions when:**
- Intent is crystal clear ("prevent console.log")
- User provides flags upfront
- Pattern is well-known standard (API keys, secrets)

**Ask questions when:**
- Intent is vague ("enforce quality")
- Pattern is custom/unusual
- Multiple valid approaches exist

### Always Preview

Before creating any law, show:
- What will be created
- Default choices and why
- Opportunity to adjust

### Test After Creation

Always run `chp-law test` after creating:
- Confirms law was created successfully
- Shows user what to implement (verify.sh is a template)
- Provides clear next step

---

## Examples

### Example 1: Clear Intent, Minimal Questions

```bash
$ chp-law create no-api-keys

Agent: Creating "no-api-keys" law with defaults:
  • Pattern: Common API key formats
  • Severity: error (security)
  • Hooks: pre-commit, pre-push
  
  Creating...
  
✓ Law created. Edit verify.sh to adjust patterns.
```

### Example 2: Unclear Intent, More Questions

```bash
$ chp-law create enforce-quality

Agent: What should this enforce?
  A) File size limits
  B) Function length limits  
  C) Documentation requirements
  D) Custom pattern

> A

Agent: Max file size?
  A) 100 lines
  B) 300 lines
  C) 500 lines
  D) Custom

> B

Agent: Which file types?
  A) All source files
  B) JS only
  C) TS only
  D) Custom

> A

Agent: Creating "enforce-quality" law:
  • Max file size: 300 lines
  • Files: All source files
  • Severity: error
  • Hooks: pre-commit
  
  Creating...
  
✓ Law created. Edit verify.sh to implement line counting.
```

### Example 3: Flags Override Questions

```bash
$ chp-law create no-console-log --severity=warn --hooks=pre-commit

Agent: Creating "no-console-log" law with your settings:
  • Severity: warn (you specified)
  • Hooks: pre-commit (you specified)
  • Everything else: default
  
  Creating...
  
✓ Law created.
```

### Example 4: Refinement with Updates

```bash
User: "The no-console-log law is too strict"

Agent: What's wrong?
  A) False positives
  B) Severity too harsh
  C) Wrong timing
  D) Other

> A

Agent: What's being flagged incorrectly?
  A) console.error (we need this)
  B) console.warn (we need this)
  C) console.debug (we need this)
  D) Custom pattern

> A

Agent: Adding exception for console.error...
  
✓ Updated. Testing...
  [chp-law update no-console-log --add-exception=console\.error]
  [chp-law test no-console-log]
  
✓ Law updated. Consider updating guidance.md.
```

---

## Success Criteria

- [ ] User can create laws with natural language
- [ ] Agent suggests smart defaults for common patterns
- [ ] Questions are asked only when context is missing
- [ ] All operations are atomic and composable
- [ ] Dry-run previews work correctly
- [ ] Skills guide agents through the full workflow
- [ ] Testing happens automatically after creation
- [ ] Update commands enable law refinement
