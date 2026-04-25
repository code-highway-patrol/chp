#!/bin/bash
# Hook Registry - Manages hook type to law mappings
#
# This module provides functions to register and manage which laws should be
# executed when specific hook types are triggered.

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly." >&2
    echo "Usage: source core/hook-registry.sh" >&2
    exit 1
fi

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Registry file location
HOOK_REGISTRY="${HOOK_REGISTRY:-$CHP_BASE/.chp/hook-registry.json}"

# Initialize the hook registry with default structure
init_hook_registry() {
    log_debug "Initializing hook registry at $HOOK_REGISTRY"

    # Create .chp directory if it doesn't exist
    local chp_dir="$(dirname "$HOOK_REGISTRY")"
    if [ ! -d "$chp_dir" ]; then
        mkdir -p "$chp_dir"
        log_debug "Created .chp directory at $chp_dir"
    fi

    # If registry already exists, don't overwrite
    if [ -f "$HOOK_REGISTRY" ]; then
        log_debug "Registry already exists, skipping initialization"
        return 0
    fi

    # Create default registry structure
    cat > "$HOOK_REGISTRY" << 'EOF'
{
  "hooks": {},
  "version": "1.0"
}
EOF

    log_debug "Hook registry initialized successfully"
}

# Force reinitialize the hook registry (overwrite existing)
_init_hook_registry_force() {
    log_debug "Force reinitializing hook registry at $HOOK_REGISTRY"

    # Create .chp directory if it doesn't exist
    local chp_dir="$(dirname "$HOOK_REGISTRY")"
    if [ ! -d "$chp_dir" ]; then
        mkdir -p "$chp_dir"
        log_debug "Created .chp directory at $chp_dir"
    fi

    # Create default registry structure (overwrite existing)
    cat > "$HOOK_REGISTRY" <<'EOF'
{
  "hooks": {},
  "version": "1.0"
}
EOF

    log_debug "Hook registry force reinitialized successfully"
}

# Ensure registry exists (private function)
_ensure_registry() {
    if [ ! -f "$HOOK_REGISTRY" ]; then
        log_debug "Registry not found, initializing"
        init_hook_registry
    fi
}

# Register a law to a hook type
register_hook_law() {
    local hook_type="$1"
    local law_name="$2"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        return 1
    fi

    if [ -z "$law_name" ]; then
        log_error "Law name cannot be empty"
        return 1
    fi

    log_debug "Registering law '$law_name' to hook '$hook_type'"

    _ensure_registry

    # Check if law already registered, avoid duplicates
    local existing_laws
    existing_laws=$(jq -r ".hooks[\"$hook_type\"].laws // []" "$HOOK_REGISTRY")
    if [ "$existing_laws" != "[]" ] && echo "$existing_laws" | grep -q "\"$law_name\""; then
        log_debug "Law '$law_name' already registered to hook '$hook_type', skipping"
        return 0
    fi

    # Add law to hook type using temp file pattern
    local tmp_file="${HOOK_REGISTRY}.tmp"
    jq ".hooks[\"$hook_type\"].laws |= . + [\"$law_name\"] | \
        .hooks[\"$hook_type\"].enabled |= true | \
        .hooks[\"$hook_type\"].blocking |= true" "$HOOK_REGISTRY" > "$tmp_file" && \
    mv "$tmp_file" "$HOOK_REGISTRY"

    log_debug "Law '$law_name' registered to hook '$hook_type'"
}

# Unregister a law from a hook type
unregister_hook_law() {
    local hook_type="$1"
    local law_name="$2"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        return 1
    fi

    if [ -z "$law_name" ]; then
        log_error "Law name cannot be empty"
        return 1
    fi

    log_debug "Unregistering law '$law_name' from hook '$hook_type'"

    _ensure_registry

    # Remove law from hook type using temp file pattern
    local tmp_file="${HOOK_REGISTRY}.tmp"
    jq ".hooks[\"$hook_type\"].laws |= map(select(. != \"$law_name\"))" "$HOOK_REGISTRY" > "$tmp_file" && \
    mv "$tmp_file" "$HOOK_REGISTRY"

    log_debug "Law '$law_name' unregistered from hook '$hook_type'"
}

# Get all laws registered for a hook type
get_hook_laws() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        echo "[]"
        return 1
    fi

    log_debug "Getting laws for hook '$hook_type'"

    _ensure_registry

    local laws
    laws=$(jq -r ".hooks[\"$hook_type\"].laws // []" "$HOOK_REGISTRY")
    echo "$laws"
}

# Check if hook is blocking (returns exit code 0=blocking, 1=non-blocking)
is_hook_blocking() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        return 1
    fi

    log_debug "Checking if hook '$hook_type' is blocking"

    _ensure_registry

    local blocking
    # Check if the hook has a blocking field, default to true if not
    local has_blocking
    has_blocking=$(jq ".hooks[\"$hook_type\"] | has(\"blocking\")" "$HOOK_REGISTRY" 2>/dev/null)

    if [ "$?" != "0" ] || [ "$has_blocking" != "true" ]; then
        blocking="true"
    else
        blocking=$(jq -r ".hooks[\"$hook_type\"].blocking" "$HOOK_REGISTRY")
    fi

    if [ "$blocking" = "true" ]; then
        return 0  # Exit code 0 = true in shell
    else
        return 1  # Exit code 1 = false in shell
    fi
}

# Check if hook is enabled (returns exit code 0=enabled, 1=disabled)
is_hook_enabled() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        return 1
    fi

    log_debug "Checking if hook '$hook_type' is enabled"

    _ensure_registry

    local enabled
    # Check if the hook has an enabled field, default to true if not
    local has_enabled
    has_enabled=$(jq ".hooks[\"$hook_type\"] | has(\"enabled\")" "$HOOK_REGISTRY" 2>/dev/null)

    if [ "$?" != "0" ] || [ "$has_enabled" != "true" ]; then
        enabled="true"
    else
        enabled=$(jq -r ".hooks[\"$hook_type\"].enabled" "$HOOK_REGISTRY")
    fi

    if [ "$enabled" = "true" ]; then
        return 0  # Exit code 0 = true in shell
    else
        return 1  # Exit code 1 = false in shell
    fi
}

# Set blocking behavior for a hook type
set_hook_blocking() {
    local hook_type="$1"
    local blocking="$2"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        return 1
    fi

    if [ -z "$blocking" ]; then
        log_error "Blocking value cannot be empty"
        return 1
    fi

    log_debug "Setting hook '$hook_type' blocking to $blocking"

    _ensure_registry

    # Normalize boolean input
    if [ "$blocking" = "true" ] || [ "$blocking" = "1" ] || [ "$blocking" = "yes" ]; then
        blocking="true"
    else
        blocking="false"
    fi

    # Update blocking setting using temp file pattern
    local tmp_file="${HOOK_REGISTRY}.tmp"
    jq ".hooks[\"$hook_type\"].blocking |= $blocking" "$HOOK_REGISTRY" > "$tmp_file" && \
    mv "$tmp_file" "$HOOK_REGISTRY" || {
        log_error "Failed to update blocking setting"
        rm -f "$tmp_file"
        return 1
    }

    log_debug "Hook '$hook_type' blocking set to $blocking"
}

# Set enabled state for a hook type
set_hook_enabled() {
    local hook_type="$1"
    local enabled="$2"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        return 1
    fi

    if [ -z "$enabled" ]; then
        log_error "Enabled value cannot be empty"
        return 1
    fi

    log_debug "Setting hook '$hook_type' enabled to $enabled"

    _ensure_registry

    # Normalize boolean input
    if [ "$enabled" = "true" ] || [ "$enabled" = "1" ] || [ "$enabled" = "yes" ]; then
        enabled="true"
    else
        enabled="false"
    fi

    # Update enabled setting using temp file pattern
    local tmp_file="${HOOK_REGISTRY}.tmp"
    jq ".hooks[\"$hook_type\"].enabled |= $enabled" "$HOOK_REGISTRY" > "$tmp_file" && \
    mv "$tmp_file" "$HOOK_REGISTRY" || {
        log_error "Failed to update enabled setting"
        rm -f "$tmp_file"
        return 1
    }

    log_debug "Hook '$hook_type' enabled set to $enabled"
}

# List all registered hooks with metadata
list_hooks() {
    log_debug "Listing all registered hooks"

    _ensure_registry

    local hooks
    hooks=$(jq '.hooks | to_entries | map({
        type: .key,
        laws: .value.laws,
        enabled: .value.enabled,
        blocking: .value.blocking
    })' "$HOOK_REGISTRY")

    echo "$hooks"
}
