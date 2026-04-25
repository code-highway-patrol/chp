---
name: write-laws
description: Create and manage CHP enforcement laws using the chp-law CLI
---

# Using CHP Laws

The CHP (Code Health Protocol) law enforcement system provides two layers of rule enforcement:

1. **Suggestive Layer** - Context documents that guide you to follow rules
2. **Verification Layer** - Programmatic checks that catch violations

## Setup (First Time Only)

Before creating laws, ensure hooks are installed:

```bash
# Check if hooks are installed
bash commands/chp-hooks list

# If no hooks are installed, install them
bash commands/chp-hooks install
```

**Auto-install:** When using this skill, hooks will be auto-installed if not present.

## Creating a Law

When you need to enforce a rule or standard in the repository, use the `chp-law` CLI:

```bash
# Interactive mode (will prompt for confirmation)
bash commands/chp-law create <law-name> --hooks=pre-commit,pre-push

# Non-interactive mode (for agents/automation)
bash commands/chp-law create <law-name> --hooks=pre-commit,pre-push --yes
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

### Law Schema

A law file contains the following fields:

**Required Fields:**
- `id` - Unique identifier for the law
- `intent` - High-level description of what the law protects
- `violations` - Array of violation patterns with `pattern`, `fix`, and `satisfies`
- `reaction` - How to respond: `"block"`, `"warn"`, or `"auto_fix"`

**Scope Control:**
- `include` - Glob patterns of files/directories this law applies to (empty = all files)
- `exclude` - Glob patterns to exempt from this law (overrides include)

**Metadata:**
- `tags` - Categories for organizing/filtering laws (e.g., `["security", "secrets"]`)
- `priority` - Higher priority wins when multiple laws conflict (default: 0)
- `author` - Law owner/team
- `documentation` - URL or path to extended documentation
- `version` - Semantic version for tracking law evolution

**Lifecycle:**
- `createdAt` - ISO 8601 timestamp when law was created
- `updatedAt` - ISO 8601 timestamp when law was last updated
- `expiresAt` - ISO 8601 timestamp for temporary laws
- `enabled` - Quick disable without deleting (default: true)

**Conditions:**
- `environment` - Environments where law applies (e.g., `["production", "staging"]`)
- `dependsOn` - Other law IDs that must be satisfied first

**Enforcement:**
- `severity` - Severity level: `"error"`, `"warn"`, or `"info"`
- `hooks` - Array of hooks that trigger this law

### Example Law with Scope Control

```json
{
  "id": "no-api-keys",
  "name": "no-api-keys",
  "intent": "Prevent API keys from being committed to the repository",
  "violations": [
    {
      "pattern": "fileContains(/sk_|AIza|AKIA/, content)",
      "fix": "Remove API key and use environment variable",
      "satisfies": "!fileContains(/sk_|AIza|AKIA/, content)"
    }
  ],
  "reaction": "block",
  "include": ["**/*.ts", "**/*.js", "**/*.json"],
  "exclude": ["**/examples/**", "**/*.example.json"],
  "tags": ["security", "secrets"],
  "priority": 100,
  "author": "security-team",
  "documentation": "/docs/security/api-key-handling.md",
  "version": "1.2.0",
  "environment": ["production", "staging"],
  "enabled": true,
  "hooks": ["pre-commit", "pre-push", "pre-tool"],
  "severity": "error"
}
```

### Implementing the Verification

Edit the `verify.sh` script to detect violations:

```bash
#!/bin/bash
# Check for API keys in staged files

if git diff --cached --name-only | xargs grep -l "sk_\|AIza\|AKIA" 2>/dev/null; then
    echo "API key detected in staged files"
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

## Scope Control Examples

**Apply only to TypeScript files:**
```json
"include": ["**/*.ts"]
```

**Apply to all files except test files:**
```json
"exclude": ["**/*.test.ts", "**/*.spec.ts", "**/test/**"]
```

**Apply to source files only (not build artifacts):**
```json
"include": ["src/**/*"],
"exclude": ["dist/**", "build/**", "**/*.min.js"]
```

**Apply to specific directories:**
```json
"include": ["lib/**/*", "components/**/*"]
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
4. Consider scope (include/exclude) to avoid false positives
5. Think about both the verification logic AND the guidance

## Pattern Reference

**NEW:** Comprehensive pattern library available at `docs/chp/LAW-PATTERNS.md`

When users describe what they want to enforce, match their language to patterns and ask "you mean something like this?"

The reference includes:
- **Section 1:** Regex/Shell patterns (secrets, console.log, file size, missing tests)
- **Section 2:** AST-based analysis (nesting depth, unused imports, unhandled promises)
- **Section 3:** Delegated tools (ESLint, Prettier, Semgrep, TypeScript)
- **Section 4:** Hybrid patterns (conditional enforcement, multi-condition rules)

Each pattern includes:
- Common user requests that trigger it
- Clarifying questions to ask
- CHP implementation templates
- Limitations

**Quick examples from reference:**

| User Request | Detection Method | Template |
|--------------|------------------|----------|
| "no API keys" | Regex | `sk_\|AIza\|AKIA` |
| "no console.log" | Regex | `console\.log` |
| "too nested" | AST | Nesting depth check |
| "enforce style" | Delegated | ESLint/Prettier |
| "console in tests only" | Hybrid | Regex + file path |

**Before writing custom verify.sh:**
1. Check `docs/chp/LAW-PATTERNS.md` for existing patterns
2. Match user's request to a pattern
3. Use the provided template
4. Adapt to specific requirements

**For the complete agent flow:**
- See `docs/chp/AGENT-FLOW.md` for step-by-step walkthroughs
- Shows how to match user requests to patterns
- Includes real-world conversation examples
- Explains when to clarify vs. implement directly

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
