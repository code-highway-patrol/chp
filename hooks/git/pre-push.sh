#!/usr/bin/env bash
# CHP Pre-Push Hook
# Installed to .git/hooks/pre-push
# Runs before pushes are sent to remote

# CHP-MANAGED

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Plugin version bump enforcement (no-op if scripts/pre-push-version-bump.sh
# is absent, e.g. downstream CHP installs that don't publish plugin manifests).
if [[ -x "$PROJECT_ROOT/scripts/pre-push-version-bump.sh" ]]; then
    stdin_buf=$(cat)
    if ! printf '%s\n' "$stdin_buf" | "$PROJECT_ROOT/scripts/pre-push-version-bump.sh"; then
        exit 1
    fi
    exec env _CHP_PUSH_REFS="$stdin_buf" "$PROJECT_ROOT/core/dispatcher.sh" pre-push "$@" <<<"$stdin_buf"
fi

exec "$PROJECT_ROOT/core/dispatcher.sh" pre-push "$@"
