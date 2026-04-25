# CHP Law Enforcement System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a two-layer law enforcement system with suggestive context and programmatic verification that auto-tightens guidance on violations.

**Architecture:** Bash-based CLI and core components, with a skill for agent guidance. Laws stored as JSON metadata + verification scripts + markdown context. Hook detection and installation for git/pretool. Verification runs on operations, failures trigger tightening.

**Tech Stack:** Bash scripts, JSON, Markdown, Git hooks

---

## File Structure

```
chp/
├── commands/
│   ├── chp-law            # Law management CLI
│   └── chp-status         # Status display
├── skills/
│   └── write-laws/
│       └── skill.md       # chp:write-laws skill
├── core/
│   ├── common.sh          # Shared functions
│   ├── detector.sh        # Hook detection
│   ├── installer.sh       # Hook installation
│   ├── verifier.sh        # Verification runner
│   └── tightener.sh       # Guidance strengthening
├── tests/
│   ├── test-detector.sh
│   ├── test-installer.sh
│   ├── test-verifier.sh
│   └── test-tightener.sh
└── docs/
    └── chp/
        ├── laws/          # Law definitions (created at runtime)
        └── .gitkeep
```

---

### Task 1: Create directory structure

**Files:**
- Create: `commands/`, `skills/write-laws/`, `core/`, `tests/`, `docs/chp/laws/`

- [ ] **Step 1: Create all directories**

```bash
mkdir -p commands skills/write-laws core tests docs/chp/laws
touch docs/chp/laws/.gitkeep
```

- [ ] **Step 2: Make scripts executable**

```bash
chmod +x commands/ core/ tests/
```

- [ ] **Step 3: Commit**

```bash
git add commands/ skills/ core/ tests/ docs/chp/
git commit -m "chore: create directory structure for law enforcement system"
```

---

### Task 2: Implement common.sh - shared utilities

**Files:**
- Create: `core/common.sh`

- [ ] **Step 1: Write common.sh with utility functions**

```bash
#!/bin/bash
# Shared utilities for CHP law enforcement

# CHP base directory
CHP_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAWS_DIR="$CHP_BASE/docs/chp/laws"
GUIDANCE_DIR="$CHP_BASE/docs/chp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if a law exists
law_exists() {
    local law_name="$1"
    [ -d "$LAWS_DIR/$law_name" ]
}

# Get law metadata
get_law_meta() {
    local law_name="$1"
    local field="$2"
    if [ -f "$LAWS_DIR/$law_name/law.json" ]; then
        jq -r ".$field // empty" "$LAWS_DIR/$law_name/law.json"
    fi
}

# List all laws
list_laws() {
    for law_dir in "$LAWS_DIR"/*; do
        if [ -d "$law_dir" ]; then
            local name=$(basename "$law_dir")
            local severity=$(get_law_meta "$name" "severity")
            local failures=$(get_law_meta "$name" "failures")
            echo "$name | severity: $severity | failures: $failures"
        fi
    done
}
```

- [ ] **Step 2: Source and verify common.sh loads**

```bash
source core/common.sh
log_info "common.sh loaded successfully"
```

Expected: `[INFO] common.sh loaded successfully`

- [ ] **Step 3: Commit**

```bash
git add core/common.sh
git commit -m "feat: add shared utility functions in common.sh"
```

---

### Task 3: Implement detector.sh - hook detection

**Files:**
- Create: `core/detector.sh`
- Create: `tests/test-detector.sh`

- [ ] **Step 1: Write failing test for detector.sh**

```bash
#!/bin/bash
# Test hook detection

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/detector.sh"

# Test git hook detection
echo "Testing git hook detection..."
if [ -d .git ]; then
    echo "PASS: .git directory detected"
else
    echo "SKIP: Not in a git repository"
fi

# Test for pretool detection
echo "Testing pretool hook detection..."
if command -v pretool &> /dev/null; then
    echo "INFO: pretool is available"
else
    echo "INFO: pretool not found"
fi

# Test detect_available_hooks function
echo "Testing detect_available_hooks..."
hooks=$(detect_available_hooks)
echo "Available hooks: $hooks"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-detector.sh
```

Expected: FAIL with `detect_available_hooks: command not found`

- [ ] **Step 3: Write detector.sh implementation**

```bash
#!/bin/bash
# Detect available hook systems

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Detect git hooks
detect_git_hooks() {
    if [ -d .git ]; then
        echo "pre-commit pre-push pre-merge-commit"
    fi
}

# Detect pretool hooks
detect_pretool_hooks() {
    if [ -f .pretool ] || [ -d .pretool ]; then
        echo "pre-write pre-commit pre-push"
    fi
}

# Detect all available hooks
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

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    detect_available_hooks
fi
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-detector.sh
```

Expected: PASS - shows available hooks

- [ ] **Step 5: Commit**

```bash
git add core/detector.sh tests/test-detector.sh
git commit -m "feat: add hook detection in detector.sh"
```

---

### Task 4: Implement installer.sh - hook installation

**Files:**
- Create: `core/installer.sh`
- Create: `tests/test-installer.sh`

- [ ] **Step 1: Write failing test for installer.sh**

```bash
#!/bin/bash
# Test hook installation

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/installer.sh"

# Test: install_hook for a law
echo "Testing install_hook..."
# This should fail initially
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-installer.sh
```

Expected: FAIL with function not found

- [ ] **Step 3: Write installer.sh implementation**

```bash
#!/bin/bash
# Install and uninstall hooks for laws

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Install a law's verification script into a hook
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
                    # Check if CHP already manages this hook
                    if ! grep -q "# CHP-MANAGED" "$hook_file"; then
                        # Backup existing hook
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
                # Pretool hook installation
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

# Uninstall a law's verification from a hook
uninstall_hook() {
    local law_name="$1"
    local hook_type="$2"
    
    case "$hook_type" in
        pre-commit|pre-push|pre-merge-commit)
            if [ -f ".git/hooks/$hook_type" ]; then
                # Remove the law's section from the hook
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

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add core/installer.sh tests/test-installer.sh
git commit -m "feat: add hook installation in installer.sh"
```

---

### Task 5: Implement verifier.sh - verification runner

**Files:**
- Create: `core/verifier.sh`
- Create: `tests/test-verifier.sh`

- [ ] **Step 1: Write failing test**

```bash
#!/bin/bash
# Test verification runner

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/verifier.sh"

echo "Testing verify_law function..."
# Should fail initially
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-verifier.sh
```

Expected: FAIL

- [ ] **Step 3: Write verifier.sh implementation**

```bash
#!/bin/bash
# Run verification for a law or all laws

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Verify a single law
verify_law() {
    local law_name="$1"
    
    if ! law_exists "$law_name"; then
        log_error "Law '$law_name' does not exist"
        return 1
    fi
    
    local verify_script="$LAWS_DIR/$law_name/verify.sh"
    if [ ! -f "$verify_script" ]; then
        log_error "Verification script not found for '$law_name'"
        return 1
    fi
    
    # Run the verification script
    bash "$verify_script"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        return 0
    else
        # Record failure and trigger tightening
        source "$(dirname "${BASH_SOURCE[0]}")/tightener.sh"
        record_failure "$law_name"
        return 1
    fi
}

# Verify all laws for a specific hook
verify_hook_laws() {
    local hook_type="$1"
    local failed=0
    
    for law_dir in "$LAWS_DIR"/*; do
        if [ -d "$law_dir" ]; then
            local law_name=$(basename "$law_dir")
            local law_json="$law_dir/law.json"
            
            # Check if this law applies to the hook
            if [ -f "$law_json" ]; then
                local hooks=$(jq -r '.hooks[]?' "$law_json" 2>/dev/null)
                if echo "$hooks" | grep -q "$hook_type"; then
                    if ! verify_law "$law_name"; then
                        failed=1
                    fi
                fi
            fi
        fi
    done
    
    return $failed
}

# Main if run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ -n "$1" ]; then
        verify_law "$1"
    else
        verify_hook_laws "${2:-pre-commit}"
    fi
fi
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-verifier.sh
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add core/verifier.sh tests/test-verifier.sh
git commit -m "feat: add verification runner in verifier.sh"
```

---

### Task 6: Implement tightener.sh - guidance strengthening

**Files:**
- Create: `core/tightener.sh`
- Create: `tests/test-tightener.sh`

- [ ] **Step 1: Write failing test**

```bash
#!/bin/bash
# Test guidance tightening

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/tightener.sh"

echo "Testing record_failure..."
# Should fail initially
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test-tightener.sh
```

Expected: FAIL

- [ ] **Step 3: Write tightener.sh implementation**

```bash
#!/bin/bash
# Strengthen guidance when laws are violated

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Record a failure and tighten guidance
record_failure() {
    local law_name="$1"
    
    if ! law_exists "$law_name"; then
        log_error "Law '$law_name' does not exist"
        return 1
    fi
    
    local law_json="$LAWS_DIR/$law_name/law.json"
    local guidance_md="$GUIDANCE_DIR/$law_name.md"
    
    # Increment failure count
    local failures=$(get_law_meta "$law_name" "failures")
    failures=$((failures + 1))
    jq --arg f "$failures" '.failures = ($f | tonumber)' "$law_json" > "$law_json.tmp"
    mv "$law_json.tmp" "$law_json"
    
    # Get current tightening level
    local level=$(get_law_meta "$law_name" "tightening_level")
    level=$((level + 1))
    jq --arg l "$level" '.tightening_level = ($l | tonumber)' "$law_json" > "$law_json.tmp"
    mv "$law_json.tmp" "$law_json"
    
    # Append stricter guidance
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat >> "$guidance_md" <<EOF

---

**Violation recorded:** $timestamp (Total: $failures)

This law has been violated $failures time(s). The guidance has been automatically strengthened.

**Previous violations indicate this pattern is easy to miss. Pay extra attention.**
EOF
    
    log_warn "Law '$law_name' violated. Tightening level: $level. Failures: $failures"
}

# Reset failure count (for testing or manual intervention)
reset_failures() {
    local law_name="$1"
    
    if ! law_exists "$law_name"; then
        log_error "Law '$law_name' does not exist"
        return 1
    fi
    
    local law_json="$LAWS_DIR/$law_name/law.json"
    jq '.failures = 0 | .tightening_level = 0' "$law_json" > "$law_json.tmp"
    mv "$law_json.tmp" "$law_json"
    
    # Also truncate the guidance file to remove violation history
    local guidance_md="$GUIDANCE_DIR/$law_name.md"
    # Keep only content before first "---" marker or entire file if no markers
    if grep -q "^---" "$guidance_md"; then
        sed -q '1,/^---$/p' "$guidance_md" > "$guidance_md.tmp"
        mv "$guidance_md.tmp" "$guidance_md"
    fi
    
    log_info "Reset failure count for '$law_name'"
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
bash tests/test-tightener.sh
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add core/tightener.sh tests/test-tightener.sh
git commit -m "feat: add guidance tightening in tightener.sh"
```

---

### Task 7: Implement chp-law CLI command

**Files:**
- Create: `commands/chp-law`

- [ ] **Step 1: Write chp-law command**

```bash
#!/bin/bash
# CHP Law Management CLI

set -e

# Source core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/detector.sh"
source "$SCRIPT_DIR/../core/installer.sh"
source "$SCRIPT_DIR/../core/tightener.sh"

# Show usage
show_usage() {
    cat <<EOF
CHP Law Management

Usage:
  chp-law create <name> [--hooks=<hooks>]  Create a new law
  chp-law list                              List all laws
  chp-law delete <name>                     Delete a law
  chp-law test <name>                       Test a law's verification
  chp-law reset <name>                      Reset failure count

Examples:
  chp-law create no-api-keys --hooks=pre-commit,pre-push
  chp-law list
  chp-law delete no-api-keys

EOF
}

# Create a new law
create_law() {
    local law_name="$1"
    shift
    
    local hooks="pre-commit"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --hooks=*)
            hooks="${1#*=}"
            shift
            ;;
            *)
            log_error "Unknown option: $1"
            exit 1
            ;;
        esac
    done
    
    # Validate law name
    if [[ ! "$law_name" =~ ^[a-z0-9-]+$ ]]; then
        log_error "Law name must be lowercase letters, numbers, and hyphens only"
        exit 1
    fi
    
    # Check if law already exists
    if law_exists "$law_name"; then
        log_error "Law '$law_name' already exists"
        exit 1
    fi
    
    # Create law directory
    local law_dir="$LAWS_DIR/$law_name"
    mkdir -p "$law_dir"
    
    # Create law.json
    cat > "$law_dir/law.json" <<EOF
{
  "name": "$law_name",
  "description": "Law created via chp-law",
  "severity": "error",
  "hooks": $(echo "$hooks" | jq -R 'split(",") | map(ltrimstr(" "))'),
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "failures": 0,
  "tightening_level": 0
}
EOF
    
    # Create verify.sh template
    cat > "$law_dir/verify.sh" <<'EOF'
#!/bin/bash
# Verification script for THIS_LAW
# Exit 1 if violation detected, 0 if pass

# TODO: Implement verification logic
echo "Checking law: THIS_LAW"
exit 0
EOF
    sed -i "s/THIS_LAW/$law_name/g" "$law_dir/verify.sh"
    chmod +x "$law_dir/verify.sh"
    
    # Create guidance.md
    cat > "$GUIDANCE_DIR/$law_name.md" <<EOF
# Law: $law_name

**Severity:** Error  
**Created:** $(date -u +"%Y-%m-%d")

## What this means

TODO: Describe what this law enforces and why it matters.

## How to comply

TODO: Provide guidance on how to follow this law.

## Detection

TODO: Explain what patterns this law checks for.
EOF
    
    log_info "Created law '$law_name'"
    log_info "  Metadata: $law_dir/law.json"
    log_info "  Verification: $law_dir/verify.sh"
    log_info "  Guidance: $GUIDANCE_DIR/$law_name.md"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Edit $law_dir/verify.sh to implement verification"
    log_info "  2. Edit $GUIDANCE_DIR/$law_name.md to add guidance"
    log_info "  3. Run: chp-law test $law_name"
    log_info "  4. Hooks will be installed on first test or manually via installer"
}

# List all laws
list_laws_cmd() {
    if [ -z "$(ls -A "$LAWS_DIR" 2>/dev/null)" ]; then
        log_info "No laws defined yet"
        return
    fi
    
    echo "Defined laws:"
    echo ""
    
    for law_dir in "$LAWS_DIR"/*; do
        if [ -d "$law_dir" ]; then
            local name=$(basename "$law_dir")
            local description=$(get_law_meta "$name" "description")
            local severity=$(get_law_meta "$name" "severity")
            local failures=$(get_law_meta "$name" "failures")
            
            echo "  📋 $name"
            echo "     $description"
            echo "     Severity: $severity | Failures: $failures"
            echo ""
        fi
    done
}

# Delete a law
delete_law() {
    local law_name="$1"
    
    if ! law_exists "$law_name"; then
        log_error "Law '$law_name' does not exist"
        exit 1
    fi
    
    # Uninstall from all hooks first
    local law_json="$LAWS_DIR/$law_name/law.json"
    local hooks=$(jq -r '.hooks[]?' "$law_json" 2>/dev/null)
    
    for hook in $hooks; do
        uninstall_hook "$law_name" "$hook"
    done
    
    # Remove files
    rm -rf "$LAWS_DIR/$law_name"
    rm -f "$GUIDANCE_DIR/$law_name.md"
    
    log_info "Deleted law '$law_name'"
}

# Test a law's verification
test_law() {
    local law_name="$1"
    
    if ! law_exists "$law_name"; then
        log_error "Law '$law_name' does not exist"
        exit 1
    fi
    
    log_info "Testing law '$law_name'..."
    
    local verify_script="$LAWS_DIR/$law_name/verify.sh"
    if bash "$verify_script"; then
        log_info "✓ Verification passed"
        exit 0
    else
        log_error "✗ Verification failed"
        exit 1
    fi
}

# Reset failure count
reset_law() {
    local law_name="$1"
    reset_failures "$law_name"
}

# Main
case "${1:-}" in
    create)
        if [ -z "${2:-}" ]; then
            log_error "Law name required"
            show_usage
            exit 1
        fi
        create_law "$2" "${@:3}"
        ;;
    list)
        list_laws_cmd
        ;;
    delete)
        if [ -z "${2:-}" ]; then
            log_error "Law name required"
            show_usage
            exit 1
        fi
        delete_law "$2"
        ;;
    test)
        if [ -z "${2:-}" ]; then
            log_error "Law name required"
            show_usage
            exit 1
        fi
        test_law "$2"
        ;;
    reset)
        if [ -z "${2:-}" ]; then
            log_error "Law name required"
            show_usage
            exit 1
        fi
        reset_law "$2"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
```

- [ ] **Step 2: Make executable and test basic usage**

```bash
chmod +x commands/chp-law
./commands/chp-law
```

Expected: Shows usage information

- [ ] **Step 3: Test creating a law**

```bash
./commands/chp-law create test-law --hooks=pre-commit
```

Expected: Creates law files and shows paths

- [ ] **Step 4: Test listing laws**

```bash
./commands/chp-law list
```

Expected: Shows the created test-law

- [ ] **Step 5: Commit**

```bash
git add commands/chp-law
git commit -m "feat: add chp-law CLI command"
```

---

### Task 8: Implement chp-status command

**Files:**
- Create: `commands/chp-status`

- [ ] **Step 1: Write chp-status command**

```bash
#!/bin/bash
# CHP Status Display

set -e

# Source core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/detector.sh"

echo "CHP Law Enforcement Status"
echo "=========================="
echo ""

# Show detected hooks
echo "🔌 Detected Hook Systems:"
if [ -d .git ]; then
    echo "   ✓ Git hooks available"
    echo "     Available: pre-commit, pre-push, pre-merge-commit"
else
    echo "   ✗ Git hooks not available"
fi

if [ -d .pretool ] || [ -f .pretool ]; then
    echo "   ✓ Pretool hooks available"
    echo "     Available: pre-write, pre-commit, pre-push"
else
    echo "   - Pretool not configured"
fi

echo ""

# Show active laws
echo "📋 Active Laws:"
if [ -z "$(ls -A "$LAWS_DIR" 2>/dev/null)" ]; then
    echo "   No laws defined"
else
    for law_dir in "$LAWS_DIR"/*; do
        if [ -d "$law_dir" ]; then
            local name=$(basename "$law_dir")
            local severity=$(get_law_meta "$name" "severity")
            local failures=$(get_law_meta "$name" "failures")
            local hooks=$(get_law_meta "$name" "hooks" | jq -r 'join(", ")')
            
            if [ "$failures" -gt 0 ]; then
                echo "   ⚠️  $name ($severity) - $failures failures"
            else
                echo "   ✓ $name ($severity)"
            fi
            echo "      Hooks: $hooks"
        fi
    done
fi

echo ""

# Show installed hooks
echo "🔨 Installed Hooks:"
if [ -d .git/hooks ]; then
    for hook in .git/hooks/pre-commit .git/hooks/pre-push .git/hooks/pre-merge-commit; do
        if [ -f "$hook" ] && grep -q "CHP-MANAGED" "$hook"; then
            local hook_name=$(basename "$hook")
            local law_count=$(grep -c "^# Law:" "$hook" || echo "0")
            echo "   ✓ $hook_name ($law_count laws)"
        fi
    done
else
    echo "   No git hooks installed"
fi

echo ""
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x commands/chp-status
./commands/chp-status
```

Expected: Shows status of hooks, laws, and installations

- [ ] **Step 3: Commit**

```bash
git add commands/chp-status
git commit -m "feat: add chp-status command"
```

---

### Task 9: Implement chp:write-laws skill

**Files:**
- Create: `skills/write-laws/skill.md`

- [ ] **Step 1: Write the skill file**

```markdown
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
```

- [ ] **Step 2: Verify skill file exists**

```bash
cat skills/write-laws/skill.md | head -20
```

Expected: Shows skill header and content

- [ ] **Step 3: Commit**

```bash
git add skills/write-laws/skill.md
git commit -m "feat: add chp:write-laws skill"
```

---

### Task 10: Add example law for demonstration

**Files:**
- Create: `docs/chp/laws/no-console-log/`
- Create: `docs/chp/no-console-log.md`

- [ ] **Step 1: Create example law - no-console-log**

```bash
./commands/chp-law create no-console-log --hooks=pre-commit
```

- [ ] **Step 2: Edit verify.sh for no-console-log**

```bash
cat > docs/chp/laws/no-console-log/verify.sh <<'EOF'
#!/bin/bash
# Prevent console.log statements in code

# Check staged files for console.log
staged_files=$(git diff --cached --name-only --diff-filter=ACM)
violations=""

for file in $staged_files; do
    # Skip certain file types
    if [[ "$file" =~ \.(md|json|txt|sh)$ ]]; then
        continue
    fi
    
    if git diff --cached "$file" | grep -q "console\.log"; then
        violations="$violations\n  - $file"
    fi
done

if [ -n "$violations" ]; then
    echo "❌ console.log detected in staged files:$violations"
    echo ""
    echo "Please remove console.log statements before committing."
    echo "Use logger or proper logging framework instead."
    exit 1
fi

exit 0
EOF
chmod +x docs/chp/laws/no-console-log/verify.sh
```

- [ ] **Step 3: Edit guidance for no-console-log**

```bash
cat > docs/chp/no-console-log.md <<'EOF'
# Law: No Console Log

**Severity:** Error  
**Action:** Blocks commits

## What this means

Do not commit `console.log()` statements to the codebase. Console logs should be removed during development or replaced with proper logging.

## How to comply

**Before committing:**
- Remove all `console.log()` debugging statements
- Use proper logging framework for production logs
- Use `console.error()` only for genuine error conditions

**Acceptable alternatives:**
- `logger.info()`, `logger.error()` (use the project's logger)
- `console.error()` for actual errors (not debugging)
- Debuggers instead of console logs

## Detection

Scans staged files for the pattern `console.log` in:
- JavaScript files (.js, .jsx, .ts, .tsx)
- Any other code files

Skips: markdown, JSON, text, and shell scripts.

## Why this exists

Console logs left in production code:
- Clutter browser consoles
- May expose sensitive information
- Indicate incomplete debugging
- Impact performance
EOF
```

- [ ] **Step 4: Test the example law**

```bash
./commands/chp-law test no-console-log
```

Expected: Pass (no violations in current state)

- [ ] **Step 5: Check system status**

```bash
./commands/chp-status
```

Expected: Shows the no-console-log law

- [ ] **Step 6: Commit**

```bash
git add docs/chp/
git commit -m "feat: add example no-console-log law"
```

---

### Task 11: Create README documentation

**Files:**
- Modify: `README.md` (or create if minimal)

- [ ] **Step 1: Update README with law enforcement section**

```bash
cat >> README.md <<'EOF'

## Law Enforcement System

CHP includes a two-layer law enforcement system:

### Quick Start

```bash
# Create a new law
./commands/chp-law create my-law --hooks=pre-commit

# List all laws
./commands/chp-law list

# Check system status
./commands/chp-status
```

### How It Works

1. **Suggestive Layer** - Context files in `docs/chp/` guide agents to follow rules
2. **Verification Layer** - Scripts in `docs/chp/laws/` check for violations
3. **Auto-Tightening** - Failed verifications strengthen guidance automatically

### Creating Laws

See the [chp:write-laws](skills/write-laws/skill.md) skill for detailed guidance.

```bash
# Create a law
./commands/chp-law create no-secrets --hooks=pre-commit,pre-push

# Edit the verification script
vim docs/chp/laws/no-secrets/verify.sh

# Edit the guidance
vim docs/chp/no-secrets.md

# Test it
./commands/chp-law test no-secrets
```

### Example Laws

- **no-console-log** - Prevents console.log commits (included)
- **no-api-keys** - Detects API key patterns (create with chp-law)
EOF
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add law enforcement section to README"
```

---

## Final Review

After implementation, verify:

1. All core scripts are executable
2. All tests pass
3. `chp-law create` works end-to-end
4. `chp-law list` shows laws
5. `chp-law test` runs verification
6. `chp-status` shows system state
7. The skill file can be loaded
8. Example law demonstrates the system

## Integration Notes

- Hooks are installed when laws are created or tested
- Git hooks must be executable (chmod +x)
- Pretool integration requires pretool to be installed
- All bash scripts should be POSIX-compatible where possible
EOF
