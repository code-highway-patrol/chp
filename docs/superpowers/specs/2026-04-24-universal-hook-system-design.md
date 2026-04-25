# CHP Universal Hook System Design

**Date:** 2026-04-24
**Status:** Design Review
**Goal:** Implement comprehensive hook system for Git, AI/Agent, and CI/CD operations

## Overview

A universal hook dispatcher that integrates CHP law enforcement across all development operations - Git hooks, AI agent operations, and CI/CD pipelines. The system uses a centralized dispatcher with a hook registry to route hook events to relevant laws.

## Architecture

```
chp/
├── core/
│   ├── common.sh              # Shared utilities (existing)
│   ├── dispatcher.sh          # NEW: Central hook dispatcher
│   ├── hook-registry.sh       # NEW: Hook type registry and management
│   ├── detector.sh            # Existing: Hook detection (expanded)
│   ├── installer.sh           # Existing: Hook installation (expanded)
│   ├── verifier.sh            # Existing: Verification runner
│   └── tightener.sh           # Existing: Guidance strengthening
├── hooks/
│   ├── git/                   # NEW: Git hook templates
│   │   ├── pre-commit.sh
│   │   ├── post-commit.sh
│   │   ├── pre-push.sh
│   │   ├── post-merge.sh
│   │   ├── commit-msg.sh
│   │   ├── pre-rebase.sh
│   │   ├── post-checkout.sh
│   │   └── post-rewrite.sh
│   ├── agent/                 # NEW: AI agent hook templates
│   │   ├── pre-prompt.sh
│   │   ├── post-prompt.sh
│   │   ├── pre-tool.sh
│   │   ├── post-tool.sh
│   │   ├── pre-response.sh
│   │   └── post-response.sh
│   └── cicd/                  # NEW: CI/CD hook templates
│       ├── pre-build.sh
│       ├── post-build.sh
│       ├── pre-deploy.sh
│       └── post-deploy.sh
├── commands/
│   ├── chp-law                # Existing: Law management (enhanced)
│   ├── chp-status             # Existing: Status display (enhanced)
│   └── chp-hooks              # NEW: Hook management CLI
└── docs/
    └── chp/
        └── laws/              # Existing: Law definitions
```

## Hook Type Specifications

### Git Hooks (15 types)

| Hook Type | Trigger | Use Case | Exit Code Impact |
|-----------|---------|----------|------------------|
| `pre-commit` | Before `git commit` | Code quality checks | Blocks commit on failure |
| `post-commit` | After `git commit` | Notifications, metrics | No impact |
| `pre-push` | Before `git push` | Full codebase validation | Blocks push on failure |
| `post-merge` | After merge | Dependency updates, cleanup | No impact |
| `commit-msg` | After message edited | Commit message validation | Blocks commit on failure |
| `prepare-commit-msg` | Before message edit | Template injection | No impact |
| `pre-rebase` | Before rebase | Branch protection | Blocks rebase on failure |
| `post-checkout` | After checkout | Environment setup | No impact |
| `post-rewrite` | After rebase/amend | History tracking | No impact |
| `applypatch-msg` | After patch message | Patch validation | Blocks patch on failure |
| `pre-applypatch` | Before patch apply | Pre-flight checks | Blocks patch on failure |
| `post-applypatch` | After patch apply | Integration tasks | No impact |
| `update` | Before ref update (server) | Access control | Blocks update on failure |
| `pre-auto-gc` | Before garbage collection | Cleanup preparation | No impact |
| `post-rewrite` | After history rewrite | Metadata sync | No impact |

### AI/Agent Hooks (6 types)

| Hook Type | Trigger | Use Case | Exit Code Impact |
|-----------|---------|----------|------------------|
| `pre-prompt` | Before user prompt | Context injection | No impact |
| `post-prompt` | After user prompt | Intent analysis | No impact |
| `pre-tool` | Before tool execution | Parameter validation | Blocks tool on failure |
| `post-tool` | After tool execution | Result validation | May trigger retry |
| `pre-response` | Before agent response | Response validation | May regenerate response |
| `post-response` | After agent response | Quality metrics | No impact |

### CI/CD Hooks (4 types)

| Hook Type | Trigger | Use Case | Exit Code Impact |
|-----------|---------|----------|------------------|
| `pre-build` | Before build | Dependency checks | Blocks build on failure |
| `post-build` | After build | Artifact validation, testing | May fail pipeline |
| `pre-deploy` | Before deployment | Deployment verification | Blocks deploy on failure |
| `post-deploy` | After deployment | Health checks, rollback triggers | May trigger rollback |

## Component Design

### 1. Hook Registry (`hook-registry.sh`)

Manages the mapping between hook types and laws.

**Data Structure:**
```json
{
  "hooks": {
    "pre-commit": {
      "laws": ["no-console-log", "no-api-keys"],
      "enabled": true,
      "blocking": true
    },
    "post-commit": {
      "laws": ["metrics-collector"],
      "enabled": true,
      "blocking": false
    }
  }
}
```

**Functions:**
- `register_hook_law()` - Associate a law with a hook
- `unregister_hook_law()` - Remove law from hook
- `get_hook_laws()` - Get all laws for a hook
- `is_hook_blocking()` - Check if hook blocks on failure

### 2. Central Dispatcher (`dispatcher.sh`)

Universal hook handler that routes events to appropriate laws.

**Interface:**
```bash
dispatcher.sh <hook-type> [hook-specific-args]
```

**Behavior:**
1. Load hook registry
2. Identify laws registered for this hook type
3. Execute each law's verification script
4. Collect results
5. Apply blocking/non-blocking behavior based on hook type
6. Call tightener for failures

**Exit Codes:**
- `0` - All laws passed
- `1` - One or more laws failed (for blocking hooks)
- `2` - Dispatcher error

### 3. Hook Templates

Each hook type gets a template script that calls the dispatcher.

**Example: `hooks/git/pre-commit.sh`**
```bash
#!/bin/bash
# CHP pre-commit hook
# Installed to .git/hooks/pre-commit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-commit "$@"
```

### 4. Enhanced Installer

Updates existing installer to handle all hook types.

**New Functions:**
- `install_hook_template()` - Install hook to target location
- `uninstall_hook_template()` - Remove hook
- `create_hook_chain()` - Chain CHP with existing hooks
- `backup_existing_hook()` - Backup non-CHP hooks

**Installation Targets:**
- Git hooks: `.git/hooks/<hook-name>`
- Agent hooks: `.claude/hooks/<hook-name>.sh`
- CI/CD hooks: Configured via CI/CD integration

## Data Flow

```
User Action (e.g., git commit)
    ↓
Hook Triggered (.git/hooks/pre-commit)
    ↓
Dispatcher (dispatcher.sh pre-commit)
    ↓
Hook Registry Lookup
    ↓
For Each Registered Law:
    ├─ Load law.json
    ├─ Execute verify.sh
    ├─ Collect result
    └─ On failure: Call tightener.sh
    ↓
Aggregate Results
    ↓
Apply Blocking Rules
    ↓
Exit Code (0 = continue, 1 = block)
```

## Law Definition Update

Laws can now specify multiple hook types:

```json
{
  "name": "no-api-keys",
  "description": "Prevents API keys in code",
  "severity": "error",
  "hooks": ["pre-commit", "pre-push", "pre-tool"],
  "blocking": {
    "pre-commit": true,
    "pre-push": true,
    "pre-tool": false
  },
  "created": "2026-04-24",
  "failures": 0,
  "tightening_level": 0
}
```

## Implementation Phases

### Phase 1: Core Infrastructure
1. Implement `hook-registry.sh`
2. Implement `dispatcher.sh`
3. Update `detector.sh` for all hook types
4. Update `installer.sh` for universal installation

### Phase 2: Git Hooks
1. Create git hook templates
2. Implement git-specific utilities
3. Add git hook tests
4. Update `chp-law` CLI

### Phase 3: AI/Agent Hooks
1. Create agent hook templates
2. Implement agent-specific utilities
3. Add agent hook tests
4. Document agent integration

### Phase 4: CI/CD Hooks
1. Create CI/CD hook templates
2. Implement CI/CD integration utilities
3. Add CI/CD hook tests
4. Document CI/CD integration

### Phase 5: CLI and Documentation
1. Create `chp-hooks` command
2. Update existing commands
3. Write comprehensive documentation
4. Create examples

## Integration Points

### Claude Code Integration
Hooks integrate via `.claude/settings.json`:
```json
{
  "hooks": {
    "pre-tool": {
      "enabled": true,
      "command": "bash /path/to/chp/hooks/agent/pre-tool.sh"
    },
    "post-tool": {
      "enabled": true,
      "command": "bash /path/to/chp/hooks/agent/post-tool.sh"
    }
  }
}
```

### Git Integration
Standard git hooks in `.git/hooks/`

### CI/CD Integration
Via CI/CD configuration calling hook scripts:
```yaml
# Example GitHub Actions
- name: CHP Pre-Build Check
  run: bash ./chp/hooks/cicd/pre-build.sh
```

## Testing Strategy

Each hook type requires:
1. Unit tests for dispatcher logic
2. Integration tests for law execution
3. End-to-end tests for actual hook triggers
4. Tests for blocking/non-blocking behavior

## Migration Path

Existing installations:
1. Run migration script
2. Backs up existing hooks
3. Installs new dispatcher
4. Updates law definitions
5. Verifies installation

## Backwards Compatibility

- Existing law definitions work without modification
- Existing git hooks continue to function
- New hook types are opt-in
- Migration is non-destructive
