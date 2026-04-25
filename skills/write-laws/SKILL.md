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
2. Draft a law with a unique id, a clear intent, and a reaction type
3. Read `laws/chp-laws.txt` to check for duplicates or overlap
4. Append the new law block to `laws/chp-laws.txt`
5. Confirm what was added

## Law Format

Append to `laws/chp-laws.txt`:

```
# === Law: <unique-id> ===
intent: <plain-language description of what this law prohibits — be specific and actionable>
reaction: block|warn
```

## Fields

- **id**: Lowercase kebab-case, unique across all laws
- **intent**: A clear, specific statement of what's not allowed and what to do instead. Write it like a rule you'd explain to a teammate. The more explicit, the better — this is what the agent evaluates against.
- **reaction**: `block` (must fix before continuing) or `warn` (flag but allow)

## Guidelines

- Write intents that are specific enough to act on — "no bad code" is too vague, "no raw SQL queries without parameterized inputs" is good
- Prefer `block` for security and correctness laws, `warn` for style preferences
- Check existing laws first to avoid overlap
- Laws evolve over time — they get tightened automatically when violations are caught
