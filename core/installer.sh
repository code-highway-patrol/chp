#!/bin/bash
# Hook installation and management for CHP laws

# Marker to identify CHP-managed hooks
readonly CHP_MANAGED_MARKER="# CHP-MANAGED: Do not edit this line"

# Install a hook for a law
install_hook() {
    local law_name="$1"
    local hook_type="$2"

    if [[ -z "$law_name" ]]; then
        error "Law name is required"
        return 1
    fi

    if [[ -z "$hook_type" ]]; then
        error "Hook type is required"
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
            info "Backed up existing hook to $backup_file"
        fi
    fi

    # Create or update the hook file
    {
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
    info "Installed hook: $hook_file for law: $law_name"

    return 0
}

# Uninstall a hook for a law
uninstall_hook() {
    local law_name="$1"
    local hook_type="$2"

    if [[ -z "$law_name" ]]; then
        error "Law name is required"
        return 1
    fi

    if [[ -z "$hook_type" ]]; then
        error "Hook type is required"
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
        warn "Hook file does not exist: $hook_file"
        return 0
    fi

    # Check if hook is CHP-managed
    if ! grep -q "$CHP_MANAGED_MARKER" "$hook_file"; then
        warn "Hook is not CHP-managed, skipping: $hook_file"
        return 0
    fi

    # Check if hook contains the law
    if ! grep -q "# CHP Law: $law_name" "$hook_file"; then
        warn "Hook does not contain law: $law_name"
        return 0
    fi

    # Remove the hook file
    rm -f "$hook_file"
    info "Uninstalled hook: $hook_file for law: $law_name"

    return 0
}
