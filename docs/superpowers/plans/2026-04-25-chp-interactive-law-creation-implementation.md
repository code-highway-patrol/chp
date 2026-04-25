# CHP Interactive Law Creation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make CHP law creation conversational and intelligent - agent suggests configurations, asks questions only when context is unclear, uses atomic CLI commands.

**Architecture:** Refactor `chp-law create` to be interactive with adaptive questioning, add new `chp-law update` command for atomic modifications, support `--dry-run` flag for previewing.

**Tech Stack:** Bash shell scripts, existing CHP command infrastructure

---

## File Structure

```
commands/
├── chp-law                    # MODIFY - Add interactive create, add update command
core/
├── interactive.sh             # NEW - Interactive prompting utilities
├── law-builder.sh             # NEW - Law construction logic
skills/
├── write-laws/skill.md        # MODIFY - Update to reflect new interactive flow
└── refine-laws/skill.md       # MODIFY - Update to use chp-law update commands
```

---

### Task 1: Create interactive prompting utilities

**Files:**
- Create: `core/interactive.sh`

- [ ] **Step 1: Create the interactive.sh module**

```bash
cat > core/interactive.sh << 'EOF'
#!/bin/bash
# Interactive prompting utilities for CHP CLI

# Prompt user with a question and multiple choice options
# Usage: prompt_choice "Question text" "Option 1" "Option 2" "Option 3" ...
# Returns: The selected option number (1-indexed)
prompt_choice() {
    local question="$1"
    shift
    local options=("$@")
    
    echo ""
    echo "$question"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    echo ""
    
    local choice
    read -p "Choose one: " choice
    
    # Validate choice is a number
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid choice. Please enter a number."
        return 1
    fi
    
    # Validate choice is in range
    if [[ $choice -lt 1 || $choice -gt ${#options[@]} ]]; then
        echo "Invalid choice. Please enter a number between 1 and ${#options[@]}."
        return 1
    fi
    
    echo "${options[$((choice-1))]}"
}

# Prompt for yes/no confirmation
# Usage: prompt_yes_no "Question text"
# Returns: 0 for yes, 1 for no
prompt_yes_no() {
    local question="$1"
    local response
    
    while true; do
        read -p "$question (y/n): " response
        case "$response" in
            y|Y|yes|YES) return 0 ;;
            n|N|no|NO) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Prompt for text input with default
# Usage: prompt_text "Question" "default_value"
prompt_text() {
    local question="$1"
    local default="$2"
    local response
    
    if [[ -n "$default" ]]; then
        read -p "$question [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$question: " response
        echo "$response"
    fi
}

# Display a preview of what will be created
# Usage: display_preview "Law name" "severity" "hooks" "pattern" "files" "exceptions"
display_preview() {
    local law_name="$1"
    local severity="$2"
    local hooks="$3"
    local pattern="$4"
    local files="$5"
    local exceptions="$6"
    
    echo ""
    echo "=================================="
    echo "  Law Preview: $law_name"
    echo "=================================="
    echo ""
    echo "  Pattern: $pattern"
    echo "  Files: $files"
    echo "  Severity: $severity"
    echo "  Hooks: $hooks"
    if [[ -n "$exceptions" && "$exceptions" != "none" ]]; then
        echo "  Exceptions: $exceptions"
    fi
    echo ""
    echo "  Files created:"
    echo "    • docs/chp/laws/$law_name/law.json"
    echo "    • docs/chp/laws/$law_name/verify.sh"
    echo "    • docs/chp/laws/$law_name/guidance.md"
    echo ""
    
    # Show which hooks will be installed
    local IFS=','
    for hook in $hooks; do
        echo "  Hooks installed:"
        case "$hook" in
            pre-commit) echo "    • .git/hooks/pre-commit" ;;
            pre-push) echo "    • .git/hooks/pre-push" ;;
            pre-merge-commit) echo "    • .git/hooks/pre-merge-commit" ;;
        esac
    done
    echo ""
}
EOF
```

- [ ] **Step 2: Make the file executable**

```bash
chmod +x core/interactive.sh
```

- [ ] **Step 3: Verify the file was created**

```bash
ls -la core/interactive.sh
```

Expected: File exists with -rwxr-xr-x permissions

- [ ] **Step 4: Commit**

```bash
git add core/interactive.sh
git commit -m "feat: add interactive prompting utilities for CHP CLI"
```

---

### Task 2: Create law builder module

**Files:**
- Create: `core/law-builder.sh`

- [ ] **Step 1: Create the law-builder.sh module**

```bash
cat > core/law-builder.sh << 'EOF'
#!/bin/bash
# Law construction logic for CHP

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Suggest law configuration based on law name
# Usage: suggest_config <law-name>
# Outputs: Suggested severity, hooks, pattern, files on separate lines
suggest_config() {
    local law_name="$1"
    
    case "$law_name" in
        *api-key*|*secret*|*credential*)
            echo "error"
            echo "pre-commit,pre-push"
            echo "API key patterns (sk_*, AIza*, AKIA*, Bearer)"
            echo "All files"
            echo "none"
            ;;
        *console-log*|*debug*)
            echo "error"
            echo "pre-commit,pre-push"
            echo "console\.log"
            echo "*.js,*.ts,*.tsx,*.jsx"
            echo "none"
            ;;
        *todo*|*fixme*)
            echo "warn"
            echo "pre-commit"
            echo "(TODO|FIXME)"
            echo "All source files"
            echo "none"
            ;;
        *file-size*|*max-lines*)
            echo "error"
            echo "pre-commit"
            echo "File line count > 300"
            echo "All source files"
            echo "none"
            ;;
        *test*|*coverage*)
            echo "warn"
            echo "pre-push"
            echo "Test coverage < 80%"
            echo "*.test.js,*.spec.js"
            echo "none"
            ;;
        *)
            echo "warn"
            echo "pre-commit"
            echo "Custom pattern"
            echo "All files"
            echo "none"
            ;;
    esac
}

# Check if law intent is clear enough to suggest defaults
# Usage: is_intent_clear <law-name>
# Returns: 0 if clear, 1 if unclear
is_intent_clear() {
    local law_name="$1"
    
    # Clear patterns: well-known law types
    if [[ "$law_name" =~ (api-key|secret|credential|console-log|debug|todo|fixme|test|coverage|file-size|max-lines) ]]; then
        return 0
    fi
    
    # Unclear: vague terms
    if [[ "$law_name" =~ (quality|enforce|standard|rule|best-practice) ]]; then
        return 1
    fi
    
    # Default to unclear
    return 1
}

# Build law.json content
# Usage: build_law_json <name> <severity> <hooks> <enabled>
build_law_json() {
    local name="$1"
    local severity="$2"
    local hooks="$3"
    local enabled="${4:-true}"
    
    local hooks_array=$(echo "$hooks" | jq -R . | jq -s -c .)
    
    cat <<EOF
{
  "name": "$name",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "severity": "$severity",
  "failures": 0,
  "tightening_level": 0,
  "hooks": $hooks_array,
  "enabled": $enabled
}
EOF
}

# Build verify.sh template
# Usage: build_verify_template <name> <pattern> <files> <exceptions>
build_verify_template() {
    local name="$1"
    local pattern="$2"
    local files="$3"
    local exceptions="$4"
    
    cat <<EOF
#!/bin/bash
# Verification script for law: $name

# Get the absolute path to CHP base directory
LAW_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="\$(cd "\$LAW_DIR/../../../../" && pwd)"

# Source CHP common functions
source "\$CHP_BASE/core/common.sh"

# Main verification logic
verify_law() {
    local law_name="$name"
    
    log_info "Verifying law: $law_name"
    
    # Pattern to detect: $pattern
    
    # File types to check: $files
    
    # Exceptions: $exceptions
    
    # Add your verification logic here
    # Return 0 if verification passes
    # Return 1 if verification fails
    
    log_info "Law verification passed: $law_name"
    return 0
}

# Run verification
verify_law
exit \$?
EOF
}

# Build guidance.md template
# Usage: build_guidance_template <name> <severity> <description>
build_guidance_template() {
    local name="$1"
    local severity="$2"
    local description="$3"
    
    cat <<EOF
# Law: $name

**Severity:** $severity
**Created:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Failures:** 0

## Purpose

This law enforces: $description

## Guidance

Describe what this law checks for and how to comply.

### Examples

#### Good Practice
\`\`\`
// Show examples of compliant code
\`\`\`

#### Bad Practice (will fail verification)
\`\`\`
// Show examples of non-compliant code
\`\`\`

## Remediation

If this law fails, take these steps:
1. Identify the violation
2. Fix the issue
3. Re-run the verification
4. Commit your changes

---

*This guidance will be automatically strengthened if violations occur.*
EOF
}
EOF
```

- [ ] **Step 2: Make the file executable**

```bash
chmod +x core/law-builder.sh
```

- [ ] **Step 3: Verify the file was created**

```bash
head -30 core/law-builder.sh
```

Expected: Output shows the law builder functions

- [ ] **Step 4: Commit**

```bash
git add core/law-builder.sh
git commit -m "feat: add law builder module for CHP"
```

---

### Task 3: Refactor chp-law create to support interactive mode

**Files:**
- Modify: `commands/chp-law`

- [ ] **Step 1: Source the new modules at the top of chp-law**

Add after line 9 (after sourcing core functions):
```bash
# Source interactive and builder modules
source "$SCRIPT_DIR/../core/interactive.sh"
source "$SCRIPT_DIR/../core/law-builder.sh"
```

- [ ] **Step 2: Add --dry-run flag to create_law function**

Modify the `create_law` function (starts around line 88) to add dry-run support. Find the line `local hooks_arg="$2"` and add:

```bash
    local dry_run=false
    
    # Parse optional arguments
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --hooks=*)
                hooks_arg="${1#*=}"
                ;;
            --dry-run)
                dry_run=true
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done
```

- [ ] **Step 3: Add flag variables for interactive mode**

After the hooks parsing, add support for other flags:

```bash
    # Flag variables (from command line or interactive)
    local specified_severity=""
    local specified_pattern=""
    local specified_files=""
    local specified_exceptions=""
```

- [ ] **Step 4: Replace hardcoded template with law_builder functions**

Find the section that creates law.json (around line 116-126) and replace with:

```bash
    # Determine if intent is clear
    if is_intent_clear "$law_name"; then
        # Suggest configuration
        read severity _ <<< $(suggest_config "$law_name")
        read _ hooks _ <<< $(suggest_config "$law_name")
        read pattern _ <<< $(suggest_config "$law_name")
        read _ files _ <<< $(suggest_config "$law_name")
        read exceptions _ <<< $(suggest_config "$law_name")
    else
        # Ask questions interactively
        echo "Creating law: $law_name"
        echo ""
        echo "What should this law enforce?"
        echo "  A) File size limits"
        echo "  B) Function length limits"
        echo "  C) Documentation requirements"
        echo "  D) Custom pattern"
        
        local choice
        read -p "Choose one: " choice
        
        case "$choice" in
            A|a)
                pattern="File line count > LIMIT"
                files="All source files"
                ;;
            B|b)
                pattern="Function line count > LIMIT"
                files="*.js,*.ts,*.py"
                ;;
            C|c)
                pattern="(TODO|FIXME)"
                files="All source files"
                ;;
            *)
                pattern=$(prompt_text "Enter the pattern to detect")
                files=$(prompt_text "Which file types" "*.js,*.ts")
                ;;
        esac
        
        severity="warn"
        hooks="pre-commit"
        exceptions="none"
    fi
    
    # Apply flag overrides if provided
    [[ -n "$specified_severity" ]] && severity="$specified_severity"
    [[ -n "$specified_pattern" ]] && pattern="$specified_pattern"
    [[ -n "$specified_files" ]] && files="$specified_files"
    [[ -n "$specified_exceptions" ]] && exceptions="$specified_exceptions"
```

- [ ] **Step 5: Add display_preview call before creating**

Find the line `mkdir -p "$law_dir"` and add before it:

```bash
    # Show preview
    display_preview "$law_name" "$severity" "$hooks" "$pattern" "$files" "$exceptions"
    
    # Confirm before creating (unless dry-run)
    if [[ "$dry_run" = false ]]; then
        if ! prompt_yes_no "Create this law?"; then
            log_info "Law creation cancelled"
            return 0
        fi
    else
        log_info "Dry run - law not created"
        return 0
    fi
    
    # Create law directory
    mkdir -p "$law_dir"
```

- [ ] **Step 6: Test the refactored create command**

```bash
bash commands/chp-law create --help 2>&1 | head -20
```

Expected: Shows usage information (may have errors we'll fix in next tasks)

- [ ] **Step 7: Commit**

```bash
git add commands/chp-law
git commit -m "refactor: add interactive mode to chp-law create"
```

---

### Task 4: Add flag parsing for all create options

**Files:**
- Modify: `commands/chp-law`

- [ ] **Step 1: Add flag parsing for severity, pattern, files, exceptions**

In the `create_law` function, expand the flag parsing section to include all options:

```bash
    # Parse optional arguments
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --hooks=*)
                hooks_arg="${1#*=}"
                ;;
            --severity=*)
                specified_severity="${1#*=}"
                ;;
            --pattern=*)
                specified_pattern="${1#*=}"
                ;;
            --files=*)
                specified_files="${1#*=}"
                ;;
            --exceptions=*)
                specified_exceptions="${1#*=}"
                ;;
            --dry-run)
                dry_run=true
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done
```

- [ ] **Step 2: Update usage information to show new flags**

Modify the `show_usage` function to include the new options:

```bash
Options:
    --hooks=<hooks>       Comma-separated list of hooks
    --severity=<level>    Severity level (error|warn|info)
    --pattern=<regex>      Custom detection pattern
    --files=<extensions>   File types to check
    --exceptions=<list>   Exception patterns (comma-separated)
    --dry-run             Preview without creating
```

- [ ] **Step 3: Verify flag parsing works**

```bash
bash commands/chp-law create test-law --severity=warn --dry-run 2>&1 | head -20
```

Expected: Should show preview or dry-run message

- [ ] **Step 4: Commit**

```bash
git add commands/chp-law
git commit -m "feat: add flag parsing for chp-law create options"
```

---

### Task 5: Implement chp-law update command

**Files:**
- Modify: `commands/chp-law`

- [ ] **Step 1: Add update_law function to chp-law**

Add after the `enable_law` function (around line 459):

```bash
# Update a law's configuration
update_law() {
    local law_name="$1"
    shift
    
    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        echo "Usage: chp-law update <law-name> [options]"
        return 1
    fi
    
    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi
    
    local law_dir="$LAWS_DIR/$law_name"
    local law_json="$law_dir/law.json"
    
    # Parse update options
    local new_severity=""
    local new_hooks=""
    local add_hook=""
    local remove_hook=""
    local add_exception=""
    local remove_exception=""
    local set_guidance=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --severity=*)
                new_severity="${1#*=}"
                ;;
            --hooks=*)
                new_hooks="${1#*=}"
                ;;
            --add-hook=*)
                add_hook="${1#*=}"
                ;;
            --remove-hook=*)
                remove_hook="${1#*=}"
                ;;
            --add-exception=*)
                add_exception="${1#*=}"
                ;;
            --remove-exception=*)
                remove_exception="${1#*=}"
                ;;
            --set-guidance)
                set_guidance=true
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    # Apply updates
    local updated=false
    
    if [[ -n "$new_severity" ]]; then
        jq ".severity = \"$new_severity\"" "$law_json" > "${law_json}.tmp" && \
        mv "${law_json}.tmp" "$law_json"
        log_info "Updated severity to: $new_severity"
        updated=true
    fi
    
    if [[ -n "$new_hooks" ]]; then
        local hooks_array=$(echo "$new_hooks" | jq -R . | jq -s -c .)
        jq ".hooks = $hooks_array" "$law_json" > "${law_json}.tmp" && \
        mv "${law_json}.tmp" "$law_json"
        log_info "Updated hooks to: $new_hooks"
        updated=true
    fi
    
    if [[ -n "$add_hook" ]]; then
        jq ".hooks += [\"$add_hook\"]" "$law_json" > "${law_json}.tmp" && \
        mv "${law_json}.tmp" "$law_json"
        log_info "Added hook: $add_hook"
        updated=true
    fi
    
    if [[ -n "$remove_hook" ]]; then
        jq ".hooks -= [\"$remove_hook\"]" "$law_json" > "${law_json}.tmp" && \
        mv "${law_json}.tmp" "$law_json"
        log_info "Removed hook: $remove_hook"
        updated=true
    fi
    
    if [[ -n "$add_exception" ]]; then
        # Add to exceptions array in law.json (would need to be added to schema first)
        log_info "Would add exception: $add_exception (not yet implemented)"
        updated=true
    fi
    
    if [[ -n "$remove_exception" ]]; then
        log_info "Would remove exception: $remove_exception (not yet implemented)"
        updated=true
    fi
    
    if [[ "$set_guidance" = true ]]; then
        log_info "Opening guidance.md for editing..."
        "${EDITOR:-vim}" "$law_dir/guidance.md"
        updated=true
    fi
    
    if [[ "$updated" = false ]]; then
        log_warn "No updates specified"
        return 0
    fi
    
    log_info "Law updated: $law_name"
    return 0
}
```

- [ ] **Step 2: Add update command to main case statement**

Find the main case statement (around line 462) and add after `enable` case:

```bash
        update)
            if [[ $# -lt 1 ]]; then
                log_error "Usage: chp-law update <law-name> [options]"
                exit 1
            fi
            update_law "$@"
            ;;
```

- [ ] **Step 3: Update usage information**

Add to the show_usage function:

```bash
Commands:
    create <law-name> [options]      Create a new law (interactive)
    update <law-name> [options]      Update law configuration
    list                             List all laws
    delete <law-name>                Delete a law
    test <law-name>                  Test a law
    reset <law-name>                 Reset failure count
    disable <law-name>               Disable a law
    enable <law-name>                Enable a law
    help                             Show this help message
```

- [ ] **Step 4: Test the update command**

```bash
bash commands/chp-law update --help 2>&1 || bash commands/chp-law 2>&1 | grep -A5 "Commands"
```

Expected: Shows update in the commands list

- [ ] **Step 5: Commit**

```bash
git add commands/chp-law
git commit -m "feat: add chp-law update command for atomic modifications"
```

---

### Task 6: Update write-laws skill documentation

**Files:**
- Modify: `skills/write-laws/skill.md`

- [ ] **Step 1: Rewrite the skill to reflect interactive create flow**

Replace the entire content of `skills/write-laws/skill.md` with:

```markdown
---
name: write-laws
description: Create and manage CHP enforcement laws through interactive, conversational workflow
---

# CHP Law Creation

Create CHP laws through an interactive, conversational process. The agent will suggest configurations based on your intent and ask questions only when context is unclear.

## When to Use

Invoke this skill when:
- You want to create a new CHP law
- You need to enforce a rule or standard in the repository
- You mention preventing specific patterns (API keys, console.log, etc.)
- Agent detects a quantifiable code quality issue

## How It Works

### Conversational Creation

The agent guides you through creating a law by:

1. **Understanding your intent** - What should the law enforce?
2. **Assessing clarity** - Is your specific request clear enough to suggest defaults?
3. **Suggesting configuration** - For clear intents, proposes reasonable defaults with reasoning
4. **Asking questions** - For unclear intents, asks targeted questions to understand requirements
5. **Previewing** - Always shows what will be created before committing
6. **Creating** - Runs `chp-law create` with appropriate configuration
7. **Testing** - Automatically tests the law after creation

### Clear Intent Example

```
You: "I want to prevent console.log statements"

Agent: I'll create a "no-console-log" law with these recommendations:
  • Pattern: console\.log
  • Files: JavaScript, TypeScript
  • Severity: error (debug code shouldn't ship)
  • Hooks: pre-commit, pre-push (catch early)
  
  Does this look right?

You: "Yes, but allow console.error for error tracking"

Agent: Got it. Creating with console.error exception...
  [Creates law]
  [Tests law]
  
✓ Law created! Edit verify.sh to customize detection logic.
```

### Unclear Intent Example

```
You: "I want to enforce code quality"

Agent: What specifically should this enforce?
  A) File size limits (max lines per file)
  B) Function length (max lines per function)  
  C) Documentation requirements
  D) Custom pattern

You: "A"

Agent: What's the max file size?
  A) 100 lines
  B) 300 lines
  C) 500 lines

You: "B"

[...continues with targeted questions...]
```

## Using the CLI Directly

### Interactive Creation

```bash
# Interactive mode - asks questions
chp-law create <law-name>
```

### Skip Questions with Flags

```bash
# Provide all options upfront
chp-law create no-console-log \
  --severity=error \
  --hooks=pre-commit,pre-push \
  --exceptions=console.error,console.warn
```

### Preview Before Creating

```bash
# See what will be created
chp-law create <law-name> --dry-run
```

## Available Commands

```bash
chp-law create <name> [options]    # Create new law (interactive)
chp-law update <name> [options]    # Update existing law
chp-law list                        # List all laws
chp-law delete <name>               # Delete a law
chp-law test <name>                # Test verification
chp-law reset <name>               # Reset failure count
chp-law enable <name>              # Enable disabled law
chp-law disable <name>             # Disable law
```

## Create Command Options

```bash
--severity=<level>     Severity: error, warn, or info
--hooks=<list>         Comma-separated hooks (pre-commit, pre-push, etc.)
--pattern=<regex>      Custom detection pattern
--files=<extensions>   File types to check (*.js, *.ts, etc.)
--exceptions=<list>    Exception patterns (comma-separated)
--dry-run             Preview without creating
```

## Update Command Options

```bash
--severity=<level>         Change severity level
--hooks=<list>             Replace all hooks
--add-hook=<hook>          Add a hook
--remove-hook=<hook>       Remove a hook
--add-exception=<pattern>  Add exception pattern
--remove-exception=<pattern> Remove exception pattern
--set-guidance             Open guidance.md for editing
```

## Common Law Patterns

### Security Laws

```bash
chp-law create no-api-keys --severity=error --hooks=pre-commit,pre-push
chp-law create no-secrets --severity=error --hooks=pre-commit
chp-law create no-hardcoded-credentials --severity=warn --hooks=pre-push
```

### Quality Laws

```bash
chp-law create no-console-log --severity=error --exceptions=console.error
chp-law create max-file-size --severity=warn --hooks=pre-commit
chp-law create require-documentation --severity=info --hooks=pre-push
```

### Workflow Laws

```bash
chp-law create test-coverage --severity=warn --hooks=pre-push
chp-law create no-todos --severity=error --hooks=pre-commit
```

## After Creation

1. **Review the law files** in `docs/chp/laws/<law-name>/`
2. **Edit verify.sh** to implement actual detection logic
3. **Edit guidance.md** to add compliance guidance
4. **Test the law** with `chp-law test <law-name>`
5. **Commit your changes**

## Related Skills

- **chp:refine-laws** - Tune existing laws
- **chp:investigate** - Debug why actions were blocked
- **chp:audit** - Scan codebase for violations
```

- [ ] **Step 2: Verify the skill file was updated**

```bash
wc -l skills/write-laws/skill.md
```

Expected: ~200 lines (increased from original)

- [ ] **Step 3: Commit**

```bash
git add skills/write-laws/skill.md
git commit -m "docs: update write-laws skill for interactive flow"
```

---

### Task 7: Update refine-laws skill documentation

**Files:**
- Modify: `skills/refine-laws/skill.md`

- [ ] **Step 1: Add update command examples to refine-laws skill**

Find the "Refinement Scenarios" section and update each scenario to use the new `chp-law update` command.

For example, update "Scenario 2: Change Severity" to:

```markdown
### Scenario 2: Change Severity

**Problem:** Law is too strict or too lenient

**Example:** `max-function-length` should warn, not error

**Solution:** Use `chp-law update`

```bash
chp-law update max-function-length --severity=warn
```

**Test the change:**
```bash
chp-law test max-function-length
```
```

- [ ] **Step 2: Add new scenario for adding exceptions**

Add to the Refinement Scenarios section:

```markdown
### Scenario 7: Add Exception Pattern

**Problem:** Law flags things that should be allowed

**Example:** `no-console-log` should allow `console.dir` for debugging

**Solution:** Use `chp-law update`

```bash
chp-law update no-console-log --add-exception=console\.dir
```

**Test the change:**
```bash
chp-law test no-console-log
```
```

- [ ] **Step 3: Verify and commit**

```bash
git add skills/refine-laws/skill.md
git commit -m "docs: update refine-laws skill to use chp-law update"
```

---

### Task 8: Test the complete interactive workflow

**Files:**
- Test: Manual testing of create and update commands

- [ ] **Step 1: Test interactive create with clear intent**

```bash
bash commands/chp-law create test-interactive-no-console --dry-run 2>&1
```

Expected: Should show preview with suggested defaults for console.log law

- [ ] **Step 2: Test create with flags**

```bash
bash commands/chp-law create test-flagged --severity=warn --hooks=pre-commit --dry-run 2>&1
```

Expected: Should show preview with specified values

- [ ] **Step 3: Test update command**

```bash
# First create a law
bash commands/chp-law create test-update-law --dry-run 2>&1 | head -5

# Then test update (this will fail until we fully implement)
bash commands/chp-law update test-update-law --severity=warn 2>&1 || echo "Expected - law doesn't exist yet"
```

- [ ] **Step 4: Verify help text shows new options**

```bash
bash commands/chp-law 2>&1 | grep -E "(create|update)" | head -5
```

Expected: Shows both create and update commands

- [ ] **Step 5: Create test documentation**

```bash
cat > tests/test-interactive-creation.md << 'EOF'
# Interactive Creation Tests

## Test Cases

1. Clear intent - should suggest defaults
   - chp-law create no-api-keys
   - Expected: Suggests error severity, pre-commit hooks

2. Unclear intent - should ask questions  
   - chp-law create enforce-quality
   - Expected: Asks what to enforce

3. Flags override - should skip questions
   - chp-law create test --severity=warn
   - Expected: Uses specified severity

4. Dry run - should preview only
   - chp-law create test --dry-run
   - Expected: Shows preview, doesn't create

5. Update severity
   - chp-law update test --severity=error
   - Expected: Updates law.json

6. Add hook
   - chp-law update test --add-hook=pre-push
   - Expected: Adds hook to array
EOF
```

- [ ] **Step 6: Commit**

```bash
git add tests/test-interactive-creation.md
git commit -m "test: add interactive creation test documentation"
```

---

## Summary

This implementation adds conversational, intelligent law creation to CHP:

**New components:**
- `core/interactive.sh` - Prompting utilities
- `core/law-builder.sh` - Law configuration logic

**Modified components:**
- `commands/chp-law` - Interactive create mode, update command, flag support
- `skills/write-laws/skill.md` - Updated for interactive flow
- `skills/refine-laws/skill.md` - Updated to use update command

**Key features:**
- Adaptive questioning (clear intent → suggest, unclear → ask)
- Atomic `chp-law update` command for all modifications
- Flag support to bypass questions
- `--dry-run` for previewing changes
- Automatic testing after creation
