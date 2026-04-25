---
name: refine-laws
description: Adjust existing CHP laws
---

# Refine an Existing Law

## When to Use

- A law is catching things it shouldn't (too broad)
- A law is missing things it should catch (too narrow)
- User wants to change a reaction type
- User wants to disable or delete a law

## Process

1. Read `laws/chp-laws.txt`
2. Identify the law to refine (by name or by the user's description of the problem)
3. Discuss the change with the user if ambiguous
4. Edit the law's `intent` in `laws/chp-laws.txt`
5. Confirm what changed

## Common Refinements

**Make more specific** (reduce false positives):
Narrow the intent to exclude legitimate patterns. Example: "No console.log in production code" → "No console.log in production code, except in dedicated logging utility files."

**Make broader** (catch more cases):
Expand the intent to cover additional patterns. Example: "No hardcoded passwords" → "No hardcoded passwords, API keys, tokens, connection strings, or any sensitive credentials."

**Change reaction**: Switch between `block` and `warn`.

**Disable**: Comment out the entire law block with `#` on each line.

**Delete**: Remove the entire law block from the file.

## Guidelines

- Read the law's current intent first to understand its purpose
- Prefer making the intent more specific over deleting the law
- Laws tighten automatically over time — manual refinement is for course corrections
