#!/bin/bash
# Hook installation and management for CHP laws

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detector.sh"

# Marker to identify CHP-managed hooks
readonly CHP_MANAGED_MARKER="# CHP-MANAGED"

# ============================================================================
# ENVIRONMENT DETECTION
# ============================================================================

# Check if git is installed and available
is_git_installed() {
    command -v git >/dev/null 2>&1
}

# Check if we're in a git repository
is_git_repository() {
    git rev-parse --git-dir >/dev/null 2>&1
}

# Check if git hooks can be installed (git installed + in a git repo)
can_install_git_hooks() {
    is_git_installed && is_git_repository
}

# Install a hook for a law
install_hook() {
    local law_name="$1"
    local hook_type="$2"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if [[ -z "$hook_type" ]]; then
        log_error "Hook type is required"
        return 1
    fi

    # Determine hook path based on type
    local hook_dir
    local hook_file

    if [[ "$hook_type" == "pre-write" ]]; then
        # Pretool hook
        hook_dir=".git/pretool/hooks"
        hook_file="$hook_dir/pre-write"
    else
        # Git hook - check if git is available first
        if ! is_git_installed; then
            log_warn "Git is not installed, skipping git hook: $hook_type for law: $law_name"
            return 0
        fi

        if ! is_git_repository; then
            log_warn "Not in a git repository, skipping git hook: $hook_type for law: $law_name"
            return 0
        fi

        hook_dir=".git/hooks"
        hook_file="$hook_dir/$hook_type"
    fi

    # Create hook directory if it doesn't exist
    mkdir -p "$hook_dir"

    # Backup existing hook if it exists and is not CHP-managed
    if [[ -f "$hook_file" ]]; then
        if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
            local backup_file="${hook_file}.backup.$(date +%s)"
            cp "$hook_file" "$backup_file"
            log_info "Backed up existing hook to $backup_file"
        fi
    fi

    # Create or update the hook file
    {
        echo "#!/bin/bash"
        echo "$CHP_MANAGED_MARKER"
        echo "# CHP Law: $law_name"
        echo "# Hook type: $hook_type"
        echo ""
        echo "# Source CHP common functions"
        echo "source \"\$(dirname \"\$0\")/../core/common.sh\""
        echo ""
        echo "# Run the law"
        echo "chp run \"$law_name\""
        echo ""
        echo "# Exit with hook's exit code"
        echo "exit \$?"
    } > "$hook_file"

    chmod +x "$hook_file"
    log_info "Installed hook: $hook_file for law: $law_name"

    return 0
}

# Uninstall a hook for a law
uninstall_hook() {
    local law_name="$1"
    local hook_type="$2"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if [[ -z "$hook_type" ]]; then
        log_error "Hook type is required"
        return 1
    fi

    # Determine hook path based on type
    local hook_dir
    local hook_file

    if [[ "$hook_type" == "pre-write" ]]; then
        # Pretool hook
        hook_dir=".git/pretool/hooks"
        hook_file="$hook_dir/pre-write"
    else
        # Git hook
        hook_dir=".git/hooks"
        hook_file="$hook_dir/$hook_type"
    fi

    # Check if hook exists
    if [[ ! -f "$hook_file" ]]; then
        log_warn "Hook file does not exist: $hook_file"
        return 0
    fi

    # Check if hook is CHP-managed
    if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
        log_warn "Hook is not CHP-managed, skipping: $hook_file"
        return 0
    fi

    # Check if hook contains the law
    if ! grep -q "# CHP Law: $law_name" "$hook_file"; then
        log_warn "Hook does not contain law: $law_name"
        return 0
    fi

    # Remove the hook file
    rm -f "$hook_file"
    log_info "Uninstalled hook: $hook_file for law: $law_name"

    return 0
}

# ============================================================================
# NEW UNIVERSAL HOOK INSTALLATION FUNCTIONS
# ============================================================================

# Backup an existing hook before overwriting
backup_existing_hook() {
    local hook_path="$1"

    if [[ -z "$hook_path" ]]; then
        log_error "Hook path is required"
        return 1
    fi

    # Check if hook exists
    if [[ ! -f "$hook_path" ]]; then
        log_debug "No existing hook to backup: $hook_path"
        return 0
    fi

    # Check if hook is CHP-managed
    if grep -q "$CHP_MANAGED_MARKER" "$hook_path"; then
        log_debug "CHP-managed hook, skipping backup: $hook_path"
        return 0
    fi

    # Create backup with timestamp
    local backup_file="${hook_path}.chp-backup-$(date +%s)"
    cp "$hook_path" "$backup_file"
    log_info "Backed up existing hook to $backup_file"

    return 0
}

# Install a hook template based on category
install_hook_template() {
    local hook_type="$1"
    local hook_category="$2"

    if [[ -z "$hook_type" ]]; then
        log_error "Hook type is required"
        return 1
    fi

    if [[ -z "$hook_category" ]]; then
        log_error "Hook category is required"
        return 1
    fi

    # Call category-specific installer
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

# Uninstall a hook template based on category
uninstall_hook_template() {
    local hook_type="$1"
    local hook_category="$2"

    if [[ -z "$hook_type" ]]; then
        log_error "Hook type is required"
        return 1
    fi

    if [[ -z "$hook_category" ]]; then
        log_error "Hook category is required"
        return 1
    fi

    # Call category-specific uninstaller
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

# Install all hooks for a law (reads from law.json)
install_law_hooks() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    # Check if law exists
    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    # Read hooks from law.json
    local law_json="$LAWS_DIR/$law_name/law.json"
    if [[ ! -f "$law_json" ]]; then
        log_error "law.json not found for: $law_name"
        return 1
    fi

    local hooks
    hooks=$(jq -r '.hooks[] // empty' "$law_json")

    if [[ -z "$hooks" ]]; then
        log_info "No hooks defined for law: $law_name"
        return 0
    fi

    # Install each hook
    for hook_type in $hooks; do
        # Strip carriage returns (Windows line endings)
        hook_type=$(echo "$hook_type" | tr -d '\r')

        local hook_category
        hook_category=$(get_hook_category "$hook_type")

        if [[ "$hook_category" == "unknown" ]]; then
            log_warn "Unknown hook type: $hook_type"
            continue
        fi

        # Skip git hooks if git is not available
        if [[ "$hook_category" == "git" ]] && ! can_install_git_hooks; then
            log_info "Git is not available, skipping git hook: $hook_type for law: $law_name"
            continue
        fi

        log_info "Installing $hook_category hook: $hook_type for law: $law_name"
        install_hook_template "$hook_type" "$hook_category"
    done

    return 0
}

# Uninstall all hooks for a law
uninstall_law_hooks() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    # Check if law exists
    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

    # Read hooks from law.json
    local law_json="$LAWS_DIR/$law_name/law.json"
    if [[ ! -f "$law_json" ]]; then
        log_error "law.json not found for: $law_name"
        return 1
    fi

    local hooks
    hooks=$(jq -r '.hooks[] // empty' "$law_json")

    if [[ -z "$hooks" ]]; then
        log_info "No hooks defined for law: $law_name"
        return 0
    fi

    # Uninstall each hook
    for hook_type in $hooks; do
        # Strip carriage returns (Windows line endings)
        hook_type=$(echo "$hook_type" | tr -d '\r')

        local hook_category
        hook_category=$(get_hook_category "$hook_type")

        if [[ "$hook_category" == "unknown" ]]; then
            log_warn "Unknown hook type: $hook_type"
            continue
        fi

        log_info "Uninstalling $hook_category hook: $hook_type for law: $law_name"
        uninstall_hook_template "$hook_type" "$hook_category"
    done

    return 0
}

# ============================================================================
# CATEGORY-SPECIFIC HELPER FUNCTIONS
# ============================================================================

# Install a git hook
_install_git_hook() {
    local hook_type="$1"

    # Check if git is installed
    if ! is_git_installed; then
        log_warn "Git is not installed, skipping git hook: $hook_type"
        return 0
    fi

    # Check if we're in a git repository
    if ! is_git_repository; then
        log_warn "Not in a git repository, skipping git hook: $hook_type"
        return 0
    fi

    local hook_dir=".git/hooks"
    local hook_file="$hook_dir/$hook_type"
    local template_file="$CHP_BASE/hooks/git/$hook_type.sh"

    # Check if template exists
    if [[ ! -f "$template_file" ]]; then
        log_warn "Template not found: $template_file"
        return 1
    fi

    # Create hook directory
    mkdir -p "$hook_dir"

    # Backup existing hook
    backup_existing_hook "$hook_file"

    # Copy template
    cp "$template_file" "$hook_file"

    # Make executable
    chmod +x "$hook_file"

    log_info "Installed git hook: $hook_file"
    return 0
}

# Uninstall a git hook
_uninstall_git_hook() {
    local hook_type="$1"
    local hook_file=".git/hooks/$hook_type"

    # Check if hook exists
    if [[ ! -f "$hook_file" ]]; then
        log_debug "Hook file does not exist: $hook_file"
        return 0
    fi

    # Check if hook is CHP-managed
    if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
        log_warn "Hook is not CHP-managed, skipping: $hook_file"
        return 0
    fi

    # Remove the hook
    rm -f "$hook_file"
    log_info "Uninstalled git hook: $hook_file"

    return 0
}

# Install an agent hook
_install_agent_hook() {
    local hook_type="$1"
    local hook_dir=".claude/hooks"
    local hook_file="$hook_dir/$hook_type"
    local template_file="$CHP_BASE/hooks/agent/$hook_type.sh"

    # Check if template exists
    if [[ ! -f "$template_file" ]]; then
        log_warn "Template not found: $template_file"
        return 1
    fi

    # Create hook directory
    mkdir -p "$hook_dir"

    # Backup existing hook
    backup_existing_hook "$hook_file"

    # Copy template
    cp "$template_file" "$hook_file"

    # Make executable
    chmod +x "$hook_file"

    log_info "Installed agent hook: $hook_file"
    return 0
}

# Uninstall an agent hook
_uninstall_agent_hook() {
    local hook_type="$1"
    local hook_file=".claude/hooks/$hook_type"

    # Check if hook exists
    if [[ ! -f "$hook_file" ]]; then
        log_debug "Hook file does not exist: $hook_file"
        return 0
    fi

    # Check if hook is CHP-managed
    if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
        log_warn "Hook is not CHP-managed, skipping: $hook_file"
        return 0
    fi

    # Remove the hook
    rm -f "$hook_file"
    log_info "Uninstalled agent hook: $hook_file"

    return 0
}

# Install a CI/CD hook
_install_cicd_hook() {
    local hook_type="$1"
    local hook_dir=".chp/cicd-hooks"
    local hook_file="$hook_dir/$hook_type"
    local template_file="$CHP_BASE/hooks/cicd/$hook_type.sh"

    # Check if template exists
    if [[ ! -f "$template_file" ]]; then
        log_warn "Template not found: $template_file"
        return 1
    fi

    # Create hook directory
    mkdir -p "$hook_dir"

    # Backup existing hook
    backup_existing_hook "$hook_file"

    # Copy template
    cp "$template_file" "$hook_file"

    # Make executable
    chmod +x "$hook_file"

    log_info "Installed CI/CD hook: $hook_file"
    return 0
}

# Uninstall a CI/CD hook
_uninstall_cicd_hook() {
    local hook_type="$1"
    local hook_file=".chp/cicd-hooks/$hook_type"

    # Check if hook exists
    if [[ ! -f "$hook_file" ]]; then
        log_debug "Hook file does not exist: $hook_file"
        return 0
    fi

    # Check if hook is CHP-managed
    if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
        log_warn "Hook is not CHP-managed, skipping: $hook_file"
        return 0
    fi

    # Remove the hook
    rm -f "$hook_file"
    log_info "Uninstalled CI/CD hook: $hook_file"

    return 0
}

# ============================================================================
# CLAUDE CODE SETTINGS HOOKS
# ============================================================================

# Ensure a wrapper script exists in .claude/hooks/
# Args: hook_type (pre-tool or post-tool)
_ensure_wrapper_script() {
    local hook_type="$1"
    local wrapper_name="${hook_type}-wrapper.sh"
    local hooks_dir=".claude/hooks"
    local wrapper_path="$hooks_dir/$wrapper_name"
    local dispatcher_arg="$hook_type"

    mkdir -p "$hooks_dir"

    if [[ -f "$wrapper_path" ]]; then
        log_debug "Wrapper already exists: $wrapper_path"
        return 0
    fi

    cat > "$wrapper_path" << 'WRAPPER'
#!/bin/bash
# CHP __HOOK_TYPE__ Hook Wrapper
# Reads JSON input from Claude Code harness and calls the CHP dispatcher

HOOK_INPUT=$(cat)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$HOOK_INPUT" | jq -r '.tool_input.content // empty')
WRAPPER

    # Add tool_output extraction for post-tool
    if [[ "$hook_type" == "post-tool" ]]; then
        cat >> "$wrapper_path" << 'EXTRA'
TOOL_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_output // empty')
EXTRA
    fi

    cat >> "$wrapper_path" << 'WRAPPER2'

export CHP_HOOK_TYPE="__HOOK_TYPE__"
export CHP_TOOL_NAME="$TOOL_NAME"
export CHP_FILE_PATH="$FILE_PATH"
export CHP_CONTENT="$CONTENT"
WRAPPER2

    if [[ "$hook_type" == "post-tool" ]]; then
        cat >> "$wrapper_path" << 'EXTRA2'
export CHP_TOOL_OUTPUT="$TOOL_OUTPUT"
EXTRA2
    fi

    cat >> "$wrapper_path" << 'WRAPPER3'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

exec "$PROJECT_ROOT/core/dispatcher.sh" __HOOK_TYPE__ "$TOOL_NAME" "$FILE_PATH" "$CONTENT"
WRAPPER3

    # Replace placeholders
    sed -i "s/__HOOK_TYPE__/$hook_type/g" "$wrapper_path"
    chmod +x "$wrapper_path"

    log_info "Created wrapper script: $wrapper_path"
}

# Configure Claude Code settings.json with PreToolUse and PostToolUse hooks
install_claude_hooks() {
    local settings_file=".claude/settings.json"

    # Check for jq
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required to configure Claude Code hooks"
        return 1
    fi

    # Ensure .claude directory exists
    mkdir -p .claude

    # Create settings.json if it doesn't exist
    if [[ ! -f "$settings_file" ]]; then
        echo '{}' > "$settings_file"
        log_info "Created $settings_file"
    fi

    # Ensure wrapper scripts exist
    _ensure_wrapper_script "pre-tool"
    _ensure_wrapper_script "post-tool"

    # Build the hooks configuration
    local tmp_file
    tmp_file=$(mktemp)

    # Use jq to add/update hooks in settings.json
    jq '
        .hooks = (.hooks // {}) |
        .hooks.PreToolUse = [{
            matcher: "Write|Edit",
            hooks: [{
                type: "command",
                command: "bash .claude/hooks/pre-tool-wrapper.sh"
            }]
        }] |
        .hooks.PostToolUse = [{
            matcher: "Write|Edit",
            hooks: [{
                type: "command",
                command: "bash .claude/hooks/post-tool-wrapper.sh"
            }]
        }]
    ' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"

    log_info "Configured PreToolUse and PostToolUse hooks in $settings_file"
    return 0
}

# Remove Claude Code hooks from settings.json
uninstall_claude_hooks() {
    local settings_file=".claude/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        log_debug "No settings.json found, nothing to uninstall"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required to update settings.json"
        return 1
    fi

    local tmp_file
    tmp_file=$(mktemp)

    # Remove PreToolUse and PostToolUse entries
    jq 'del(.hooks.PreToolUse) | del(.hooks.PostToolUse)' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"

    log_info "Removed Claude Code hooks from $settings_file"

    # Clean up wrapper scripts
    rm -f ".claude/hooks/pre-tool-wrapper.sh"
    rm -f ".claude/hooks/post-tool-wrapper.sh"

    return 0
}
