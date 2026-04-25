---
name: write-laws
description: Create and manage CHP enforcement laws through interactive, conversational workflow
---

# CHP Law Creation

Create CHP laws through an interactive, conversational process. The agent will suggest configurations based on your intent and ask questions only when context is unclear.

## When to Use

Invoke this skill when:
- You want to create a new CHP law
- You need to enforce a rule or standard in the repository
- You mention preventing specific patterns (API keys, console.log, etc.)
- Agent detects a quantifiable code quality issue

## How It Works

### Conversational Creation

The agent guides you through creating a law by:

1. **Understanding your intent** - What should the law enforce?
2. **Assessing clarity** - Is your specific request clear enough to suggest defaults?
3. **Suggesting configuration** - For clear intents, proposes reasonable defaults with reasoning
4. **Asking questions** - For unclear intents, asks targeted questions to understand requirements
5. **Previewing** - Always shows what will be created before committing
6. **Creating** - Runs `chp-law create` with appropriate configuration
7. **Testing** - Automatically tests the law after creation

### Clear Intent Example

```
You: "I want to prevent console.log statements"

Agent: I'll create a "no-console-log" law with these recommendations:
  • Pattern: console\.log
  • Files: JavaScript, TypeScript
  • Severity: error (debug code shouldn't ship)
  • Hooks: pre-commit, pre-push (catch early)

  Does this look right?

You: "Yes, but allow console.error for error tracking"

Agent: Got it. Creating with console.error exception...
  [Creates law]
  [Tests law]

✓ Law created! Edit verify.sh to customize detection logic.
```

### Unclear Intent Example

```
You: "I want to enforce code quality"

Agent: What specifically should this enforce?
  A) File size limits (max lines per file)
  B) Function length (max lines per function)
  C) Documentation requirements
  D) Custom pattern

You: "A"

Agent: What's the max file size?
  A) 100 lines
  B) 300 lines
  C) 500 lines

You: "B"

[...continues with targeted questions...]
```

## Using the CLI Directly

### Interactive Creation

```bash
# Interactive mode - asks questions
chp-law create <law-name>
```

### Skip Questions with Flags

```bash
# Provide all options upfront
chp-law create no-console-log \
  --severity=error \
  --hooks=pre-commit,pre-push \
  --exceptions=console.error,console.warn
```

### Preview Before Creating

```bash
# See what will be created
chp-law create <law-name> --dry-run
```

## Available Commands

```bash
chp-law create <name> [options]    # Create new law (interactive)
chp-law update <name> [options]    # Update existing law
chp-law list                        # List all laws
chp-law delete <name>               # Delete a law
chp-law test <name>                # Test verification
chp-law reset <name>               # Reset failure count
chp-law enable <name>              # Enable disabled law
chp-law disable <name>             # Disable law
```

## Create Command Options

```bash
--severity=<level>     Severity: error, warn, or info
--hooks=<list>         Comma-separated hooks (pre-commit, pre-push, etc.)
--pattern=<regex>      Custom detection pattern
--files=<extensions>   File types to check (*.js, *.ts, etc.)
--exceptions=<list>    Exception patterns (comma-separated)
--dry-run             Preview without creating
```

## Update Command Options

```bash
--severity=<level>         Change severity level
--hooks=<list>             Replace all hooks
--add-hook=<hook>          Add a hook
--remove-hook=<hook>       Remove a hook
--add-exception=<pattern>  Add exception pattern
--remove-exception=<pattern> Remove exception pattern
--set-guidance             Open guidance.md for editing
```

## Common Law Patterns

### Security Laws

```bash
chp-law create no-api-keys --severity=error --hooks=pre-commit,pre-push
chp-law create no-secrets --severity=error --hooks=pre-commit
chp-law create no-hardcoded-credentials --severity=warn --hooks=pre-push
```

### Quality Laws

```bash
chp-law create no-console-log --severity=error --exceptions=console.error
chp-law create max-file-size --severity=warn --hooks=pre-commit
chp-law create require-documentation --severity=info --hooks=pre-push
```

### Workflow Laws

```bash
chp-law create test-coverage --severity=warn --hooks=pre-push
chp-law create no-todos --severity=error --hooks=pre-commit
```

## After Creation

1. **Review the law files** in `docs/chp/laws/<law-name>/`
2. **Edit verify.sh** to implement actual detection logic
3. **Edit guidance.md** to add compliance guidance
4. **Test the law** with `chp-law test <law-name>`
5. **Commit your changes**

## Related Skills

- **chp:refine-laws** - Tune existing laws
- **chp:investigate** - Debug why actions were blocked
- **chp:audit** - Scan codebase for violations
