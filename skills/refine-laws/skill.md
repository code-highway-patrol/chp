---
name: refine-laws
description: Adjust existing CHP laws to reduce false positives or update patterns
---

# Refine an Existing Law

## When to Use

- A law is flagging false positives
- A law needs broader or narrower patterns
- User wants to change a reaction type (block/warn/auto_fix)
- User wants to disable or delete a law

## Process

1. Read `laws/chp-laws.txt`
2. Identify the law to refine (by name or by the user's description of the problem)
3. Discuss the change with the user if ambiguous
4. Edit the law block in `laws/chp-laws.txt`
5. Confirm what changed

## Common Refinements

**Add exclusion** (reduce false positives):
```
exclusion: <regex matching the false positive pattern>
```

**Broaden violation** (catch more cases):
Update the `violation:` regex to cover additional patterns.

**Change reaction**:
Switch between `block`, `warn`, and `auto_fix`.

**Disable temporarily**:
Comment out the entire law block with `#` on each line.

**Delete permanently**:
Remove the entire law block from the file.

## Guidelines

- Always read the law's `intent` first to understand its purpose
- Prefer adding exclusions over weakening the violation pattern
- After editing, mentally test the regex against the problematic code to verify the fix
