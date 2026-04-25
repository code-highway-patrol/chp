---
name: refine-laws
description: Adjust existing CHP laws
---

# Refine an Existing Law

## When to Use

- A law is flagging false positives
- A law should be switched from subjective to deterministic (or vice versa)
- User wants to change a reaction type
- User wants to disable or delete a law

## Process

1. Read `laws/chp-laws.txt`
2. Identify the law to refine
3. Edit the law block in `laws/chp-laws.txt`
4. Confirm what changed

## Common Refinements

**Add a deterministic check to a subjective law:**
If you realize a subjective law can be checked with regex, add a `check:` field.

**Narrow a regex** (reduce false positives):
Make the `check:` pattern more specific.

**Change reaction**: Switch between `block` and `warn`.

**Convert to subjective**: Remove the `check:` field if regex can't capture the intent accurately.

**Disable**: Comment out the entire law block with `#`.

**Delete**: Remove the entire law block.
