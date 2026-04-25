#!/usr/bin/env bash
# Hook Registry - Manages hook type to law mappings

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This file should be sourced, not executed directly." >&2
    echo "Usage: source core/hook-registry.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

HOOK_REGISTRY="${HOOK_REGISTRY:-$CHP_BASE/.chp/hook-registry.json}"

init_hook_registry() {
    log_debug "Initializing hook registry at $HOOK_REGISTRY"

    local chp_dir="$(dirname "$HOOK_REGISTRY")"
    if [ ! -d "$chp_dir" ]; then
        mkdir -p "$chp_dir"
        log_debug "Created .chp directory at $chp_dir"
    fi

    if [ -f "$HOOK_REGISTRY" ]; then
        log_debug "Registry already exists, skipping initialization"
        return 0
    fi

    cat > "$HOOK_REGISTRY" << 'EOF'
{
  "hooks": {},
  "version": "1.0"
}
EOF

    log_debug "Hook registry initialized successfully"
}

_init_hook_registry_force() {
    log_debug "Force reinitializing hook registry at $HOOK_REGISTRY"

    local chp_dir="$(dirname "$HOOK_REGISTRY")"
    if [ ! -d "$chp_dir" ]; then
        mkdir -p "$chp_dir"
        log_debug "Created .chp directory at $chp_dir"
    fi

    cat > "$HOOK_REGISTRY" <<'EOF'
{
  "hooks": {},
  "version": "1.0"
}
EOF

    log_debug "Hook registry force reinitialized successfully"
}

_ensure_registry() {
    if [ ! -f "$HOOK_REGISTRY" ]; then
        log_debug "Registry not found, initializing"
        init_hook_registry
    fi
}

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

    local existing_laws
    existing_laws=$(jq -r ".hooks[\"$hook_type\"].laws // []" "$HOOK_REGISTRY")
    if [ "$existing_laws" != "[]" ] && echo "$existing_laws" | grep -q "\"$law_name\""; then
        log_debug "Law '$law_name' already registered to hook '$hook_type', skipping"
        return 0
    fi

    local tmp_file="${HOOK_REGISTRY}.tmp"
    jq ".hooks[\"$hook_type\"].laws |= . + [\"$law_name\"] | \
        .hooks[\"$hook_type\"].enabled |= true | \
        .hooks[\"$hook_type\"].blocking |= true" "$HOOK_REGISTRY" > "$tmp_file" && \
    mv "$tmp_file" "$HOOK_REGISTRY"

    log_debug "Law '$law_name' registered to hook '$hook_type'"
}

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

    local tmp_file="${HOOK_REGISTRY}.tmp"
    jq ".hooks[\"$hook_type\"].laws |= map(select(. != \"$law_name\"))" "$HOOK_REGISTRY" > "$tmp_file" && \
    mv "$tmp_file" "$HOOK_REGISTRY"

    log_debug "Law '$law_name' unregistered from hook '$hook_type'"
}

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

# Returns: 0=blocking, 1=non-blocking
is_hook_blocking() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        return 1
    fi

    log_debug "Checking if hook '$hook_type' is blocking"

    _ensure_registry

    local blocking
    local has_blocking
    has_blocking=$(jq ".hooks[\"$hook_type\"] | has(\"blocking\")" "$HOOK_REGISTRY" 2>/dev/null)

    if [ "$?" != "0" ] || [ "$has_blocking" != "true" ]; then
        blocking="true"
    else
        blocking=$(jq -r ".hooks[\"$hook_type\"].blocking" "$HOOK_REGISTRY")
    fi

    if [ "$blocking" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Returns: 0=enabled, 1=disabled
is_hook_enabled() {
    local hook_type="$1"

    if [ -z "$hook_type" ]; then
        log_error "Hook type cannot be empty"
        return 1
    fi

    log_debug "Checking if hook '$hook_type' is enabled"

    _ensure_registry

    local enabled
    local has_enabled
    has_enabled=$(jq ".hooks[\"$hook_type\"] | has(\"enabled\")" "$HOOK_REGISTRY" 2>/dev/null)

    if [ "$?" != "0" ] || [ "$has_enabled" != "true" ]; then
        enabled="true"
    else
        enabled=$(jq -r ".hooks[\"$hook_type\"].enabled" "$HOOK_REGISTRY")
    fi

    if [ "$enabled" = "true" ]; then
        return 0
    else
        return 1
    fi
}

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

    if [ "$blocking" = "true" ] || [ "$blocking" = "1" ] || [ "$blocking" = "yes" ]; then
        blocking="true"
    else
        blocking="false"
    fi

    local tmp_file="${HOOK_REGISTRY}.tmp"
    jq ".hooks[\"$hook_type\"].blocking |= $blocking" "$HOOK_REGISTRY" > "$tmp_file" && \
    mv "$tmp_file" "$HOOK_REGISTRY" || {
        log_error "Failed to update blocking setting"
        rm -f "$tmp_file"
        return 1
    }

    log_debug "Hook '$hook_type' blocking set to $blocking"
}

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

    if [ "$enabled" = "true" ] || [ "$enabled" = "1" ] || [ "$enabled" = "yes" ]; then
        enabled="true"
    else
        enabled="false"
    fi

    local tmp_file="${HOOK_REGISTRY}.tmp"
    jq ".hooks[\"$hook_type\"].enabled |= $enabled" "$HOOK_REGISTRY" > "$tmp_file" && \
    mv "$tmp_file" "$HOOK_REGISTRY" || {
        log_error "Failed to update enabled setting"
        rm -f "$tmp_file"
        return 1
    }

    log_debug "Hook '$hook_type' enabled set to $enabled"
}

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
