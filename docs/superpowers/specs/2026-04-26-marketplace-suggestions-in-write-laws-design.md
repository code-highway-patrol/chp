# Marketplace Suggestions in write-laws

**Date:** 2026-04-26
**Status:** Design
**Author:** CHP Agent

## Overview

Integrate marketplace search into the write-laws skill flow to suggest existing laws before writing custom ones.

## Problem

Users often want to enforce rules that may already exist in the CHP marketplace. Currently, the write-laws skill immediately proceeds to creating custom laws without checking if a suitable law already exists. This can lead to:
- Duplicate effort writing laws that already exist
- Missed opportunity to leverage community-maintained laws
- Users unaware of relevant marketplace options

## Solution

After decomposing a law concept into atomic checks, the write-laws skill queries the marketplace for similar laws and presents them as an alternative.

## Flow

```
User: "I want a law for no secrets"
    ↓
write-laws skill invoked
    ↓
[If vague] decompose-laws skill breaks it down
    ↓
Result: checks for API keys, tokens, passwords
    ↓
Call marketplace API: POST /api/statues/search with query
    ↓
[If results found] Show similar laws and ask:
    1. Use marketplace law
    2. Write custom law
    3. Show details of both
    ↓
User decides → Continue accordingly
```

## Changes

### write-laws Skill (SKILL.md)

Add new section "Check Marketplace Before Writing" between "Decompose Before Writing" and "Creating a Law":

```markdown
## Check Marketplace Before Writing

After decomposing the law into atomic checks (or for clear, specific requests), check if a similar law exists on the marketplace before writing from scratch.

**Query the marketplace:**
```bash
chp search "console"
chp search "api keys"
```

**If similar laws are found:**

Present results and ask:
> "I found similar laws on the marketplace:
> - **No Console Logging** (no-console-log) ★ 42
>
> What would you like to do?
> 1. Use a marketplace law instead
> 2. Write a custom law
> 3. Show details of the marketplace law first"

**User response handling:**
- "Use marketplace law" → Invoke chp:marketplace skill
- "Write custom law" → Proceed to "Creating a Law"
- "Show details" → Display full description, then re-ask
```

### No Code Changes Required

This is a skill documentation change only. The marketplace CLI commands (`chp search`, `chp install`) already exist and work correctly.

## Example Interaction

```
User: I want a law that prevents console logging

Agent: [Decomposes] I'll create checks for:
  - console.log() (block)
  - console.debug() (warn)

  Let me check if a similar law exists on the marketplace...

  [Queries: chp search "console"]

  Found similar law: **No Console Logging** (no-console-log)
  ★ 42 stars | Prevents console.log in production code

  What would you like to do?
  1. Use the marketplace law
  2. Write a custom law
  3. Show details of both

User: 1

Agent: [Invokes chp:marketplace skill]
  Installing no-console-log from marketplace...
  Done! The law is now active.
```

## Edge Cases

- **No marketplace results**: Proceed directly to custom law creation
- **Multiple similar results**: Show top 3 results, ask user to choose
- **User wants custom anyway**: Respect choice, proceed with creation
- **Marketplace API failure**: Inform user, proceed with custom law creation

## Success Criteria

1. write-laws skill checks marketplace before creating custom laws
2. User is presented with marketplace options when available
3. Flow seamlessly integrates with existing decompose-laws and marketplace skills
4. No breaking changes to existing write-laws behavior
