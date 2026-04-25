# CHP Universal Hook System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a universal hook dispatcher that integrates CHP law enforcement across Git hooks, AI agent operations, and CI/CD pipelines.

**Architecture:** Central dispatcher with hook registry maps hook events to relevant CHP laws. Hook templates call dispatcher, which executes law verification scripts and applies blocking/non-blocking behavior. Shell-based for maximum portability.

**Tech Stack:** Bash scripts, JSON, Git hooks, Claude Code hooks, CI/CD integration

---

## File Structure

```
chp/
├── core/
│   ├── common.sh              # Existing: Shared utilities
│   ├── hook-registry.sh       # NEW: Hook type registry and management
│   ├── dispatcher.sh          # NEW: Central hook dispatcher
│   ├── detector.sh            # Existing: Hook detection (modify)
│   └── installer.sh           # Existing: Hook installation (modify)
├── hooks/
│   ├── git/                   # NEW: Git hook templates (15 files)
│   ├── agent/                 # NEW: AI agent hook templates (6 files)
│   └── cicd/                  # NEW: CI/CD hook templates (4 files)
├── commands/
│   └── chp-hooks              # NEW: Hook management CLI
├── tests/
│   ├── test-hook-registry.sh  # NEW
│   ├── test-dispatcher.sh     # NEW
│   └── test-hook-templates.sh # NEW
└── .claude/
    └── hooks/                 # NEW: Claude Code hook integration
```

---

## Phase 1: Core Infrastructure

### Task 1: Create hook-registry.sh - Hook type registry

**Files:**
- Create: `core/hook-registry.sh`
- Test: `tests/test-hook-registry.sh`

- [ ] **Step 1: Write failing test for hook registry**

```bash
#!/bin/bash
# Test hook registry functionality

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/hook-registry.sh"

# Test registry initialization
echo "Testing init_hook_registry..."
init_hook_registry
if [ -f "$HOOK_REGISTRY_FILE" ]; then
    echo "PASS: Registry file created"
else
    echo "FAIL: Registry file not created"
    exit 1
fi

# Test registering a law
echo "Testing register_hook_law..."
register_hook_law "pre-commit" "test-law"
if get_hook_laws "pre-commit" | grep -q "test-law"; then
    echo "PASS: Law registered"
else
    echo "FAIL: Law not registered"
    exit 1
fi

# Test unregistering
echo "Testing unregister_hook_law..."
unregister_hook_law "pre-commit" "test-law"
if ! get_hook_laws "pre-commit" | grep -q "test-law"; then
    echo "PASS: Law unregistered"
else
    echo "FAIL: Law still registered"
    exit 1
fi

echo "All tests passed!"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-hook-registry.sh
```

Expected: FAIL with `init_hook_registry: command not found`

- [ ] **Step 3: Write hook-registry.sh implementation**

```bash
#!/bin/bash
# Hook registry - manages mapping between hook types and laws

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Registry file location
HOOK_REGISTRY_FILE="$CHP_BASE/.chp/hook-registry.json"

# Initialize registry file
init_hook_registry() {
    local registry_dir="$(dirname "$HOOK_REGISTRY_FILE")"
    mkdir -p "$registry_dir"

    if [ ! -f "$HOOK_REGISTRY_FILE" ]; then
        cat > "$HOOK_REGISTRY_FILE" <<'EOF'
{
  "hooks": {},
  "version": "1.0"
}
EOF
        log_info "Initialized hook registry at $HOOK_REGISTRY_FILE"
    fi
}

# Ensure registry exists
_ensure_registry() {
    if [ ! -f "$HOOK_REGISTRY_FILE" ]; then
        init_hook_registry
    fi
}

# Register a law for a hook type
register_hook_law() {
    local hook_type="$1"
    local law_name="$2"

    _ensure_registry

    # Add hook if not exists
    local temp_file="${HOOK_REGISTRY_FILE}.tmp"
    jq --arg ht "$hook_type" --arg ln "$law_name" '
        if .hooks[$ht] == null then
            .hooks[$ht] = {"laws": [$ln], "enabled": true, "blocking": true}
        else
            .hooks[$ht].laws |= if index($ln) then . else . + [$ln] end
        end
    ' "$HOOK_REGISTRY_FILE" > "$temp_file"
    mv "$temp_file" "$HOOK_REGISTRY_FILE"

    log_debug "Registered law '$law_name' for hook '$hook_type'"
}

# Unregister a law from a hook type
unregister_hook_law() {
    local hook_type="$1"
    local law_name="$2"

    _ensure_registry

    local temp_file="${HOOK_REGISTRY_FILE}.tmp"
    jq --arg ht "$hook_type" --arg ln "$law_name" '
        if .hooks[$ht] != null then
            .hooks[$ht].laws |= map(select(. != $ln))
        end
    ' "$HOOK_REGISTRY_FILE" > "$temp_file"
    mv "$temp_file" "$HOOK_REGISTRY_FILE"

    log_debug "Unregistered law '$law_name' from hook '$hook_type'"
}

# Get all laws for a hook type
get_hook_laws() {
    local hook_type="$1"

    _ensure_registry

    jq -r --arg ht "$hook_type" '
        if .hooks[$ht] == null then
            empty
        else
            .hooks[$ht].laws[]
        end
    ' "$HOOK_REGISTRY_FILE"
}

# Check if a hook is blocking (returns 0=blocking, 1=non-blocking)
is_hook_blocking() {
    local hook_type="$1"

    _ensure_registry

    local blocking=$(jq -r --arg ht "$hook_type" '
        if .hooks[$ht] == null then
            "true"
        else
            .hooks[$ht].blocking | tostring
        end
    ' "$HOOK_REGISTRY_FILE")

    [ "$blocking" = "true" ]
}

# Check if a hook is enabled
is_hook_enabled() {
    local hook_type="$1"

    _ensure_registry

    local enabled=$(jq -r --arg ht "$hook_type" '
        if .hooks[$ht] == null then
            "true"
        else
            .hooks[$ht].enabled | tostring
        end
    ' "$HOOK_REGISTRY_FILE")

    [ "$enabled" = "true" ]
}

# Set hook blocking behavior
set_hook_blocking() {
    local hook_type="$1"
    local blocking="$2"

    _ensure_registry

    local temp_file="${HOOK_REGISTRY_FILE}.tmp"
    jq --arg ht "$hook_type" --arg bl "$blocking" '
        if .hooks[$ht] == null then
            .hooks[$ht] = {"laws": [], "enabled": true, "blocking": ($bl == "true")}
        else
            .hooks[$ht].blocking = ($bl == "true")
        end
    ' "$HOOK_REGISTRY_FILE" > "$temp_file"
    mv "$temp_file" "$HOOK_REGISTRY_FILE"
}

# Set hook enabled state
set_hook_enabled() {
    local hook_type="$1"
    local enabled="$2"

    _ensure_registry

    local temp_file="${HOOK_REGISTRY_FILE}.tmp"
    jq --arg ht "$hook_type" --arg en "$enabled" '
        if .hooks[$ht] == null then
            .hooks[$ht] = {"laws": [], "enabled": ($en == "true"), "blocking": true}
        else
            .hooks[$ht].enabled = ($en == "true")
        end
    ' "$HOOK_REGISTRY_FILE" > "$temp_file"
    mv "$temp_file" "$HOOK_REGISTRY_FILE"
}

# List all registered hooks
list_hooks() {
    _ensure_registry

    jq -r '.hooks | to_entries[] | "\(.key) | laws: \(.value.laws | length) | enabled: \(.value.enabled) | blocking: \(.value.blocking)"' "$HOOK_REGISTRY_FILE"
}

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    case "${1:-}" in
        init)
            init_hook_registry
            ;;
        list)
            list_hooks
            ;;
        *)
            echo "Usage: hook-registry.sh {init|list}"
            exit 1
            ;;
    esac
fi
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-hook-registry.sh
```

Expected: PASS - All tests pass

- [ ] **Step 5: Add log_debug function to common.sh**

```bash
# Add to common.sh after other log functions
log_debug() {
    if [ "${CHP_DEBUG:-false}" = "true" ]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1" >&2
    fi
}
```

- [ ] **Step 6: Commit**

```bash
git add core/hook-registry.sh core/common.sh tests/test-hook-registry.sh
git commit -m "feat: add hook registry for managing hook-to-law mappings"
```

---

### Task 2: Create dispatcher.sh - Central hook dispatcher

**Files:**
- Create: `core/dispatcher.sh`
- Test: `tests/test-dispatcher.sh`

- [ ] **Step 1: Write failing test for dispatcher**

```bash
#!/bin/bash
# Test dispatcher functionality

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/hook-registry.sh"
source "$(dirname "$0")/../core/dispatcher.sh"

# Setup test environment
export CHp_BASE="$(dirname "$0")/.."
export CHp_DEBUG="true"

echo "Testing dispatch_hook..."

# Create a test law
mkdir -p "$LAWS_DIR/test-law"
cat > "$LAWS_DIR/test-law/law.json" <<'EOF'
{
  "name": "test-law",
  "description": "Test law",
  "severity": "error",
  "hooks": ["pre-commit"],
  "created": "2026-04-24",
  "failures": 0,
  "tightening_level": 0
}
EOF

cat > "$LAWS_DIR/test-law/verify.sh" <<'EOF'
#!/bin/bash
echo "Test law verification passed"
exit 0
EOF
chmod +x "$LAWS_DIR/test-law/verify.sh"

# Register the law
init_hook_registry
register_hook_law "pre-commit" "test-law"

# Test dispatching
if dispatch_hook "pre-commit"; then
    echo "PASS: Hook dispatched successfully"
else
    echo "FAIL: Hook dispatch failed"
    exit 1
fi

# Cleanup
rm -rf "$LAWS_DIR/test-law"
unregister_hook_law "pre-commit" "test-law"

echo "All dispatcher tests passed!"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-dispatcher.sh
```

Expected: FAIL with `dispatch_hook: command not found`

- [ ] **Step 3: Write dispatcher.sh implementation**

```bash
#!/bin/bash
# Central hook dispatcher - routes hook events to relevant laws

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/hook-registry.sh"

# Dispatch a hook event to all registered laws
dispatch_hook() {
    local hook_type="$1"
    shift
    local hook_args=("$@")

    # Check if hook is enabled
    if ! is_hook_enabled "$hook_type"; then
        log_debug "Hook '$hook_type' is disabled, skipping"
        return 0
    fi

    # Get laws for this hook
    local laws=$(get_hook_laws "$hook_type")

    if [ -z "$laws" ]; then
        log_debug "No laws registered for hook '$hook_type'"
        return 0
    fi

    log_info "CHP Dispatcher: Executing $hook_type hook"

    local failed_laws=()
    local passed=0
    local failed=0

    # Execute each law's verification
    while IFS= read -r law_name; do
        if [ -z "$law_name" ]; then
            continue
        fi

        log_info "  Checking law: $law_name"

        local law_dir="$LAWS_DIR/$law_name"
        local verify_script="$law_dir/verify.sh"

        # Check if law exists
        if [ ! -d "$law_dir" ]; then
            log_warn "    Law directory not found: $law_dir"
            continue
        fi

        # Check if verify script exists
        if [ ! -f "$verify_script" ]; then
            log_warn "    Verification script not found: $verify_script"
            continue
        fi

        # Run verification
        if bash "$verify_script" "${hook_args[@]}"; then
            log_info "    ✓ Passed"
            passed=$((passed + 1))
        else
            local exit_code=$?
            log_error "    ✗ Failed (exit code: $exit_code)"
            failed_laws+=("$law_name")
            failed=$((failed + 1))

            # Trigger tightening for failures
            if [ -f "$(dirname "${BASH_SOURCE[0]}")/tightener.sh" ]; then
                source "$(dirname "${BASH_SOURCE[0]}")/tightener.sh"
                record_failure "$law_name"
            fi
        fi
    done <<< "$laws"

    # Output summary
    echo ""
    log_info "CHP Dispatcher Results: $passed passed, $failed failed"

    # Determine exit code based on blocking behavior
    if is_hook_blocking "$hook_type"; then
        if [ $failed -gt 0 ]; then
            log_error "Hook '$hook_type' is blocking and $failed law(s) failed"
            return 1
        fi
    else
        if [ $failed -gt 0 ]; then
            log_warn "Hook '$hook_type' is non-blocking, $failed law(s) failed but continuing"
        fi
    fi

    return 0
}

# Get hook context information
get_hook_context() {
    local hook_type="$1"

    case "$hook_type" in
        pre-commit)
            echo "git diff --cached --name-only"
            ;;
        pre-push)
            echo "git diff --name-only HEAD @{u}"
            ;;
        commit-msg)
            echo ".git/COMMIT_EDITMSG"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Main dispatcher entry point
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ -z "${1:-}" ]; then
        log_error "Usage: dispatcher.sh <hook-type> [hook-args]"
        exit 2
    fi

    dispatch_hook "$@"
    exit $?
fi
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-dispatcher.sh
```

Expected: PASS - All tests pass

- [ ] **Step 5: Commit**

```bash
git add core/dispatcher.sh tests/test-dispatcher.sh
git commit -m "feat: add central hook dispatcher"
```

---

### Task 3: Update detector.sh for all hook types

**Files:**
- Modify: `core/detector.sh`
- Test: `tests/test-detector.sh`

- [ ] **Step 1: Write test for expanded hook detection**

```bash
#!/bin/bash
# Test expanded hook detection

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/detector.sh"

echo "Testing detect_all_git_hooks..."
git_hooks=$(detect_all_git_hooks)
echo "Git hooks: $git_hooks"

echo "Testing detect_all_agent_hooks..."
agent_hooks=$(detect_all_agent_hooks)
echo "Agent hooks: $agent_hooks"

echo "Testing detect_all_cicd_hooks..."
cicd_hooks=$(detect_all_cicd_hooks)
echo "CI/CD hooks: $cicd_hooks"

echo "Testing detect_all_hooks..."
all_hooks=$(detect_all_hooks)
echo "All hooks: $all_hooks"

echo "All detection tests passed!"
```

- [ ] **Step 2: Run test to see current state**

```bash
bash tests/test-detector.sh
```

Expected: Partial FAIL - New functions don't exist

- [ ] **Step 3: Update detector.sh with comprehensive hook detection**

```bash
#!/bin/bash
# Detect available hook systems

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Git hooks (all standard git hooks)
detect_all_git_hooks() {
    if [ -d .git ]; then
        echo "pre-commit post-commit pre-push post-merge commit-msg prepare-commit-msg pre-rebase post-checkout post-rewrite applypatch-msg pre-applypatch post-applypatch update pre-auto-gc"
    fi
}

# Agent hooks (Claude Code, Copilot CLI, etc.)
detect_all_agent_hooks() {
    local agent_hooks="pre-prompt post-prompt pre-tool post-tool pre-response post-response"

    # Check if Claude Code hooks directory exists
    if [ -d .claude ]; then
        echo "$agent_hooks"
    fi

    # Check for other agent systems
    if [ -f .copilot ] || [ -d .copilot ]; then
        echo "$agent_hooks"
    fi
}

# CI/CD hooks
detect_all_cicd_hooks() {
    local cicd_hooks="pre-build post-build pre-deploy post-deploy"

    # Detect CI/CD by presence of config files
    if [ -f .github/workflows/*.yml ] || [ -f .gitlab-ci.yml ] || [ -f Jenkinsfile ]; then
        echo "$cicd_hooks"
    fi

    # Also return if explicitly opted in
    if [ -f .chp/cicd-enabled ]; then
        echo "$cicd_hooks"
    fi
}

# Detect all available hooks across all systems
detect_all_hooks() {
    local all_hooks=""

    # Add git hooks
    local git_hooks=$(detect_all_git_hooks)
    all_hooks="$all_hooks $git_hooks"

    # Add agent hooks
    local agent_hooks=$(detect_all_agent_hooks)
    all_hooks="$all_hooks $agent_hooks"

    # Add CI/CD hooks
    local cicd_hooks=$(detect_all_cicd_hooks)
    all_hooks="$all_hooks $cicd_hooks"

    # Deduplicate and return
    echo "$all_hooks" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs
}

# Detect git hooks (legacy function)
detect_git_hooks() {
    if [ -d .git ]; then
        echo "pre-commit pre-push pre-merge-commit"
    fi
}

# Detect pretool hooks (legacy function)
detect_pretool_hooks() {
    if [ -f .pretool ] || [ -d .pretool ]; then
        echo "pre-write pre-commit pre-push"
    fi
}

# Detect available hooks (legacy function)
detect_available_hooks() {
    local all_hooks=""

    # Check git
    if [ -d .git ]; then
        all_hooks="$all_hooks $(detect_git_hooks)"
    fi

    # Check pretool
    if [ -f .pretool ] || [ -d .pretool ]; then
        all_hooks="$all_hooks $(detect_pretool_hooks)"
    fi

    # Deduplicate and return
    echo "$all_hooks" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs
}

# Get hook category (git, agent, or cicd)
get_hook_category() {
    local hook_type="$1"

    local git_hooks=$(detect_all_git_hooks)
    local agent_hooks=$(detect_all_agent_hooks)
    local cicd_hooks=$(detect_all_cicd_hooks)

    if echo "$git_hooks" | grep -qw "$hook_type"; then
        echo "git"
    elif echo "$agent_hooks" | grep -qw "$hook_type"; then
        echo "agent"
    elif echo "$cicd_hooks" | grep -qw "$hook_type"; then
        echo "cicd"
    else
        echo "unknown"
    fi
}

# Check if a specific hook type is available
is_hook_available() {
    local hook_type="$1"
    local all_hooks=$(detect_all_hooks)

    echo "$all_hooks" | grep -qw "$hook_type"
}

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    case "${1:-}" in
        all)
            detect_all_hooks
            ;;
        git)
            detect_all_git_hooks
            ;;
        agent)
            detect_all_agent_hooks
            ;;
        cicd)
            detect_all_cicd_hooks
            ;;
        category)
            get_hook_category "$2"
            ;;
        *)
            detect_available_hooks
            ;;
    esac
fi
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-detector.sh
```

Expected: PASS - Shows all hook types

- [ ] **Step 5: Commit**

```bash
git add core/detector.sh tests/test-detector.sh
git commit -m "feat: expand hook detection for all hook types"
```

---

### Task 4: Update installer.sh for universal installation

**Files:**
- Modify: `core/installer.sh`
- Test: `tests/test-installer.sh`

- [ ] **Step 1: Write test for universal installer**

```bash
#!/bin/bash
# Test universal hook installation

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/installer.sh"

echo "Testing install_hook_template..."

# Test git hook installation
if [ -d .git ]; then
    install_hook_template "pre-commit" "git"
    if [ -f ".git/hooks/pre-commit" ] && grep -q "CHP" ".git/hooks/pre-commit"; then
        echo "PASS: Git hook installed"
        uninstall_hook_template "pre-commit" "git"
    else
        echo "FAIL: Git hook not installed"
        exit 1
    fi
else
    echo "SKIP: Not in a git repository"
fi

# Test agent hook installation
install_hook_template "pre-tool" "agent"
if [ -d ".claude/hooks" ]; then
    echo "PASS: Agent hook directory created"
    uninstall_hook_template "pre-tool" "agent"
else
    echo "INFO: Agent hooks not configured"
fi

echo "All installer tests passed!"
```

- [ ] **Step 2: Run test to see current state**

```bash
bash tests/test-installer.sh
```

Expected: FAIL - New functions don't exist

- [ ] **Step 3: Update installer.sh with universal installation**

```bash
#!/bin/bash
# Install and uninstall hooks for laws (universal)

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detector.sh"

# Backup existing hook before overwriting
backup_existing_hook() {
    local hook_path="$1"
    local backup_path="${hook_path}.chp-backup-$(date +%s)"

    if [ -f "$hook_path" ] && ! grep -q "# CHP-MANAGED" "$hook_path"; then
        cp "$hook_path" "$backup_path"
        log_info "Backed up existing hook to $backup_path"
        echo "$backup_path"
    fi
}

# Install a hook template to its target location
install_hook_template() {
    local hook_type="$1"
    local hook_category="$2"

    case "$hook_category" in
        git)
            _install_git_hook "$hook_type"
            ;;
        agent)
            _install_agent_hook "$hook_type"
            ;;
        cicd)
            _install_cicd_hook "$hook_type"
            ;;
        *)
            log_error "Unknown hook category: $hook_category"
            return 1
            ;;
    esac
}

# Uninstall a hook template
uninstall_hook_template() {
    local hook_type="$1"
    local hook_category="$2"

    case "$hook_category" in
        git)
            _uninstall_git_hook "$hook_type"
            ;;
        agent)
            _uninstall_agent_hook "$hook_type"
            ;;
        cicd)
            _uninstall_cicd_hook "$hook_type"
            ;;
        *)
            log_error "Unknown hook category: $hook_category"
            return 1
            ;;
    esac
}

# Install git hook
_install_git_hook() {
    local hook_type="$1"

    if [ ! -d .git ]; then
        log_warn "Not in a git repository, skipping git hook installation"
        return 0
    fi

    local hook_file=".git/hooks/$hook_type"
    local template_file="$CHP_BASE/hooks/git/$hook_type.sh"

    if [ ! -f "$template_file" ]; then
        log_error "Hook template not found: $template_file"
        return 1
    fi

    # Backup existing hook
    backup_existing_hook "$hook_file"

    # Copy template
    cp "$template_file" "$hook_file"
    chmod +x "$hook_file"

    log_info "Installed git hook: $hook_type"
}

# Uninstall git hook
_uninstall_git_hook() {
    local hook_type="$1"
    local hook_file=".git/hooks/$hook_type"

    if [ -f "$hook_file" ] && grep -q "# CHP-MANAGED" "$hook_file"; then
        rm -f "$hook_file"
        log_info "Uninstalled git hook: $hook_type"

        # Check for backup
        local backup_file=$(ls "${hook_file}.chp-backup-"* 2>/dev/null | tail -1)
        if [ -n "$backup_file" ]; then
            mv "$backup_file" "$hook_file"
            chmod +x "$hook_file"
            log_info "Restored original hook from backup"
        fi
    fi
}

# Install agent hook
_install_agent_hook() {
    local hook_type="$1"

    local hook_dir=".claude/hooks"
    local hook_file="$hook_dir/${hook_type}.sh"
    local template_file="$CHP_BASE/hooks/agent/$hook_type.sh"

    if [ ! -f "$template_file" ]; then
        log_error "Hook template not found: $template_file"
        return 1
    fi

    # Create directory
    mkdir -p "$hook_dir"

    # Copy template
    cp "$template_file" "$hook_file"
    chmod +x "$hook_file"

    log_info "Installed agent hook: $hook_type"
}

# Uninstall agent hook
_uninstall_agent_hook() {
    local hook_type="$1"
    local hook_file=".claude/hooks/${hook_type}.sh"

    if [ -f "$hook_file" ] && grep -q "# CHP-MANAGED" "$hook_file"; then
        rm -f "$hook_file"
        log_info "Uninstalled agent hook: $hook_type"
    fi
}

# Install CI/CD hook
_install_cicd_hook() {
    local hook_type="$1"

    local hook_dir=".chp/cicd-hooks"
    local hook_file="$hook_dir/${hook_type}.sh"
    local template_file="$CHP_BASE/hooks/cicd/$hook_type.sh"

    if [ ! -f "$template_file" ]; then
        log_error "Hook template not found: $template_file"
        return 1
    fi

    # Create directory
    mkdir -p "$hook_dir"

    # Copy template
    cp "$template_file" "$hook_file"
    chmod +x "$hook_file"

    log_info "Installed CI/CD hook: $hook_type"
    log_warn "Add this to your CI/CD config: bash $hook_file"
}

# Uninstall CI/CD hook
_uninstall_cicd_hook() {
    local hook_type="$1"
    local hook_file=".chp/cicd-hooks/${hook_type}.sh"

    if [ -f "$hook_file" ]; then
        rm -f "$hook_file"
        log_info "Uninstalled CI/CD hook: $hook_type"
    fi
}

# Install all hooks for a law
install_law_hooks() {
    local law_name="$1"

    if ! law_exists "$law_name"; then
        log_error "Law '$law_name' does not exist"
        return 1
    fi

    local law_json="$LAWS_DIR/$law_name/law.json"
    local hooks=$(jq -r '.hooks[]? // empty' "$law_json" 2>/dev/null)

    if [ -z "$hooks" ]; then
        log_warn "No hooks specified for law '$law_name'"
        return 0
    fi

    while IFS= read -r hook_type; do
        if [ -z "$hook_type" ]; then
            continue
        fi

        local hook_category=$(get_hook_category "$hook_type")

        if [ "$hook_category" = "unknown" ]; then
            log_warn "Unknown hook type: $hook_type"
            continue
        fi

        install_hook_template "$hook_type" "$hook_category"
    done <<< "$hooks"
}

# Uninstall all hooks for a law
uninstall_law_hooks() {
    local law_name="$1"

    if ! law_exists "$law_name"; then
        log_error "Law '$law_name' does not exist"
        return 1
    fi

    local law_json="$LAWS_DIR/$law_name/law.json"
    local hooks=$(jq -r '.hooks[]? // empty' "$law_json" 2>/dev/null)

    while IFS= read -r hook_type; do
        if [ -z "$hook_type" ]; then
            continue
        fi

        local hook_category=$(get_hook_category "$hook_type")
        uninstall_hook_template "$hook_type" "$hook_category"
    done <<< "$hooks"
}

# Legacy: Install a law's verification script into a hook
install_hook() {
    local law_name="$1"
    local hook_type="$2"

    if ! law_exists "$law_name"; then
        log_error "Law '$law_name' does not exist"
        return 1
    fi

    local verify_script="$LAWS_DIR/$law_name/verify.sh"
    if [ ! -f "$verify_script" ]; then
        log_error "Verification script not found for '$law_name'"
        return 1
    fi

    case "$hook_type" in
        pre-commit|pre-push|pre-merge-commit)
            if [ -d .git ]; then
                local hook_file=".git/hooks/$hook_type"

                # Create or append to hook
                if [ -f "$hook_file" ]; then
                    if ! grep -q "# CHP-MANAGED" "$hook_file"; then
                        cp "$hook_file" "$hook_file.backup"
                        echo "# CHP-MANAGED" > "$hook_file"
                    fi
                else
                    echo "# CHP-MANAGED" > "$hook_file"
                    chmod +x "$hook_file"
                fi

                # Add law verification
                if ! grep -q "$law_name" "$hook_file"; then
                    echo "" >> "$hook_file"
                    echo "# Law: $law_name" >> "$hook_file"
                    echo "bash \"$verify_script\" || exit 1" >> "$hook_file"
                    log_info "Installed '$law_name' into $hook_type hook"
                fi
            fi
            ;;
        pre-write)
            if [ -d .pretool ]; then
                local pretool_hook=".pretool/hooks/$hook_type/$law_name.sh"
                mkdir -p "$(dirname "$pretool_hook")"
                cp "$verify_script" "$pretool_hook"
                chmod +x "$pretool_hook"
                log_info "Installed '$law_name' into pretool $hook_type hook"
            fi
            ;;
        *)
            log_warn "Unknown hook type: $hook_type"
            return 1
            ;;
    esac

    return 0
}

# Legacy: Uninstall a law's verification from a hook
uninstall_hook() {
    local law_name="$1"
    local hook_type="$2"

    case "$hook_type" in
        pre-commit|pre-push|pre-merge-commit)
            if [ -f ".git/hooks/$hook_type" ]; then
                sed -i.tmp "/# Law: $law_name/,/^bash/ d" ".git/hooks/$hook_type"
                rm -f ".git/hooks/$hook_type.tmp"
                log_info "Uninstalled '$law_name' from $hook_type hook"
            fi
            ;;
        pre-write)
            if [ -f ".pretool/hooks/$hook_type/$law_name.sh" ]; then
                rm -f ".pretool/hooks/$hook_type/$law_name.sh"
                log_info "Uninstalled '$law_name' from pretool $hook_type hook"
            fi
            ;;
    esac

    return 0
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-installer.sh
```

Expected: PASS - Hooks installed and uninstalled

- [ ] **Step 5: Commit**

```bash
git add core/installer.sh tests/test-installer.sh
git commit -m "feat: add universal hook installation support"
```

---

## Phase 2: Git Hook Templates

### Task 5: Create Git hook templates

**Files:**
- Create: `hooks/git/pre-commit.sh`
- Create: `hooks/git/post-commit.sh`
- Create: `hooks/git/pre-push.sh`
- Create: `hooks/git/post-merge.sh`
- Create: `hooks/git/commit-msg.sh`
- Create: `hooks/git/prepare-commit-msg.sh`
- Create: `hooks/git/pre-rebase.sh`
- Create: `hooks/git/post-checkout.sh`
- Create: `hooks/git/post-rewrite.sh`
- Create: `hooks/git/applypatch-msg.sh`
- Create: `hooks/git/pre-applypatch.sh`
- Create: `hooks/git/post-applypatch.sh`
- Create: `hooks/git/update.sh`
- Create: `hooks/git/pre-auto-gc.sh`

- [ ] **Step 1: Create pre-commit.sh template**

```bash
#!/bin/bash
# CHP Pre-Commit Hook
# Installed to .git/hooks/pre-commit
# Runs CHP law verification before allowing commit

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-commit "$@"

exit $?
```

- [ ] **Step 2: Create post-commit.sh template**

```bash
#!/bin/bash
# CHP Post-Commit Hook
# Installed to .git/hooks/post-commit
# Runs after commit completes (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-commit "$@"

# Always allow commit to succeed
exit 0
```

- [ ] **Step 3: Create pre-push.sh template**

```bash
#!/bin/bash
# CHP Pre-Push Hook
# Installed to .git/hooks/pre-push
# Runs CHP law verification before allowing push

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-push "$@"

exit $?
```

- [ ] **Step 4: Create post-merge.sh template**

```bash
#!/bin/bash
# CHP Post-Merge Hook
# Installed to .git/hooks/post-merge
# Runs after merge completes (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-merge "$@"

# Always allow merge to succeed
exit 0
```

- [ ] **Step 5: Create commit-msg.sh template**

```bash
#!/bin/bash
# CHP Commit-Msg Hook
# Installed to .git/hooks/commit-msg
# Validates commit message format

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" commit-msg "$1"

exit $?
```

- [ ] **Step 6: Create prepare-commit-msg.sh template**

```bash
#!/bin/bash
# CHP Prepare-Commit-Msg Hook
# Installed to .git/hooks/prepare-commit-msg
# Edits commit message before user sees it (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" prepare-commit-msg "$@"

# Always allow preparation to succeed
exit 0
```

- [ ] **Step 7: Create pre-rebase.sh template**

```bash
#!/bin/bash
# CHP Pre-Rebase Hook
# Installed to .git/hooks/pre-rebase
# Runs before rebase operation

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-rebase "$@"

exit $?
```

- [ ] **Step 8: Create post-checkout.sh template**

```bash
#!/bin/bash
# CHP Post-Checkout Hook
# Installed to .git/hooks/post-checkout
# Runs after checkout completes (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-checkout "$@"

# Always allow checkout to succeed
exit 0
```

- [ ] **Step 9: Create post-rewrite.sh template**

```bash
#!/bin/bash
# CHP Post-Rewrite Hook
# Installed to .git/hooks/post-rewrite
# Runs after rewrite operations (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-rewrite "$@"

# Always allow rewrite to succeed
exit 0
```

- [ ] **Step 10: Create applypatch-msg.sh template**

```bash
#!/bin/bash
# CHP Applypatch-Msg Hook
# Installed to .git/hooks/applypatch-msg
# Validates patch message format

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" applypatch-msg "$1"

exit $?
```

- [ ] **Step 11: Create pre-applypatch.sh template**

```bash
#!/bin/bash
# CHP Pre-Applypatch Hook
# Installed to .git/hooks/pre-applypatch
# Runs before applying a patch

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-applypatch "$@"

exit $?
```

- [ ] **Step 12: Create post-applypatch.sh template**

```bash
#!/bin/bash
# CHP Post-Applypatch Hook
# Installed to .git/hooks/post-applypatch
# Runs after applying a patch (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-applypatch "$@"

# Always allow patch apply to succeed
exit 0
```

- [ ] **Step 13: Create update.sh template**

```bash
#!/bin/bash
# CHP Update Hook
# Installed to .git/hooks/update (server-side)
# Runs before ref updates

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" update "$@"

exit $?
```

- [ ] **Step 14: Create pre-auto-gc.sh template**

```bash
#!/bin/bash
# CHP Pre-Auto-GC Hook
# Installed to .git/hooks/pre-auto-gc
# Runs before garbage collection (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-auto-gc "$@"

# Always allow gc to proceed
exit 0
```

- [ ] **Step 15: Make all templates executable and commit**

```bash
chmod +x hooks/git/*.sh
git add hooks/git/
git commit -m "feat: add git hook templates"
```

---

## Phase 3: AI/Agent Hook Templates

### Task 6: Create Agent hook templates

**Files:**
- Create: `hooks/agent/pre-prompt.sh`
- Create: `hooks/agent/post-prompt.sh`
- Create: `hooks/agent/pre-tool.sh`
- Create: `hooks/agent/post-tool.sh`
- Create: `hooks/agent/pre-response.sh`
- Create: `hooks/agent/post-response.sh`

- [ ] **Step 1: Create pre-prompt.sh template**

```bash
#!/bin/bash
# CHP Pre-Prompt Hook
# Installed to .claude/hooks/pre-prompt.sh
# Runs before user prompt is processed (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-prompt "$@"

# Always allow prompt to proceed
exit 0
```

- [ ] **Step 2: Create post-prompt.sh template**

```bash
#!/bin/bash
# CHP Post-Prompt Hook
# Installed to .claude/hooks/post-prompt.sh
# Runs after user prompt is processed (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-prompt "$@"

# Always allow continuation
exit 0
```

- [ ] **Step 3: Create pre-tool.sh template**

```bash
#!/bin/bash
# CHP Pre-Tool Hook
# Installed to .claude/hooks/pre-tool.sh
# Runs before tool execution (can block)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-tool "$@"

exit $?
```

- [ ] **Step 4: Create post-tool.sh template**

```bash
#!/bin/bash
# CHP Post-Tool Hook
# Installed to .claude/hooks/post-tool.sh
# Runs after tool execution (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-tool "$@"

# Always allow continuation
exit 0
```

- [ ] **Step 5: Create pre-response.sh template**

```bash
#!/bin/bash
# CHP Pre-Response Hook
# Installed to .claude/hooks/pre-response.sh
# Runs before agent response (can trigger regeneration)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-response "$@"

exit $?
```

- [ ] **Step 6: Create post-response.sh template**

```bash
#!/bin/bash
# CHP Post-Response Hook
# Installed to .claude/hooks/post-response.sh
# Runs after agent response (non-blocking)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-response "$@"

# Always allow continuation
exit 0
```

- [ ] **Step 7: Make all templates executable and commit**

```bash
chmod +x hooks/agent/*.sh
git add hooks/agent/
git commit -m "feat: add AI/agent hook templates"
```

---

## Phase 4: CI/CD Hook Templates

### Task 7: Create CI/CD hook templates

**Files:**
- Create: `hooks/cicd/pre-build.sh`
- Create: `hooks/cicd/post-build.sh`
- Create: `hooks/cicd/pre-deploy.sh`
- Create: `hooks/cicd/post-deploy.sh`

- [ ] **Step 1: Create pre-build.sh template**

```bash
#!/bin/bash
# CHP Pre-Build Hook
# Installed to .chp/cicd-hooks/pre-build.sh
# Runs before build starts (can block)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-build "$@"

exit $?
```

- [ ] **Step 2: Create post-build.sh template**

```bash
#!/bin/bash
# CHP Post-Build Hook
# Installed to .chp/cicd-hooks/post-build.sh
# Runs after build completes (can fail pipeline)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-build "$@"

exit $?
```

- [ ] **Step 3: Create pre-deploy.sh template**

```bash
#!/bin/bash
# CHP Pre-Deploy Hook
# Installed to .chp/cicd-hooks/pre-deploy.sh
# Runs before deployment (can block)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" pre-deploy "$@"

exit $?
```

- [ ] **Step 4: Create post-deploy.sh template**

```bash
#!/bin/bash
# CHP Post-Deploy Hook
# Installed to .chp/cicd-hooks/post-deploy.sh
# Runs after deployment (can trigger rollback)

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/dispatcher.sh" post-deploy "$@"

exit $?
```

- [ ] **Step 5: Make all templates executable and commit**

```bash
chmod +x hooks/cicd/*.sh
git add hooks/cicd/
git commit -m "feat: add CI/CD hook templates"
```

---

## Phase 5: CLI and Integration

### Task 8: Create chp-hooks command

**Files:**
- Create: `commands/chp-hooks`

- [ ] **Step 1: Create chp-hooks command**

```bash
#!/bin/bash
# CHP Hooks Management CLI

set -e

# Source core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/hook-registry.sh"
source "$SCRIPT_DIR/../core/detector.sh"
source "$SCRIPT_DIR/../core/installer.sh"

# Show usage
show_usage() {
    cat <<EOF
CHP Hooks Management

Usage:
  chp-hooks list                          List all hooks and their status
  chp-hooks enable <hook-type>            Enable a hook type
  chp-hooks disable <hook-type>           Disable a hook type
  chp-hooks blocking <hook-type> [true]   Set blocking behavior
  chp-hooks install <hook-type>           Install hook template
  chp-hooks uninstall <hook-type>         Uninstall hook template
  chp-hooks detect                        Detect available hook types
  chp-hooks registry                      Show hook registry

Examples:
  chp-hooks list
  chp-hooks enable pre-commit
  chp-hooks blocking pre-commit false
  chp-hooks install pre-commit

EOF
}

# List all hooks with their status
list_hooks_cmd() {
    echo "CHP Hooks Status"
    echo "================"
    echo ""

    # Get all available hooks
    local all_hooks=$(detect_all_hooks)

    if [ -z "$all_hooks" ]; then
        log_info "No hooks detected in this environment"
        return
    fi

    printf "%-20s %-10s %-10s %-10s\n" "Hook Type" "Enabled" "Blocking" "Laws"
    echo "------------------------------------------------------------"

    for hook_type in $all_hooks; do
        local enabled=$(is_hook_enabled "$hook_type" && echo "yes" || echo "no")
        local blocking=$(is_hook_blocking "$hook_type" && echo "yes" || echo "no")
        local law_count=$(get_hook_laws "$hook_type" | wc -l)

        printf "%-20s %-10s %-10s %-10s\n" "$hook_type" "$enabled" "$blocking" "$law_count"
    done
}

# Enable a hook
enable_hook() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type required"
        exit 1
    fi

    set_hook_enabled "$hook_type" "true"
    log_info "Enabled hook: $hook_type"
}

# Disable a hook
disable_hook() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type required"
        exit 1
    fi

    set_hook_enabled "$hook_type" "false"
    log_info "Disabled hook: $hook_type"
}

# Set blocking behavior
set_blocking() {
    local hook_type="$1"
    local blocking="${2:-true}"

    if [ -z "$hook_type" ]; then
        log_error "Hook type required"
        exit 1
    fi

    set_hook_blocking "$hook_type" "$blocking"
    log_info "Set hook '$hook_type' blocking to: $blocking"
}

# Install hook template
install_hook_cmd() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type required"
        exit 1
    fi

    local hook_category=$(get_hook_category "$hook_type")

    if [ "$hook_category" = "unknown" ]; then
        log_error "Unknown hook type: $hook_type"
        exit 1
    fi

    install_hook_template "$hook_type" "$hook_category"
}

# Uninstall hook template
uninstall_hook_cmd() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type required"
        exit 1
    fi

    local hook_category=$(get_hook_category "$hook_type")
    uninstall_hook_template "$hook_type" "$hook_category"
}

# Detect available hooks
detect_cmd() {
    echo "Detected Hook Types"
    echo "==================="
    echo ""

    echo "Git hooks:"
    local git_hooks=$(detect_all_git_hooks)
    if [ -n "$git_hooks" ]; then
        echo "  $git_hooks"
    else
        echo "  (none - not a git repository)"
    fi

    echo ""
    echo "Agent hooks:"
    local agent_hooks=$(detect_all_agent_hooks)
    if [ -n "$agent_hooks" ]; then
        echo "  $agent_hooks"
    else
        echo "  (none - no agent system detected)"
    fi

    echo ""
    echo "CI/CD hooks:"
    local cicd_hooks=$(detect_all_cicd_hooks)
    if [ -n "$cicd_hooks" ]; then
        echo "  $cicd_hooks"
    else
        echo "  (none - no CI/CD config detected)"
    fi
}

# Show registry
show_registry() {
    init_hook_registry
    cat "$HOOK_REGISTRY_FILE"
}

# Main
case "${1:-}" in
    list)
        list_hooks_cmd
        ;;
    enable)
        if [ -z "${2:-}" ]; then
            log_error "Hook type required"
            show_usage
            exit 1
        fi
        enable_hook "$2"
        ;;
    disable)
        if [ -z "${2:-}" ]; then
            log_error "Hook type required"
            show_usage
            exit 1
        fi
        disable_hook "$2"
        ;;
    blocking)
        if [ -z "${2:-}" ]; then
            log_error "Hook type required"
            show_usage
            exit 1
        fi
        set_blocking "$2" "${3:-true}"
        ;;
    install)
        if [ -z "${2:-}" ]; then
            log_error "Hook type required"
            show_usage
            exit 1
        fi
        install_hook_cmd "$2"
        ;;
    uninstall)
        if [ -z "${2:-}" ]; then
            log_error "Hook type required"
            show_usage
            exit 1
        fi
        uninstall_hook_cmd "$2"
        ;;
    detect)
        detect_cmd
        ;;
    registry)
        show_registry
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x commands/chp-hooks
./commands/chp-hooks
```

Expected: Shows usage information

- [ ] **Step 3: Commit**

```bash
git add commands/chp-hooks
git commit -m "feat: add chp-hooks management command"
```

---

### Task 9: Update chp-law command for hooks

**Files:**
- Modify: `commands/chp-law`

- [ ] **Step 1: Update chp-law to register hooks in registry**

Add to the `create_law()` function in `commands/chp-law` after creating law.json:

```bash
    # Register law in hook registry
    source "$SCRIPT_DIR/../core/hook-registry.sh"
    init_hook_registry

    IFS=',' read -ra hook_array <<< "$hooks"
    for hook in "${hook_array[@]}"; do
        hook=$(echo "$hook" | xargs)  # trim whitespace
        register_hook_law "$hook" "$law_name"
    done

    log_info "Registered '$law_name' with hooks: $hooks"
```

- [ ] **Step 2: Update delete_law() to unregister hooks**

Add to the `delete_law()` function before removing files:

```bash
    # Unregister from hook registry
    source "$SCRIPT_DIR/../core/hook-registry.sh"

    for hook in $hooks; do
        unregister_hook_law "$hook" "$law_name"
    done
```

- [ ] **Step 3: Commit**

```bash
git add commands/chp-law
git commit -m "feat: integrate chp-law with hook registry"
```

---

### Task 10: Update chp-status command

**Files:**
- Modify: `commands/chp-status`

- [ ] **Step 1: Add hook registry status to chp-status**

Add after the "Installed Hooks" section:

```bash
echo ""
echo "🔗 Hook Registry:"
if [ -f "$CHP_BASE/.chp/hook-registry.json" ]; then
    local hook_count=$(jq '.hooks | length' "$CHP_BASE/.chp/hook-registry.json")
    echo "   $hook_count hook types registered"
    echo ""
    echo "   Registered mappings:"
    jq -r '.hooks | to_entries[] | "   \(.key): \(.value.laws | length) law(s)"' "$CHP_BASE/.chp/hook-registry.json"
else
    echo "   No hook registry found"
fi
```

- [ ] **Step 2: Commit**

```bash
git add commands/chp-status
git commit -m "feat: add hook registry status to chp-status"
```

---

### Task 11: Create Claude Code integration

**Files:**
- Create: `.claude/hooks/README.md`

- [ ] **Step 1: Create Claude Code hooks documentation**

```bash
# CHP Claude Code Hook Integration

This directory contains CHP hooks for Claude Code.

## Setup

Add to your `.claude/settings.json`:

```json
{
  "hooks": {
    "pre-tool": {
      "enabled": true,
      "command": "bash /path/to/chp/.claude/hooks/pre-tool.sh"
    },
    "post-tool": {
      "enabled": true,
      "command": "bash /path/to/chp/.claude/hooks/post-tool.sh"
    }
  }
}
```

## Available Hooks

- `pre-prompt.sh` - Runs before user prompt
- `post-prompt.sh` - Runs after user prompt
- `pre-tool.sh` - Runs before tool execution (can block)
- `post-tool.sh` - Runs after tool execution
- `pre-response.sh` - Runs before agent response
- `post-response.sh` - Runs after agent response

## Installation

Run `chp-hooks install pre-tool` to install hooks to this directory.
```

- [ ] **Step 2: Create installation helper script**

```bash
#!/bin/bash
# Install CHP hooks to .claude/hooks directory

CHP_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR=".claude/hooks"

mkdir -p "$HOOKS_DIR"

# Copy agent hooks
for hook in pre-prompt post-prompt pre-tool post-tool pre-response post-response; do
    if [ -f "$CHP_BASE/hooks/agent/$hook.sh" ]; then
        cp "$CHP_BASE/hooks/agent/$hook.sh" "$HOOKS_DIR/"
        chmod +x "$HOOKS_DIR/$hook.sh"
        echo "Installed: $hook"
    fi
done

echo ""
echo "CHP hooks installed to $HOOKS_DIR"
echo "Add hook configuration to .claude/settings.json"
```

- [ ] **Step 3: Commit**

```bash
git add .claude/hooks/
git commit -m "feat: add Claude Code hook integration"
```

---

### Task 12: Create comprehensive documentation

**Files:**
- Create: `docs/chp/HOOKS.md`

- [ ] **Step 1: Create HOOKS documentation**

```markdown
# CHP Universal Hook System

Complete guide to using CHP hooks across Git, AI agents, and CI/CD.

## Overview

The CHP Universal Hook System provides a single interface for enforcing laws across all development operations:

- **Git Hooks** - 15 hook types for Git operations
- **AI/Agent Hooks** - 6 hook types for Claude Code, Copilot CLI, etc.
- **CI/CD Hooks** - 4 hook types for build/deploy pipelines

## Quick Start

```bash
# List available hooks
./commands/chp-hooks detect

# List registered hooks
./commands/chp-hooks list

# Enable a hook
./commands/chp-hooks enable pre-commit

# Install hook templates
./commands/chp-hooks install pre-commit
```

## Hook Types

### Git Hooks

| Hook | Trigger | Blocking | Use Case |
|------|---------|----------|----------|
| `pre-commit` | Before commit | Yes | Code quality checks |
| `post-commit` | After commit | No | Notifications, metrics |
| `pre-push` | Before push | Yes | Full validation |
| `post-merge` | After merge | No | Dependency updates |
| `commit-msg` | After message edit | Yes | Message validation |
| `prepare-commit-msg` | Before message edit | No | Template injection |
| `pre-rebase` | Before rebase | Yes | Branch protection |
| `post-checkout` | After checkout | No | Environment setup |
| `post-rewrite` | After rewrite | No | History tracking |
| `applypatch-msg` | After patch message | Yes | Patch validation |
| `pre-applypatch` | Before patch apply | Yes | Pre-flight checks |
| `post-applypatch` | After patch apply | No | Integration tasks |
| `update` | Before ref update | Yes | Access control |
| `pre-auto-gc` | Before GC | No | Cleanup preparation |

### AI/Agent Hooks

| Hook | Trigger | Blocking | Use Case |
|------|---------|----------|----------|
| `pre-prompt` | Before prompt | No | Context injection |
| `post-prompt` | After prompt | No | Intent analysis |
| `pre-tool` | Before tool | Yes | Parameter validation |
| `post-tool` | After tool | No | Result validation |
| `pre-response` | Before response | Yes | Response validation |
| `post-response` | After response | No | Quality metrics |

### CI/CD Hooks

| Hook | Trigger | Blocking | Use Case |
|------|---------|----------|----------|
| `pre-build` | Before build | Yes | Dependency checks |
| `post-build` | After build | Yes | Artifact validation |
| `pre-deploy` | Before deploy | Yes | Deployment verification |
| `post-deploy` | After deploy | Yes | Health checks |

## Creating Laws for Hooks

When creating a law, specify which hooks it should use:

```bash
./commands/chp-law create no-secrets --hooks=pre-commit,pre-push,pre-tool
```

This creates a law that runs on:
- Before each commit
- Before each push
- Before each AI tool execution

## Managing Hooks

### List Hooks

```bash
./commands/chp-hooks list
```

Output:
```
CHP Hooks Status
================

Hook Type           Enabled    Blocking   Laws
------------------------------------------------------------
pre-commit          yes        yes        2
pre-push            yes        yes        2
post-commit         yes        no         1
```

### Enable/Disable Hooks

```bash
# Disable a hook
./commands/chp-hooks disable pre-commit

# Re-enable it
./commands/chp-hooks enable pre-commit
```

### Set Blocking Behavior

```bash
# Make hook non-blocking
./commands/chp-hooks blocking pre-commit false

# Make hook blocking
./commands/chp-hooks blocking pre-commit true
```

### Install Hook Templates

```bash
# Install git hook
./commands/chp-hooks install pre-commit

# Install agent hook
./commands/chp-hooks install pre-tool

# Uninstall
./commands/chp-hooks uninstall pre-commit
```

## Claude Code Integration

1. Install hooks to `.claude/hooks`:

```bash
bash .claude/hooks/install.sh
```

2. Add to `.claude/settings.json`:

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
    }
  }
}
```

## CI/CD Integration

### GitHub Actions

```yaml
name: CHP Check
on: [push, pull_request]

jobs:
  chp:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: CHP Pre-Build Check
        run: bash .chp/cicd-hooks/pre-build.sh
      - name: CHP Post-Build Check
        run: bash .chp/cicd-hooks/post-build.sh
```

### GitLab CI

```yaml
chp-check:
  script:
    - bash .chp/cicd-hooks/pre-build.sh
    - npm run build
    - bash .chp/cicd-hooks/post-build.sh
```

## Troubleshooting

### Hook Not Running

1. Check if hook is enabled:
   ```bash
   ./commands/chp-hooks list
   ```

2. Check if hook is installed:
   ```bash
   ls -la .git/hooks/  # for git hooks
   ls -la .claude/hooks/  # for agent hooks
   ```

3. Enable debug mode:
   ```bash
   CHP_DEBUG=true ./commands/chp-hooks list
   ```

### Law Not Running on Hook

1. Check if law is registered:
   ```bash
   ./commands/chp-hooks registry
   ```

2. Verify law has the hook in its `law.json`:
   ```bash
   cat docs/chp/laws/<law-name>/law.json | jq '.hooks'
   ```

3. Re-register the law:
   ```bash
   ./commands/chp-law delete <law-name>
   ./commands/chp-law create <law-name> --hooks=<hooks>
   ```

## Architecture

The hook system uses a central dispatcher:

```
User Action
    ↓
Hook Triggered
    ↓
Dispatcher (dispatcher.sh)
    ↓
Hook Registry Lookup
    ↓
Execute Each Law's verify.sh
    ↓
Aggregate Results
    ↓
Apply Blocking Rules
    ↓
Exit Code
```

## Best Practices

1. **Use blocking hooks sparingly** - Only block on critical failures
2. **Post-* hooks for notifications** - Use post-commit, post-response for alerts
3. **Pre-* hooks for validation** - Use pre-commit, pre-tool for quality checks
4. **Non-blocking for metrics** - Don't block on data collection
5. **Test hooks locally** - Use `chp-law test` before committing

## Examples

See example laws in `docs/chp/laws/`:

- `no-console-log` - Git pre-commit hook
- `no-api-keys` - Git pre-commit + pre-push hooks

Create your own with `./commands/chp-law create`.
```

- [ ] **Step 2: Commit**

```bash
git add docs/chp/HOOKS.md
git commit -m "docs: add comprehensive hook system documentation"
```

---

## Phase 6: Testing and Validation

### Task 13: Create comprehensive hook tests

**Files:**
- Create: `tests/test-hook-templates.sh`

- [ ] **Step 1: Write hook template tests**

```bash
#!/bin/bash
# Test hook templates

source "$(dirname "$0")/../core/common.sh"

echo "Testing Hook Templates"
echo "====================="
echo ""

# Test git hook templates
echo "Testing git hook templates..."
for hook in pre-commit post-commit pre-push post-merge commit-msg prepare-commit-msg pre-rebase post-checkout post-rewrite applypatch-msg pre-applypatch post-applypatch update pre-auto-gc; do
    template="$CHP_BASE/hooks/git/$hook.sh"
    if [ -f "$template" ]; then
        if grep -q "CHP-MANAGED" "$template" && grep -q "dispatcher.sh" "$template"; then
            echo "  ✓ $hook"
        else
            echo "  ✗ $hook (missing CHP markers)"
            exit 1
        fi
    else
        echo "  ✗ $hook (not found)"
        exit 1
    fi
done

# Test agent hook templates
echo ""
echo "Testing agent hook templates..."
for hook in pre-prompt post-prompt pre-tool post-tool pre-response post-response; do
    template="$CHP_BASE/hooks/agent/$hook.sh"
    if [ -f "$template" ]; then
        if grep -q "CHP-MANAGED" "$template" && grep -q "dispatcher.sh" "$template"; then
            echo "  ✓ $hook"
        else
            echo "  ✗ $hook (missing CHP markers)"
            exit 1
        fi
    else
        echo "  ✗ $hook (not found)"
        exit 1
    fi
done

# Test CI/CD hook templates
echo ""
echo "Testing CI/CD hook templates..."
for hook in pre-build post-build pre-deploy post-deploy; do
    template="$CHP_BASE/hooks/cicd/$hook.sh"
    if [ -f "$template" ]; then
        if grep -q "CHP-MANAGED" "$template" && grep -q "dispatcher.sh" "$template"; then
            echo "  ✓ $hook"
        else
            echo "  ✗ $hook (missing CHP markers)"
            exit 1
        fi
    else
        echo "  ✗ $hook (not found)"
        exit 1
    fi
done

echo ""
echo "All hook template tests passed!"
```

- [ ] **Step 2: Run tests**

```bash
bash tests/test-hook-templates.sh
```

Expected: PASS - All templates verified

- [ ] **Step 3: Commit**

```bash
git add tests/test-hook-templates.sh
git commit -m "test: add hook template validation tests"
```

---

### Task 14: End-to-end integration test

**Files:**
- Create: `tests/test-e2e-hooks.sh`

- [ ] **Step 1: Create end-to-end test**

```bash
#!/bin/bash
# End-to-end hook system test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "CHP Universal Hook System - End-to-End Test"
echo "==========================================="
echo ""

# Setup
export CHP_DEBUG=true

echo "1. Testing hook registry..."
./core/hook-registry.sh init
if [ -f ".chp/hook-registry.json" ]; then
    echo "   ✓ Registry initialized"
else
    echo "   ✗ Registry initialization failed"
    exit 1
fi

echo ""
echo "2. Testing hook detection..."
./core/detector.sh all > /dev/null
echo "   ✓ Hooks detected"

echo ""
echo "3. Creating test law..."
./commands/chp-law create e2e-test-law --hooks=pre-commit > /dev/null
if [ -d "docs/chp/laws/e2e-test-law" ]; then
    echo "   ✓ Test law created"
else
    echo "   ✗ Law creation failed"
    exit 1
fi

echo ""
echo "4. Testing hook registration..."
if ./commands/chp-hooks registry | grep -q "pre-commit"; then
    echo "   ✓ Hook registered"
else
    echo "   ✗ Hook registration failed"
    exit 1
fi

echo ""
echo "5. Testing chp-hooks list..."
./commands/chp-hooks list > /dev/null
echo "   ✓ Hook list works"

echo ""
echo "6. Testing chp-status..."
./commands/chp-status > /dev/null
echo "   ✓ Status command works"

echo ""
echo "7. Cleanup..."
./commands/chp-law delete e2e-test-law > /dev/null
if [ ! -d "docs/chp/laws/e2e-test-law" ]; then
    echo "   ✓ Test law deleted"
else
    echo "   ✗ Law deletion failed"
    exit 1
fi

echo ""
echo "==========================================="
echo "All end-to-end tests passed!"
echo "==========================================="
```

- [ ] **Step 2: Run end-to-end test**

```bash
bash tests/test-e2e-hooks.sh
```

Expected: PASS - All integration tests pass

- [ ] **Step 3: Commit**

```bash
git add tests/test-e2e-hooks.sh
git commit -m "test: add end-to-end hook system tests"
```

---

### Task 15: Create example law for post-commit hook

**Files:**
- Create: `docs/chp/laws/commit-metrics/`

- [ ] **Step 1: Create commit-metrics law**

```bash
./commands/chp-law create commit-metrics --hooks=post-commit
```

- [ ] **Step 2: Edit verify.sh for commit-metrics**

```bash
cat > docs/chp/laws/commit-metrics/verify.sh <<'EOF'
#!/bin/bash
# Collect commit metrics

METRICS_FILE="$CHP_BASE/.chp/commit-metrics.json"

# Initialize metrics file
if [ ! -f "$METRICS_FILE" ]; then
    echo '{"commits": 0, "files_changed": 0}' > "$METRICS_FILE"
fi

# Increment commit count
jq '.commits += 1' "$METRICS_FILE" > "${METRICS_FILE}.tmp"
mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

# Count changed files
changed_files=$(git diff --name-only HEAD~1 HEAD | wc -l)
jq --arg cf "$changed_files" '.files_changed += ($cf | tonumber)' "$METRICS_FILE" > "${METRICS_FILE}.tmp"
mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

echo "📊 Commit metrics updated"
echo "   Total commits: $(jq -r '.commits' "$METRICS_FILE")"
echo "   Files changed: $(jq -r '.files_changed' "$METRICS_FILE")"

exit 0
EOF
chmod +x docs/chp/laws/commit-metrics/verify.sh
```

- [ ] **Step 3: Edit guidance for commit-metrics**

```bash
cat > docs/chp/commit-metrics.md <<'EOF'
# Law: Commit Metrics

**Severity:** Info
**Action:** Non-blocking metrics collection

## What this means

This law tracks commit metrics to provide insights into development activity.

## Data Collected

- Total number of commits
- Total files changed across commits

## Location

Metrics stored in: `.chp/commit-metrics.json`

## Viewing Metrics

```bash
cat .chp/commit-metrics.json
```

## Disabling

To disable metrics collection:

```bash
./commands/chp-hooks disable post-commit
```
EOF
```

- [ ] **Step 4: Test the law**

```bash
./commands/chp-law test commit-metrics
```

Expected: PASS - Metrics file created and updated

- [ ] **Step 5: Commit**

```bash
git add docs/chp/
git commit -m "feat: add commit-metrics example law for post-commit hook"
```

---

## Phase 7: Final Polish

### Task 16: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add universal hook system section to README**

```bash
cat >> README.md <<'EOF'

## Universal Hook System

CHP now supports 25+ hook types across Git, AI/Agent, and CI/CD operations:

### Quick Start

```bash
# Detect available hooks
./commands/chp-hooks detect

# Create a law for multiple hook types
./commands/chp-law create no-secrets --hooks=pre-commit,pre-push,pre-tool

# Manage hooks
./commands/chp-hooks list
./commands/chp-hooks enable pre-commit
./commands/chp-hooks install pre-commit
```

### Hook Types

- **Git Hooks (15):** pre-commit, post-commit, pre-push, post-merge, commit-msg, prepare-commit-msg, pre-rebase, post-checkout, post-rewrite, applypatch-msg, pre-applypatch, post-applypatch, update, pre-auto-gc
- **AI/Agent Hooks (6):** pre-prompt, post-prompt, pre-tool, post-tool, pre-response, post-response
- **CI/CD Hooks (4):** pre-build, post-build, pre-deploy, post-deploy

### Documentation

See [docs/chp/HOOKS.md](docs/chp/HOOKS.md) for complete hook system documentation.
EOF
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add universal hook system to README"
```

---

### Task 17: Final validation and smoke test

**Files:**
- No files created - validation only

- [ ] **Step 1: Run all tests**

```bash
echo "Running all CHP tests..."
echo ""

echo "1. Hook registry tests..."
bash tests/test-hook-registry.sh

echo ""
echo "2. Dispatcher tests..."
bash tests/test-dispatcher.sh

echo ""
echo "3. Detector tests..."
bash tests/test-detector.sh

echo ""
echo "4. Installer tests..."
bash tests/test-installer.sh

echo ""
echo "5. Hook template tests..."
bash tests/test-hook-templates.sh

echo ""
echo "6. End-to-end tests..."
bash tests/test-e2e-hooks.sh

echo ""
echo "==========================================="
echo "All tests completed successfully!"
echo "==========================================="
```

Expected: All tests pass

- [ ] **Step 2: Verify hook installation**

```bash
./commands/chp-hooks detect
./commands/chp-hooks list
```

Expected: Shows detected and registered hooks

- [ ] **Step 3: Create a test law and verify hook registration**

```bash
./commands/chp-law create verify-hooks --hooks=pre-commit,post-commit,pre-tool
./commands/chp-hooks registry | grep verify-hooks
./commands/chp-law delete verify-hooks
```

Expected: Law created, registered, and deleted successfully

- [ ] **Step 4: Final commit**

```bash
git add .
git commit -m "feat: complete CHP universal hook system implementation"
```

---

## Final Review Checklist

- [ ] All core components implemented (registry, dispatcher, detector, installer)
- [ ] All 15 git hook templates created
- [ ] All 6 agent hook templates created
- [ ] All 4 CI/CD hook templates created
- [ ] chp-hooks command working
- [ ] chp-law integrated with hook registry
- [ ] chp-status shows hook registry
- [ ] Claude Code integration documented
- [ ] Comprehensive documentation in docs/chp/HOOKS.md
- [ ] All tests passing
- [ ] Example laws created for different hook types
- [ ] README updated

## Migration Guide for Existing Installations

For existing CHP installations:

1. Pull latest changes
2. Run `./core/hook-registry.sh init`
3. Re-create existing laws to register them in the new system
4. Install hook templates with `./commands/chp-hooks install <hook-type>`

The system is backwards compatible - existing laws continue to work without modification.
