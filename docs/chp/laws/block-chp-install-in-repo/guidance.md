# Law: Block CHP Install in CHP Repository

**Severity:** Error
**Action:** Blocks operation

## What this means

You cannot run `chp install` or `chp-law create` commands in the CHP repository itself.

## Why

The CHP repository manages its own laws manually to prevent self-modification issues. Allowing automated law installation in the CHP codebase could create circular dependencies or break the law enforcement system itself.

## How to comply

In the CHP repository:
- Create law directories manually under `docs/chp/laws/<law-name>/`
- Write `law.json`, `verify.sh`, and `guidance.md` files directly
- Register laws manually in the hook registry if needed

For other projects:
- Use `chp install` normally — this law only applies to the CHP repository
- The law detects the CHP repo by checking if `package.json` name is "chp"

## Detection

Checks for:
1. Running in CHP repository (package.json name = "chp")
2. Command contains "chp install" or "chp-law create"
3. Blocks the operation if both conditions are met
