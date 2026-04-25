#!/bin/bash
# Hook installation and management for CHP laws

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/detector.sh"

# Marker to identify CHP-managed hooks
readonly CHP_MANAGED_MARKER="# CHP-MANAGED"

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
        # Git hook
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
