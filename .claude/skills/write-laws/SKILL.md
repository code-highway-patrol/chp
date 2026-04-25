---
name: write-laws
description: Create and manage CHP enforcement laws using the chp-law CLI
---

# Using CHP Laws

The CHP (Code Health Protocol) law enforcement system provides two layers of rule enforcement:

1. **Suggestive Layer** - Context documents that guide you to follow rules
2. **Verification Layer** - Programmatic checks that catch violations

## Creating a Law

When you need to enforce a rule or standard in the repository, use the `chp-law` CLI:

```bash
chp-law create <law-name> --hooks=pre-commit,pre-push
```

### Example: No API Keys Law

```bash
# Create the law
chp-law create no-api-keys --hooks=pre-commit,pre-push

# This creates:
# - docs/chp/laws/no-api-keys/law.json (metadata)
# - docs/chp/laws/no-api-keys/verify.sh (verification script)
# - docs/chp/no-api-keys.md (suggestive context)
```

### Implementing the Verification

Edit the `verify.sh` script to detect violations:

```bash
#!/bin/bash
# Check for API keys in staged files

if git diff --cached --name-only | xargs grep -l "sk_\|AIza\|AKIA" 2>/dev/null; then
    echo "❌ API key detected in staged files"
    exit 1  # Block the commit
fi
exit 0
```

### Writing the Guidance

Edit the `.md` file to provide context:

```markdown
# Law: No API Keys

**Severity:** Error
**Action:** Blocks commits and pushes

## What this means
Never commit API keys, tokens, or secrets to this repository.

## How to comply
- Use environment variables
- Use `.env` files (already gitignored)
- Use secret management services

## Detection
Scans for patterns: `sk_`, `AIza`, `AKIA`, `Bearer eyJ`
```

## Testing Your Law

Before the law is active, test it:

```bash
chp-law test no-api-keys
```

## Available Commands

```bash
chp-law create <name> [--hooks=<list>]  # Create new law
chp-law list                            # List all laws
chp-law delete <name>                   # Delete a law
chp-law test <name>                     # Test verification
chp-law reset <name>                    # Reset failure count
chp-status                               # Show system status
```

## Hook Types

- `pre-commit` - Runs before `git commit`
- `pre-push` - Runs before `git push`
- `pre-merge-commit` - Runs before merge commits
- `pre-write` - Runs before file writes (pretool)

## Universal Hook System

CHP supports 25+ hook types across Git, AI/Agent, and CI/CD operations:

**Git Hooks (15):** pre-commit, post-commit, pre-push, post-merge, commit-msg, prepare-commit-msg, pre-rebase, post-checkout, post-rewrite, applypatch-msg, pre-applypatch, post-applypatch, update, pre-auto-gc, post-update

**AI/Agent Hooks (6):** pre-prompt, post-prompt, pre-tool, post-tool, pre-response, post-response

**CI/CD Hooks (4):** pre-build, post-build, pre-deploy, post-deploy

Use `chp-hooks detect` to see available hooks and `chp-hooks list` to see installed hooks.

## Auto-Tightening

When a law's verification fails:
1. The operation is blocked
2. Failure count increments
3. Guidance is automatically strengthened with violation history
4. Future attempts get stricter context

## Before Creating New Laws

1. Check existing laws: `chp-law list`
2. Ensure the law name is descriptive (lowercase, hyphens)
3. Consider which hooks should trigger verification
4. Think about both the verification logic AND the guidance

## Common Law Patterns

**Security Laws:**
- No API keys
- No hardcoded credentials
- No debug endpoints in production

**Quality Laws:**
- Max file size
- Max function length
- Required documentation

**Style Laws:**
- No console.log
- Enforce import ordering
- Require type annotations
