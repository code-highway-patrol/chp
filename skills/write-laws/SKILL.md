---
name: write-laws
description: Create new CHP enforcement laws
---

# Create a New Law

## When to Use

- User wants to add a new code rule
- User says "add a law", "create a rule", "enforce", "ban", or "block"

## Process

1. Ask the user what they want to enforce (or infer from context)
2. Draft a law block with: unique id, intent, violation regex, reaction type
3. Read `laws/chp-laws.txt` to check for duplicates or conflicts
4. Append the new law block to `laws/chp-laws.txt`
5. Confirm what was added

## Law Format

Append to `laws/chp-laws.txt`:

```
# === Law: <unique-id> ===
intent: <plain English description>
violation: <regex pattern matching the bad code>
exclusion: <optional regex for legitimate exceptions>
reaction: block|warn|auto_fix
```

## Fields

- **id**: Lowercase kebab-case, unique across all laws (e.g. `no-eval`, `require-error-handling`)
- **intent**: One sentence explaining what the law protects against
- **violation**: Regex pattern that matches violating code. Test it mentally against realistic examples
- **exclusion**: Optional. Patterns that look like violations but are acceptable (e.g. test files, debug modes)
- **reaction**: `block` (must fix), `warn` (flag but allow), `auto_fix` (attempt automatic correction)

## Guidelines

- Use precise regex — overly broad patterns cause false positives
- Prefer `block` for security laws, `warn` for style laws
- Add exclusions proactively for known legitimate patterns
- Check existing laws first to avoid overlap
