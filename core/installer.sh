#!/bin/bash
# Hook installation and management for CHP laws

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detector.sh"

readonly CHP_MANAGED_MARKER="# CHP-MANAGED"

is_git_installed() {
    command -v git >/dev/null 2>&1
}

is_git_repository() {
    git rev-parse --git-dir >/dev/null 2>&1
}

can_install_git_hooks() {
    is_git_installed && is_git_repository
}

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

    local hook_dir
    local hook_file

    if [[ "$hook_type" == "pre-write" ]]; then
        hook_dir=".git/pretool/hooks"
        hook_file="$hook_dir/pre-write"
    else
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

    mkdir -p "$hook_dir"

    if [[ -f "$hook_file" ]]; then
        if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
            local backup_file="${hook_file}.backup.$(date +%s)"
            cp "$hook_file" "$backup_file"
            log_info "Backed up existing hook to $backup_file"
        fi
    fi

    {
        echo "#!/bin/bash"
        echo "$CHP_MANAGED_MARKER"
        echo "# CHP Law: $law_name"
        echo "# Hook type: $hook_type"
        echo ""
        echo "SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\""
        echo "PROJECT_ROOT=\"\$(cd \"\$SCRIPT_DIR/../..\" && pwd)\""
        echo "exec \"\$PROJECT_ROOT/core/dispatcher.sh\" $hook_type \"\$@\""
    } > "$hook_file"

    chmod +x "$hook_file"
    log_info "Installed hook: $hook_file for law: $law_name"

    return 0
}

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

    local hook_dir
    local hook_file

    if [[ "$hook_type" == "pre-write" ]]; then
        hook_dir=".git/pretool/hooks"
        hook_file="$hook_dir/pre-write"
    else
        hook_dir=".git/hooks"
        hook_file="$hook_dir/$hook_type"
    fi

    if [[ ! -f "$hook_file" ]]; then
        log_warn "Hook file does not exist: $hook_file"
        return 0
    fi

    if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
        log_warn "Hook is not CHP-managed, skipping: $hook_file"
        return 0
    fi

    if ! grep -q "# CHP Law: $law_name" "$hook_file"; then
        log_warn "Hook does not contain law: $law_name"
        return 0
    fi

    rm -f "$hook_file"
    log_info "Uninstalled hook: $hook_file for law: $law_name"

    return 0
}

# Universal Hook Installation

backup_existing_hook() {
    local hook_path="$1"

    if [[ -z "$hook_path" ]]; then
        log_error "Hook path is required"
        return 1
    fi

    if [[ ! -f "$hook_path" ]]; then
        log_debug "No existing hook to backup: $hook_path"
        return 0
    fi

    if grep -q "$CHP_MANAGED_MARKER" "$hook_path"; then
        log_debug "CHP-managed hook, skipping backup: $hook_path"
        return 0
    fi

    local backup_file="${hook_path}.chp-backup-$(date +%s)"
    cp "$hook_path" "$backup_file"
    log_info "Backed up existing hook to $backup_file"

    return 0
}

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

    case "$hook_category" in
        git)
            _install_git_hook "$hook_type"
            ;;
        agent)
            _install_agent_hook "$hook_type"
            ;;
        *)
            log_error "Unknown hook category: $hook_category"
            return 1
            ;;
    esac
}

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

    case "$hook_category" in
        git)
            _uninstall_git_hook "$hook_type"
            ;;
        agent)
            _uninstall_agent_hook "$hook_type"
            ;;
        *)
            log_error "Unknown hook category: $hook_category"
            return 1
            ;;
    esac
}

install_law_hooks() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

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

    for hook_type in $hooks; do
        hook_type=$(echo "$hook_type" | tr -d '\r')

        local hook_category
        hook_category=$(get_hook_category "$hook_type")

        if [[ "$hook_category" == "unknown" ]]; then
            log_warn "Unknown hook type: $hook_type"
            continue
        fi

        if [[ "$hook_category" == "git" ]] && ! can_install_git_hooks; then
            log_info "Git is not available, skipping git hook: $hook_type for law: $law_name"
            continue
        fi

        log_info "Installing $hook_category hook: $hook_type for law: $law_name"
        install_hook_template "$hook_type" "$hook_category"
    done

    return 0
}

uninstall_law_hooks() {
    local law_name="$1"

    if [[ -z "$law_name" ]]; then
        log_error "Law name is required"
        return 1
    fi

    if ! law_exists "$law_name"; then
        log_error "Law does not exist: $law_name"
        return 1
    fi

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

    for hook_type in $hooks; do
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

# Category-specific helpers

_install_git_hook() {
    local hook_type="$1"

    if ! is_git_installed; then
        log_warn "Git is not installed, skipping git hook: $hook_type"
        return 0
    fi

    if ! is_git_repository; then
        log_warn "Not in a git repository, skipping git hook: $hook_type"
        return 0
    fi

    local hook_dir=".git/hooks"
    local hook_file="$hook_dir/$hook_type"
    local template_file="$CHP_BASE/hooks/git/$hook_type.sh"

    if [[ ! -f "$template_file" ]]; then
        log_warn "Template not found: $template_file"
        return 1
    fi

    mkdir -p "$hook_dir"
    backup_existing_hook "$hook_file"
    cp "$template_file" "$hook_file"
    chmod +x "$hook_file"

    log_info "Installed git hook: $hook_file"
    return 0
}

_uninstall_git_hook() {
    local hook_type="$1"
    local hook_file=".git/hooks/$hook_type"

    if [[ ! -f "$hook_file" ]]; then
        log_debug "Hook file does not exist: $hook_file"
        return 0
    fi

    if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
        log_warn "Hook is not CHP-managed, skipping: $hook_file"
        return 0
    fi

    rm -f "$hook_file"
    log_info "Uninstalled git hook: $hook_file"

    return 0
}

_install_agent_hook() {
    local hook_type="$1"
    local hook_dir=".claude/hooks"
    local hook_file="$hook_dir/$hook_type"
    local template_file="$CHP_BASE/hooks/agent/$hook_type.sh"

    if [[ ! -f "$template_file" ]]; then
        log_warn "Template not found: $template_file"
        return 1
    fi

    mkdir -p "$hook_dir"
    backup_existing_hook "$hook_file"
    cp "$template_file" "$hook_file"
    chmod +x "$hook_file"

    log_info "Installed agent hook: $hook_file"
    return 0
}

_uninstall_agent_hook() {
    local hook_type="$1"
    local hook_file=".claude/hooks/$hook_type"

    if [[ ! -f "$hook_file" ]]; then
        log_debug "Hook file does not exist: $hook_file"
        return 0
    fi

    if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
        log_warn "Hook is not CHP-managed, skipping: $hook_file"
        return 0
    fi

    rm -f "$hook_file"
    log_info "Uninstalled agent hook: $hook_file"

    return 0
}

# Claude Code Settings Hooks

# Args: hook_type (pre-tool or post-tool)
_ensure_wrapper_script() {
    local hook_type="$1"
    local wrapper_name="${hook_type}-wrapper.sh"
    local hooks_dir=".claude/hooks"
    local wrapper_path="$hooks_dir/$wrapper_name"

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

    sed -i "s/__HOOK_TYPE__/$hook_type/g" "$wrapper_path"
    chmod +x "$wrapper_path"

    log_info "Created wrapper script: $wrapper_path"
}

install_claude_hooks() {
    local settings_file=".claude/settings.json"

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required to configure Claude Code hooks"
        return 1
    fi

    mkdir -p .claude

    if [[ ! -f "$settings_file" ]]; then
        echo '{}' > "$settings_file"
        log_info "Created $settings_file"
    fi

    _ensure_wrapper_script "pre-tool"
    _ensure_wrapper_script "post-tool"

    local tmp_file
    tmp_file=$(mktemp)

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

    jq 'del(.hooks.PreToolUse) | del(.hooks.PostToolUse)' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"

    log_info "Removed Claude Code hooks from $settings_file"

    rm -f ".claude/hooks/pre-tool-wrapper.sh"
    rm -f ".claude/hooks/post-tool-wrapper.sh"

    return 0
}

# Hook Ensure / Sync

# Check if a hook file is already installed at its expected location
_is_hook_installed() {
    local hook_type="$1"
    local hook_category="$2"

    case "$hook_category" in
        git)
            [[ -f ".git/hooks/$hook_type" ]]
            ;;
        agent)
            [[ -f ".claude/hooks/$hook_type" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Ensure Claude Code settings.json has hooks configured
_ensure_claude_settings() {
    local settings_file=".claude/settings.json"

    if [[ ! -f "$settings_file" ]]; then
        mkdir -p .claude
        echo '{}' > "$settings_file"
        log_info "Created $settings_file"
    fi

    if jq -e '.hooks.PreToolUse' "$settings_file" >/dev/null 2>&1; then
        log_debug "Claude Code hooks already configured in settings.json"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq is required to configure Claude Code agent hooks"
        return 1
    fi

    _ensure_wrapper_script "pre-tool"
    _ensure_wrapper_script "post-tool"

    local tmp_file
    tmp_file=$(mktemp)

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

    log_info "Configured Claude Code hooks in $settings_file"
    return 0
}

# Ensure all registered hooks have their files installed.
# Reads the registry and installs any missing hook templates.
# Requires: hook-registry.sh and detector.sh to be sourced by the caller.
ensure_hooks_installed() {
    _ensure_registry

    local registered_hooks
    registered_hooks=$(jq -r '.hooks | keys[]' "$HOOK_REGISTRY" 2>/dev/null)

    if [[ -z "$registered_hooks" ]]; then
        log_debug "No hooks registered, nothing to ensure"
        return 0
    fi

    local installed=0
    local needs_claude_settings=false

    while IFS= read -r hook_type; do
        hook_type=$(echo "$hook_type" | tr -d '\r')
        [[ -z "$hook_type" ]] && continue

        local hook_category
        hook_category=$(get_hook_category "$hook_type")

        if [[ "$hook_category" == "unknown" ]]; then
            log_warn "Unknown hook type in registry: $hook_type"
            continue
        fi

        if _is_hook_installed "$hook_type" "$hook_category"; then
            log_debug "Hook already installed: $hook_type ($hook_category)"
            continue
        fi

        log_info "Hook missing, installing: $hook_type ($hook_category)"
        if install_hook_template "$hook_type" "$hook_category"; then
            installed=$((installed + 1))
        else
            log_warn "Failed to install hook: $hook_type ($hook_category)"
        fi

        if [[ "$hook_category" == "agent" ]]; then
            needs_claude_settings=true
        fi
    done <<< "$registered_hooks"

    if [[ "$needs_claude_settings" == true ]]; then
        _ensure_claude_settings
    fi

    if [[ $installed -gt 0 ]]; then
        log_info "Ensured $installed hook(s) installed"
    else
        log_info "All registered hooks already installed"
    fi

    return 0
}
