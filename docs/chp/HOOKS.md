# CHP Universal Hook System

Complete guide to using CHP hooks across Git, AI agents, and CI/CD pipelines.

## Overview

The CHP Universal Hook System provides a unified interface for enforcing laws across all development operations. It supports 25 hook types across three categories:

- **Git Hooks (15 types)** - Enforce laws during Git operations (commit, push, merge, etc.)
- **AI/Agent Hooks (6 types)** - Enforce laws during AI agent operations (Claude Code, Copilot CLI, etc.)
- **CI/CD Hooks (4 types)** - Enforce laws during build and deployment pipelines

### Architecture

The system uses a central dispatcher that routes hook events to relevant laws:

```
User Action (e.g., git commit)
    ↓
Hook Triggered (.git/hooks/pre-commit)
    ↓
Dispatcher (core/dispatcher.sh)
    ↓
Hook Registry Lookup (.chp/hook-registry.json)
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

### Key Concepts

- **Hook Type** - The specific event that triggers law execution (e.g., `pre-commit`)
- **Law** - A rule with verification logic that can be attached to multiple hooks
- **Blocking** - Whether a hook failure should prevent the operation from completing
- **Registry** - JSON file mapping hook types to their registered laws

## Quick Start

### Basic Commands

```bash
# Detect available hooks in your environment
./commands/chp-hooks detect

# List all hooks and their status
./commands/chp-hooks list

# Create a law for multiple hooks
./commands/chp-law create no-secrets --hooks=pre-commit,pre-push,pre-tool

# Enable/disable a hook
./commands/chp-hooks enable pre-commit
./commands/chp-hooks disable pre-commit

# Set blocking behavior
./commands/chp-hooks blocking pre-commit false  # Non-blocking
./commands/chp-hooks blocking pre-commit true   # Blocking (default)

# Install hook templates
./commands/chp-hooks install pre-commit
./commands/chp-hooks uninstall pre-commit
```

### Example Workflow

```bash
# 1. Create a law that runs on multiple hooks
./commands/chp-law create no-api-keys --hooks=pre-commit,pre-push,pre-tool

# 2. The law is automatically registered in the hook registry
./commands/chp-hooks registry

# 3. Install the hook templates
./commands/chp-hooks install pre-commit
./commands/chp-hooks install pre-push

# 4. The law will now run before commits, pushes, and tool executions
git commit  # Runs no-api-keys verification
```

## Hook Types Reference

### Git Hooks (15 types)

| Hook Type | Trigger | Blocking | Use Case |
|-----------|---------|----------|----------|
| `pre-commit` | Before `git commit` | Yes | Code quality checks, linting, security scans |
| `post-commit` | After `git commit` | No | Notifications, metrics collection, CI triggers |
| `pre-push` | Before `git push` | Yes | Full codebase validation, test coverage checks |
| `post-merge` | After merge completes | No | Dependency updates, cleanup tasks, notifications |
| `commit-msg` | After commit message edited | Yes | Commit message format validation |
| `prepare-commit-msg` | Before message editor opens | No | Template injection, ticket number addition |
| `pre-rebase` | Before rebase starts | Yes | Branch protection, conflict prevention |
| `post-checkout` | After checkout completes | No | Environment setup, dependency installation |
| `post-rewrite` | After rebase/amend/commit --rewrite | No | History tracking, metadata sync |
| `applypatch-msg` | After patch message edited | Yes | Patch message validation |
| `pre-applypatch` | Before patch applied | Yes | Pre-flight checks, patch validation |
| `post-applypatch` | After patch applied | No | Integration tasks, notifications |
| `update` | Before ref update (server-side) | Yes | Access control, branch protection |
| `pre-auto-gc` | Before garbage collection | No | Cleanup preparation |
| `post-update` | After ref update (server-side) | No | Notifications, CI triggers |

### AI/Agent Hooks (6 types)

| Hook Type | Trigger | Blocking | Use Case |
|-----------|---------|----------|----------|
| `pre-prompt` | Before user prompt processed | No | Context injection, intent analysis |
| `post-prompt` | After user prompt processed | No | Prompt logging, analytics |
| `pre-tool` | Before tool execution | Yes | Parameter validation, security checks |
| `post-tool` | After tool execution | No | Result validation, logging |
| `pre-response` | Before agent response | Yes | Response validation, filtering |
| `post-response` | After agent response | No | Quality metrics, analytics |

### CI/CD Hooks (4 types)

| Hook Type | Trigger | Blocking | Use Case |
|-----------|---------|----------|----------|
| `pre-build` | Before build starts | Yes | Dependency checks, environment validation |
| `post-build` | After build completes | Yes | Artifact validation, test execution |
| `pre-deploy` | Before deployment | Yes | Deployment verification, rollback checks |
| `post-deploy` | After deployment | Yes | Health checks, smoke tests, rollback triggers |

## Creating Laws for Hooks

### Law Creation Syntax

```bash
./commands/chp-law create <law-name> --hooks=<hook1,hook2,...>
```

### Examples

#### Single Hook Law

```bash
# Create a law that only runs on pre-commit
./commands/chp-law create no-console-log --hooks=pre-commit
```

#### Multi-Hook Law

```bash
# Create a law that runs on multiple hooks
./commands/chp-law create no-secrets --hooks=pre-commit,pre-push,pre-tool,pre-build
```

#### Non-Blocking Law

```bash
# Create a metrics collection law (non-blocking)
./commands/chp-law create commit-metrics --hooks=post-commit
./commands/chp-hooks blocking post-commit false
```

### Law Structure

When you create a law, the following files are generated:

```
docs/chp/laws/<law-name>/
├── law.json       # Law metadata (hooks, severity, failures)
├── verify.sh      # Verification script (implement your logic here)
└── guidance.md    # Human-readable compliance guidance
```

### Example: Custom Law

```bash
# Create the law
./commands/chp-law create no-hardcoded-urls --hooks=pre-commit,pre-push

# Edit the verification script
nano docs/chp/laws/no-hardcoded-urls/verify.sh

# Implement verification logic
# Example: Check for hardcoded URLs in code
git diff --cached | grep -E 'https?://localhost|127\.0\.0\.1' && {
    echo "Hardcoded URLs detected"
    exit 1
}

# Test the law
./commands/chp-law test no-hardcoded-urls

# Commit and push - the law will run automatically
```

## Managing Hooks

### List Hooks

```bash
./commands/chp-hooks list
```

Output:
```
Hook Type           Enabled    Blocking   Laws
------------------------------------------------------------
pre-commit          yes        yes        2
pre-push            yes        yes        2
post-commit         yes        no         1
pre-tool            yes        yes        1
```

### Enable/Disable Hooks

```bash
# Disable a hook (laws won't run)
./commands/chp-hooks disable pre-commit

# Re-enable a hook
./commands/chp-hooks enable pre-commit
```

**Use cases:**
- Temporarily disable hooks during debugging
- Disable non-blocking hooks to improve performance
- Enable hooks gradually after law creation

### Set Blocking Behavior

```bash
# Make hook non-blocking (logs failures but allows operation)
./commands/chp-hooks blocking pre-commit false

# Make hook blocking (fails operation on law violations)
./commands/chp-hooks blocking pre-commit true
```

**Default behavior:** Most hooks are blocking by default, except `post-*` hooks.

### Install Hook Templates

Hook templates must be installed to their target locations:

```bash
# Install git hook
./commands/chp-hooks install pre-commit

# Install agent hook
./commands/chp-hooks install pre-tool

# Install CI/CD hook
./commands/chp-hooks install pre-build
```

**Installation locations:**
- Git hooks: `.git/hooks/<hook-name>`
- Agent hooks: `.claude/hooks/<hook-name>.sh`
- CI/CD hooks: `.chp/cicd-hooks/<hook-name>.sh`

### Uninstall Hooks

```bash
./commands/chp-hooks uninstall pre-commit
```

This removes the hook template and restores any backed-up original hooks.

## Claude Code Integration

### Setup

1. **Install agent hooks to `.claude/hooks`:**

```bash
./commands/chp-hooks install pre-tool
./commands/chp-hooks install post-tool
```

2. **Configure Claude Code settings:**

Edit `.claude/settings.json`:

```json
{
  "hooks": {
    "pre-tool": {
      "enabled": true,
      "command": "bash .claude/hooks/pre-tool.sh"
    },
    "post-tool": {
      "enabled": true,
      "command": "bash .claude/hooks/post-tool.sh"
    },
    "pre-prompt": {
      "enabled": false,
      "command": "bash .claude/hooks/pre-prompt.sh"
    },
    "post-prompt": {
      "enabled": false,
      "command": "bash .claude/hooks/post-prompt.sh"
    }
  }
}
```

3. **Create laws for agent hooks:**

```bash
# Block dangerous tool operations
./commands/chp-law create safe-tool-usage --hooks=pre-tool

# Edit verify.sh to check tool parameters
# Example: Block Write tool in certain directories
```

### Available Agent Hooks

- `pre-tool` - Validate tool parameters before execution
- `post-tool` - Validate tool results after execution
- `pre-prompt` - Inject context before prompt processing
- `post-prompt` - Log prompts for analytics
- `pre-response` - Filter responses before display
- `post-response` - Collect quality metrics

### Example: Safe File Operations

```bash
# Create law to prevent file writes to sensitive directories
./commands/chp-law create protect-sensitive-dirs --hooks=pre-tool

# Edit verify.sh:
#!/bin/bash
# Check if Write tool is being used
if [[ "$TOOL_NAME" == "Write" ]]; then
    # Check if path contains sensitive directories
    if [[ "$FILE_PATH" =~ /etc/|/system/|/boot/ ]]; then
        echo "Blocked: Cannot write to system directory"
        exit 1
    fi
fi
exit 0
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/chp-check.yml`:

```yaml
name: CHP Law Enforcement

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  chp-pre-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup CHP
        run: |
          chmod +x ./commands/chp-hooks
          chmod +x ./commands/chp-law

      - name: Run Pre-Build Checks
        run: bash .chp/cicd-hooks/pre-build.sh

  chp-build:
    needs: chp-pre-build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Project
        run: |
          npm ci
          npm run build

      - name: Run Post-Build Checks
        run: bash .chp/cicd-hooks/post-build.sh

  chp-deploy:
    needs: chp-build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3

      - name: Run Pre-Deploy Checks
        run: bash .chp/cicd-hooks/pre-deploy.sh

      - name: Deploy to Production
        run: |
          # Your deployment commands
          npm run deploy

      - name: Run Post-Deploy Checks
        run: bash .chp/cicd-hooks/post-deploy.sh
```

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
stages:
  - pre-build
  - build
  - deploy

chp-pre-build:
  stage: pre-build
  script:
    - bash .chp/cicd-hooks/pre-build.sh
  only:
    - main
    - develop
    - merge_requests

build:
  stage: build
  script:
    - npm ci
    - npm run build
    - bash .chp/cicd-hooks/post-build.sh
  artifacts:
    paths:
      - dist/

deploy:
  stage: deploy
  script:
    - bash .chp/cicd-hooks/pre-deploy.sh
    - npm run deploy
    - bash .chp/cicd-hooks/post-deploy.sh
  only:
    - main
  when: manual
```

### Jenkins Pipeline

Create `Jenkinsfile`:

```groovy
pipeline {
    agent any

    stages {
        stage('Pre-Build Checks') {
            steps {
                sh 'bash .chp/cicd-hooks/pre-build.sh'
            }
        }

        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
            }
        }

        stage('Post-Build Checks') {
            steps {
                sh 'bash .chp/cicd-hooks/post-build.sh'
            }
        }

        stage('Pre-Deploy Checks') {
            when {
                branch 'main'
            }
            steps {
                sh 'bash .chp/cicd-hooks/pre-deploy.sh'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh 'npm run deploy'
            }
        }

        stage('Post-Deploy Checks') {
            when {
                branch 'main'
            }
            steps {
                sh 'bash .chp/cicd-hooks/post-deploy.sh'
            }
        }
    }

    post {
        failure {
            mail to: 'team@example.com',
                 subject: "CHP Checks Failed: ${env.JOB_NAME}",
                 body: "One or more CHP laws failed during ${env.STAGE_NAME}."
        }
    }
}
```

## Troubleshooting

### Hook Not Running

**Symptom:** Laws not executing when hook should trigger.

**Diagnosis:**

```bash
# 1. Check if hook is enabled
./commands/chp-hooks list

# 2. Check if hook template is installed
ls -la .git/hooks/          # For git hooks
ls -la .claude/hooks/       # For agent hooks
ls -la .chp/cicd-hooks/     # For CI/CD hooks

# 3. Check if hook is executable
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x (executable)

# 4. Test hook manually
bash .git/hooks/pre-commit
```

**Solutions:**

```bash
# Enable the hook
./commands/chp-hooks enable pre-commit

# Install the hook template
./commands/chp-hooks install pre-commit

# Make hook executable
chmod +x .git/hooks/pre-commit
```

### Law Not Running on Hook

**Symptom:** Hook runs but specific law doesn't execute.

**Diagnosis:**

```bash
# 1. Check if law is registered
./commands/chp-hooks registry

# 2. Check law's hook list
cat docs/chp/laws/<law-name>/law.json | jq '.hooks'

# 3. Check if law is enabled
cat docs/chp/laws/<law-name>/law.json | jq '.enabled'
```

**Solutions:**

```bash
# Re-register the law
./commands/chp-law delete <law-name>
./commands/chp-law create <law-name> --hooks=<hooks>

# Enable the law
./commands/chp-law enable <law-name>
```

### Hook Causing Performance Issues

**Symptom:** Operations (commit, push) are slow.

**Diagnosis:**

```bash
# Enable debug mode to see which laws are running
CHP_DEBUG=true ./commands/chp-hooks list

# Check law execution time
time ./commands/chp-law test <law-name>
```

**Solutions:**

```bash
# Disable non-critical hooks
./commands/chp-hooks disable post-commit

# Make hook non-blocking (runs but doesn't fail operation)
./commands/chp-hooks blocking pre-commit false

# Optimize slow laws
nano docs/chp/laws/<law-name>/verify.sh
```

### Permission Errors

**Symptom:** "Permission denied" when running hooks.

**Solutions:**

```bash
# Make hook executable
chmod +x .git/hooks/pre-commit
chmod +x .claude/hooks/pre-tool.sh
chmod +x .chp/cicd-hooks/pre-build.sh

# Make verification scripts executable
chmod +x docs/chp/laws/*/verify.sh

# Make commands executable
chmod +x commands/chp-hooks
chmod +x commands/chp-law
```

### Hook Registry Corruption

**Symptom:** Commands fail with JSON parse errors.

**Diagnosis:**

```bash
# Validate registry JSON
cat .chp/hook-registry.json | jq '.'
```

**Solutions:**

```bash
# Reinitialize registry (clears all registrations)
rm .chp/hook-registry.json
./commands/chp-hooks registry

# Re-register laws
./commands/chp-law delete <law-name>
./commands/chp-law create <law-name> --hooks=<hooks>
```

## Best Practices

### 1. Hook Selection

- **Use blocking hooks sparingly** - Only block on critical failures
- **Pre-commit for fast checks** - Linting, formatting, basic validation
- **Pre-push for comprehensive checks** - Full test suite, security scans
- **Post-* hooks for notifications** - Metrics, alerts, CI triggers

### 2. Law Design

- **Keep laws focused** - One law should check one thing
- **Fast verification** - Pre-commit hooks should complete in < 5 seconds
- **Clear error messages** - Tell users exactly what failed and how to fix it
- **Idempotent** - Laws should give same result on repeated runs

### 3. Blocking vs Non-Blocking

**Use blocking for:**
- Security violations (API keys, secrets)
- Critical bugs (syntax errors, type errors)
- Policy violations (license compliance, data handling)

**Use non-blocking for:**
- Metrics collection
- Style suggestions
- Documentation checks
- Performance warnings

### 4. Hook Organization

```bash
# Development workflow
./commands/chp-law create quick-check --hooks=pre-commit           # Fast linting
./commands/chp-law create full-check --hooks=pre-push              # Full tests
./commands/chp-law create deploy-check --hooks=pre-deploy          # Deployment validation
./commands/chp-law create metrics --hooks=post-commit              # Metrics (non-blocking)
```

### 5. CI/CD Integration

```bash
# Create CI-specific laws
./commands/chp-law create ci-build-check --hooks=pre-build,post-build
./commands/chp-law create ci-deploy-check --hooks=pre-deploy,post-deploy

# Set appropriate blocking behavior
./commands/chp-hooks blocking post-build true    # Fail pipeline on errors
./commands/chp-hooks blocking post-deploy true   # Rollback on errors
```

### 6. Testing

```bash
# Test laws before committing
./commands/chp-law test <law-name>

# Test hooks manually
bash .git/hooks/pre-commit

# Use non-blocking mode during development
./commands/chp-hooks blocking pre-commit false
```

### 7. Maintenance

```bash
# Periodically review and update laws
./commands/chp-law list

# Reset failure counts after fixes
./commands/chp-law reset <law-name>

# Disable outdated laws
./commands/chp-law disable <law-name>

# Delete unused laws
./commands/chp-law delete <law-name>
```

## Advanced Usage

### Custom Hook Categories

You can extend the system with custom hook types by:

1. Creating hook templates in `hooks/custom/`
2. Adding detection logic to `core/detector.sh`
3. Implementing installation logic in `core/installer.sh`

### Hook Chaining

Multiple laws can be registered to the same hook:

```bash
./commands/chp-law create lint --hooks=pre-commit
./commands/chp-law create security-scan --hooks=pre-commit
./commands/chp-law create test-coverage --hooks=pre-commit

# All three laws will run on pre-commit
```

### Conditional Hook Execution

Add conditional logic to verification scripts:

```bash
#!/bin/bash
# Only run on specific branches
if [[ "$(git branch --show-current)" != "main" ]]; then
    exit 0  # Skip check on non-main branches
fi

# Your verification logic here
```

### Environment-Specific Hooks

```bash
#!/bin/bash
# Different behavior based on environment
if [[ "${CI:-false}" == "true" ]]; then
    # CI environment - run comprehensive checks
    run_full_test_suite
else
    # Local development - run quick checks
    run_quick_checks
fi
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Action                             │
│                    (git commit, push, etc.)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Hook Triggered                             │
│              (.git/hooks/pre-commit, etc.)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Central Dispatcher                            │
│              (core/dispatcher.sh)                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. Load hook registry                                  │   │
│  │  2. Check if hook is enabled                           │   │
│  │  3. Get registered laws for this hook                  │   │
│  │  4. For each law:                                      │   │
│  │     a. Load law.json                                   │   │
│  │     b. Execute verify.sh                               │   │
│  │     c. Collect result                                  │   │
│  │     d. On failure: Call tightener.sh                   │   │
│  │  5. Aggregate results                                  │   │
│  │  6. Check blocking behavior                            │   │
│  │  7. Return exit code                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Hook Registry                                │
│               (.chp/hook-registry.json)                         │
│  {                                                              │
│    "hooks": {                                                   │
│      "pre-commit": {                                            │
│        "laws": ["no-console-log", "no-api-keys"],              │
│        "enabled": true,                                         │
│        "blocking": true                                         │
│      }                                                          │
│    }                                                            │
│  }                                                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Law Execution                                │
│  For each law in registry:                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  docs/chp/laws/<law-name>/verify.sh                     │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │  • Load law metadata                            │    │   │
│  │  │  • Run verification logic                      │    │   │
│  │  │  • Return exit code (0=pass, 1=fail)           │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Result Aggregation                            │
│  • Count passed laws                                            │
│  • Count failed laws                                            │
│  • Collect error messages                                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Blocking Behavior                               │
│  IF hook is blocking AND laws failed:                          │
│    → Exit with error code 1 (block operation)                  │
│  ELSE:                                                          │
│    → Exit with error code 0 (allow operation)                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Final Result                               │
│  Success: Operation continues                                  │
│  Failure: Operation blocked with error message                 │
└─────────────────────────────────────────────────────────────────┘
```

## Examples

### Example 1: Prevent Secrets in Code

```bash
# Create law
./commands/chp-law create no-secrets --hooks=pre-commit,pre-push,pre-tool

# Edit verify.sh
cat > docs/chp/laws/no-secrets/verify.sh <<'EOF'
#!/bin/bash
# Check for common secret patterns

# Patterns to detect
patterns=(
    "sk-[a-zA-Z0-9]{32}"           # Stripe keys
    "AIza[0-9A-Za-z\\-_]{35}"       # Google API keys
    "AKIA[0-9A-Z]{16}"             # AWS access keys
    "[09]{9,}"                     # Potential credit card numbers
)

# Check staged files
files=$(git diff --cached --name-only --diff-filter=ACM)
for file in $files; do
    if [[ -f "$file" ]]; then
        for pattern in "${patterns[@]}"; do
            if grep -qE "$pattern" "$file"; then
                echo "ERROR: Potential secret detected in $file"
                echo "Pattern: $pattern"
                exit 1
            fi
        done
    fi
done

exit 0
EOF

chmod +x docs/chp/laws/no-secrets/verify.sh

# Test
./commands/chp-law test no-secrets
```

### Example 2: Enforce Commit Message Format

```bash
# Create law
./commands/chp-law create commit-format --hooks=commit-msg

# Edit verify.sh
cat > docs/chp/laws/commit-format/verify.sh <<'EOF'
#!/bin/bash
# Enforce conventional commit format

commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Format: type(scope): description
pattern="^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,72}"

if ! [[ "$commit_msg" =~ $pattern ]]; then
    echo "ERROR: Commit message must follow conventional commit format"
    echo "Format: type(scope): description"
    echo "Types: feat, fix, docs, style, refactor, test, chore"
    echo "Example: feat(auth): add OAuth2 login support"
    exit 1
fi

exit 0
EOF

chmod +x docs/chp/laws/commit-format/verify.sh

# Install hook
./commands/chp-hooks install commit-msg
```

### Example 3: Collect Commit Metrics

```bash
# Create law
./commands/chp-law create commit-metrics --hooks=post-commit

# Make non-blocking
./commands/chp-hooks blocking post-commit false

# Edit verify.sh
cat > docs/chp/laws/commit-metrics/verify.sh <<'EOF'
#!/bin/bash
# Collect commit metrics

metrics_file="$CHP_BASE/.chp/commit-metrics.json"

# Initialize metrics
if [[ ! -f "$metrics_file" ]]; then
    echo '{"commits": 0, "files_changed": 0, "lines_added": 0, "lines_deleted": 0}' > "$metrics_file"
fi

# Get commit stats
files_changed=$(git diff --shortstat HEAD~1 HEAD | grep -oE '[0-9]+ file' | grep -oE '[0-9]+')
lines_added=$(git diff --shortstat HEAD~1 HEAD | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
lines_deleted=$(git diff --shortstat HEAD~1 HEAD | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')

# Update metrics
jq --argjson fc "${files_changed:-0}" \
   --argjson la "${lines_added:-0}" \
   --argjson ld "${lines_deleted:-0}" \
   '.commits += 1 | .files_changed += $fc | .lines_added += $la | .lines_deleted += $ld' \
   "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"

echo "📊 Commit metrics updated"
exit 0
EOF

chmod +x docs/chp/laws/commit-metrics/verify.sh
```

## Additional Resources

- [Main CHP Documentation](../README.md)
- [Law Creation Guide](LAWS.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [GitHub Repository](https://github.com/your-repo/chp)

## Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Check existing documentation
- Review example laws in `docs/chp/laws/`
