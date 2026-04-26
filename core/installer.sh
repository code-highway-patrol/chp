#!/usr/bin/env bash
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
        echo "# Resolve CHP_BASE: env var, then settings.json, then relative fallback"
        echo "if [[ -n \"\$CHP_BASE\" ]]; then"
        echo "    : # CHP_BASE already set"
        echo "elif [[ -f \"\$HOME/.claude/settings.json\" ]]; then"
        echo "    CHP_BASE=\$(jq -r '.extraKnownMarketplaces[\"chp-local\"].source.path // empty' \"\$HOME/.claude/settings.json\" 2>/dev/null)"
        echo "fi"
        echo ""
        echo "# Final fallback to relative path"
        echo "if [[ -z \"\$CHP_BASE\" ]] || [[ ! -f \"\$CHP_BASE/core/dispatcher.sh\" ]]; then"
        echo "    SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\""
        echo "    PROJECT_ROOT=\"\$(cd \"\$SCRIPT_DIR/../..\" && pwd)\""
        echo "    if [[ -f \"\$PROJECT_ROOT/core/dispatcher.sh\" ]]; then"
        echo "        CHP_BASE=\"\$PROJECT_ROOT\""
        echo "    fi"
        echo "fi"
        echo ""
        echo "if [[ -z \"\$CHP_BASE\" ]] || [[ ! -f \"\$CHP_BASE/core/dispatcher.sh\" ]]; then"
        echo "    echo \"Error: Cannot find CHP dispatcher (core/dispatcher.sh)\" >&2"
        echo "    exit 1"
        echo "fi"
        echo ""
        echo "exec \"\$CHP_BASE/core/dispatcher.sh\" $hook_type \"\$@\""
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

# Resolve CHP_BASE: env var, then settings.json, then relative fallback
if [[ -n "$CHP_BASE" ]]; then
    : # CHP_BASE already set
elif [[ -f "$HOME/.claude/settings.json" ]]; then
    CHP_BASE=$(jq -r '.extraKnownMarketplaces["chp-local"].source.path // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi

# Final fallback to relative path (only works if CHP core is in project root)
if [[ -z "$CHP_BASE" ]] || [[ ! -f "$CHP_BASE/core/dispatcher.sh" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    if [[ -f "$PROJECT_ROOT/core/dispatcher.sh" ]]; then
        CHP_BASE="$PROJECT_ROOT"
    fi
fi

if [[ -z "$CHP_BASE" ]] || [[ ! -f "$CHP_BASE/core/dispatcher.sh" ]]; then
    echo "Error: Cannot find CHP dispatcher (core/dispatcher.sh)" >&2
    echo "Set CHP_BASE environment variable or ensure CHP is installed" >&2
    exit 1
fi

exec "$CHP_BASE/core/dispatcher.sh" __HOOK_TYPE__ "$TOOL_NAME" "$FILE_PATH" "$CONTENT"
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

# Codex Hooks

readonly CODEX_HOOKS_MARKER="# CHP-MANAGED-START"
readonly CODEX_HOOKS_END_MARKER="# CHP-MANAGED-END"

can_install_codex_hooks() {
    command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1
}

install_codex_hooks() {
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required to install Codex hooks"
        return 1
    fi

    local codex_dir=".codex"
    local codex_hooks_dir="$codex_dir/hooks"
    local config_file="$codex_dir/config.toml"
    local bridge_template="$CHP_BASE/hooks/codex/bridge.sh"
    local config_template="$CHP_BASE/hooks/codex/config.toml"

    if [[ ! -f "$bridge_template" ]]; then
        log_error "Codex bridge template not found: $bridge_template"
        return 1
    fi

    mkdir -p "$codex_hooks_dir"

    # Install bridge script
    cp "$bridge_template" "$codex_hooks_dir/chp-bridge.sh"
    chmod +x "$codex_hooks_dir/chp-bridge.sh"
    log_info "Installed Codex bridge: $codex_hooks_dir/chp-bridge.sh"

    # Install config.toml
    if [[ -f "$config_file" ]]; then
        # Remove existing CHP-managed section if present
        if grep -q "$CODEX_HOOKS_MARKER" "$config_file"; then
            local tmp_file
            tmp_file=$(mktemp)
            sed "/$CODEX_HOOKS_MARKER/,/$CODEX_HOOKS_END_MARKER/d" "$config_file" > "$tmp_file"
            # Remove trailing empty lines
            sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp_file" > "$config_file"
            rm -f "$tmp_file"
            echo "" >> "$config_file"
        else
            echo "" >> "$config_file"
        fi
        cat "$config_template" >> "$config_file"
        log_info "Updated existing Codex config: $config_file"
    else
        cp "$config_template" "$config_file"
        log_info "Created Codex config: $config_file"
    fi

    return 0
}

uninstall_codex_hooks() {
    local codex_dir=".codex"
    local bridge_file="$codex_dir/hooks/chp-bridge.sh"
    local config_file="$codex_dir/config.toml"

    # Remove bridge script
    if [[ -f "$bridge_file" ]]; then
        rm -f "$bridge_file"
        log_info "Removed Codex bridge: $bridge_file"
    fi

    # Remove CHP section from config.toml
    if [[ -f "$config_file" ]] && grep -q "$CODEX_HOOKS_MARKER" "$config_file"; then
        local tmp_file
        tmp_file=$(mktemp)
        sed "/$CODEX_HOOKS_MARKER/,/$CODEX_HOOKS_END_MARKER/d" "$config_file" > "$tmp_file"
        # Clean up: if only comments/whitespace remain, remove the file
        local remaining
        remaining=$(grep -v '^\s*#' "$tmp_file" | grep -v '^\s*$' | tr -d '[:space:]')
        if [[ -z "$remaining" ]]; then
            rm -f "$config_file"
            log_info "Removed empty Codex config: $config_file"
        else
            cp "$tmp_file" "$config_file"
            log_info "Removed CHP hooks from Codex config: $config_file"
        fi
        rm -f "$tmp_file"
    fi

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
            # For agent hooks, also check wrapper scripts exist
            if [[ "$hook_type" == "pre-tool" ]] || [[ "$hook_type" == "post-tool" ]]; then
                local wrapper="${hook_type}-wrapper.sh"
                [[ -f ".claude/hooks/$hook_type" ]] && [[ -f ".claude/hooks/$wrapper" ]]
            else
                [[ -f ".claude/hooks/$hook_type" ]]
            fi
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

    # Check if wrapper files exist (not just settings.json config)
    local pre_wrapper=".claude/hooks/pre-tool-wrapper.sh"
    local post_wrapper=".claude/hooks/post-tool-wrapper.sh"

    if [[ -f "$pre_wrapper" ]] && [[ -f "$post_wrapper" ]]; then
        if jq -e '.hooks.PreToolUse' "$settings_file" >/dev/null 2>&1; then
            log_debug "Claude Code hooks already configured and wrappers exist"
            return 0
        fi
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
            # Reinstall to pick up template changes
            log_debug "Hook already installed, updating: $hook_type ($hook_category)"
            install_hook_template "$hook_type" "$hook_category" >/dev/null 2>&1 || true
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

    # Store sync state for future change detection
    _store_sync_state

    return 0
}

# Check if hooks should be ensured (avoid running on every status call)
# Only ensures if:
# 1. .claude/hooks doesn't exist OR
# 2. Wrapper scripts are missing OR
# 3. .claude/settings.json exists but has no hooks configured
# 4. Laws or registry were modified since last sync
# 5. Plugin version changed
_should_ensure_hooks() {
    local stamp_file=".claude/.chp-hooks-synced"
    local state_file=".claude/.chp-state"

    # Initialize registry to check current state
    init_hook_registry >/dev/null 2>&1 || true

    # Get current state hash
    local current_hash=""
    local needs_sync=false

    # 1. Check if wrapper scripts exist
    local pre_wrapper=".claude/hooks/pre-tool-wrapper.sh"
    local post_wrapper=".claude/hooks/post-tool-wrapper.sh"

    if [[ ! -f "$pre_wrapper" ]] || [[ ! -f "$post_wrapper" ]]; then
        # Wrappers missing, should ensure
        return 0
    fi

    # 2. Check if any registered hook files are missing
    local registered_hooks
    registered_hooks=$(jq -r '.hooks | keys[]' "$HOOK_REGISTRY" 2>/dev/null)
    if [[ -n "$registered_hooks" ]]; then
        while IFS= read -r hook_type; do
            hook_type=$(echo "$hook_type" | tr -d '\r')
            [[ -z "$hook_type" ]] && continue

            local hook_category
            hook_category=$(get_hook_category "$hook_type")

            if ! _is_hook_installed "$hook_type" "$hook_category"; then
                # Hook file missing, should ensure
                return 0
            fi
        done <<< "$registered_hooks"
    fi

    # 3. Compute current state hash
    if command -v jq >/dev/null 2>&1 && [[ -f "$HOOK_REGISTRY" ]]; then
        # Hash of registry + all law.json files + plugin version
        local registry_hash
        local laws_hash
        local plugin_version="1.0.0"

        # Hash the registry
        registry_hash=$(jq -c '.' "$HOOK_REGISTRY" 2>/dev/null | md5sum | cut -d' ' -f1)

        # Hash all law.json files (sorted for consistency)
        if [[ -d "$LAWS_DIR" ]]; then
            laws_hash=$(find "$LAWS_DIR" -name "law.json" -type f -exec cat {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1)
        else
            laws_hash=$(echo "$LAWS_DIR" | md5sum | cut -d' ' -f1)
        fi

        # Get plugin version from package.json if available
        local plugin_package="$CHP_BASE/package.json"
        if [[ -f "$plugin_package" ]]; then
            plugin_version=$(jq -r '.version // "1.0.0"' "$plugin_package" 2>/dev/null)
        fi

        current_hash="${registry_hash}-${laws_hash}-${plugin_version}"
    fi

    # 4. Compare with stored state
    if [[ -f "$state_file" ]]; then
        local stored_hash
        stored_hash=$(cat "$state_file" 2>/dev/null)

        if [[ "$current_hash" != "$stored_hash" ]]; then
            # State changed, should ensure
            return 0
        fi
    else
        # No state file, first run
        return 0
    fi

    # 5. Check stamp age (re-sync at least once per day even if no changes)
    if [[ -f "$stamp_file" ]]; then
        local stamp_age=$(($(date +%s) - $(stat -c %Y "$stamp_file" 2>/dev/null || stat -f %m "$stamp_file")))
        # Re-sync if older than 24 hours
        if [[ $stamp_age -gt 86400 ]]; then
            return 0
        fi
    fi

    # Everything in sync, skip
    return 1
}

# Store the current state after successful ensure
_store_sync_state() {
    local state_file=".claude/.chp-state"
    local stamp_file=".claude/.chp-hooks-synced"

    # Compute current state hash
    local current_hash=""
    if command -v jq >/dev/null 2>&1 && [[ -f "$HOOK_REGISTRY" ]]; then
        local registry_hash
        local laws_hash
        local plugin_version="1.0.0"

        registry_hash=$(jq -c '.' "$HOOK_REGISTRY" 2>/dev/null | md5sum | cut -d' ' -f1)

        if [[ -d "$LAWS_DIR" ]]; then
            laws_hash=$(find "$LAWS_DIR" -name "law.json" -type f -exec cat {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1)
        else
            laws_hash=$(echo "$LAWS_DIR" | md5sum | cut -d' ' -f1)
        fi

        local plugin_package="$CHP_BASE/package.json"
        if [[ -f "$plugin_package" ]]; then
            plugin_version=$(jq -r '.version // "1.0.0"' "$plugin_package" 2>/dev/null)
        fi

        current_hash="${registry_hash}-${laws_hash}-${plugin_version}"
    fi

    # Store state
    mkdir -p ".claude"
    echo "$current_hash" > "$state_file"
    touch "$stamp_file"
}
