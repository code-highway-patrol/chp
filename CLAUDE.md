# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CHP (Code Highway Patrol) is a static analysis framework for enforcing rules across your codebase using a two-layer law enforcement system:
- **Suggestive Layer** - Context files in `docs/chp/` guide agent behavior
- **Verification Layer** - Scripts in `docs/chp/laws/` check for violations and auto-tighten guidance on failures

## Common Commands

```bash
# Law management
./commands/chp-law create <name> --hooks=pre-commit,pre-push   # Create a new law
./commands/chp-law list                                           # List all laws
./commands/chp-law test <name>                                    # Test a law's verify.sh
./commands/chp-law delete <name>                                  # Delete a law
./commands/chp-law disable <name>                                 # Disable a law
./commands/chp-law enable <name>                                  # Enable a law
./commands/chp-law reset <name>                                  # Reset failure count

# Scanning
./commands/chp-scan                             # Scan all files for all law violations
./commands/chp-scan --law=<name>                 # Scan for specific law violations

# Hook management
./commands/chp-hooks detect                                       # Detect available hooks
./commands/chp-hooks list                                         # List hook status
./commands/chp-hooks install pre-commit                           # Install a hook
./commands/chp-hooks uninstall pre-commit                         # Remove a hook
./commands/chp-hooks blocking pre-commit true                     # Set blocking behavior

# Status
./commands/chp-status                                            # Check system status
./commands/chp-audit                                             # Audit law enforcement
```

## Architecture

### Core Components (in `core/`)
- `index.ts` - Main exports for TypeScript modules
- `types.ts` - TypeScript interfaces (Law, Action, EvaluationResult, HookType)
- `evaluator.ts` - Evaluates actions against laws, returns blocked/warned/fixed
- `law-loader.ts` - Loads and validates law JSON files from `docs/chp/laws/`
- `pattern-matcher.ts` - Matches actions against violation patterns
- `hook-registry.ts` - TypeScript module for detecting environment and registering hooks (git/tool/file watching)
- `hook-registry.sh` - Manages hook-to-law mappings in `.chp/hook-registry.json`
- `dispatcher.sh` - Routes hook events to registered laws
- `tightener.sh` - Auto-strengthens guidance when verifications fail

### Skills (in `skills/` and `.claude/skills/`)
Skills provide specialized capabilities for law enforcement:
- `audit` - Scan codebase for CHP violations and code health assessment
- `investigate` - Debug specific violations with deeper analysis
- `plan-check` - Review plans before implementation
- `write-laws` - Guide law creation process
- `scan-repo` - Repository-level scanning

### Laws (in `docs/chp/laws/<law-name>/`)
Active laws: `no-console-log`, `no-api-keys`, `no-todos`, `commit-metrics`, `test-dispatcher-law`
Each law has three files:
- `law.json` - Metadata (id, intent, violations, reaction, hooks, enabled)
- `verify.sh` - Verification script that returns exit 0 (pass) or 1 (fail)
- `guidance.md` - Human-readable compliance guidance (auto-tightened on failure)

### Hook System
Supports 25 hook types across three categories:
- **Git Hooks (15)**: pre-commit, post-commit, pre-push, post-merge, commit-msg, etc.
- **AI/Agent Hooks (6)**: pre-prompt, post-prompt, pre-tool, post-tool, pre-response, post-response
- **CI/CD Hooks (4)**: pre-build, post-build, pre-deploy, post-deploy

## Claude Code Integration

CHP hooks are configured in `.claude/settings.json` and scripts live in `.claude/hooks/`:
- `pre-tool` - Validates tool parameters before execution
- `post-tool` - Validates tool results after execution

The TypeScript `hook-registry.ts` module provides `detectEnvironment()` and `registerHooks()` functions for programmatic hook management.

### TypeScript Types (core/types.ts)
```typescript
Law { id, intent, violations: [{pattern, fix, satisfies}], reaction: 'block'|'warn'|'auto_fix' }
Action { type, payload, context? }
EvaluationResult { blocked?, warned?, fixed?, law?, reason?, fix?, suggestion? }
HookType = 'pre-tool' | 'post-tool' | 'pre-commit' | 'pre-push' | 'file-change'
```

## Law Creation Flow

1. `chp-law create <name> --hooks=<hooks>` creates `docs/chp/laws/<name>/`
2. Edit `verify.sh` with your verification logic (check git diff, files, etc.)
3. Edit `guidance.md` with compliance instructions
4. Test with `chp-law test <name>`
5. Install hooks with `chp-hooks install <hook-type>`

The evaluator (`core/evaluator.ts`) processes actions through loaded laws and returns structured results with blocked/warned/fixed status based on the law's reaction type.