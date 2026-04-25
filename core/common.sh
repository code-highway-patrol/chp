#!/bin/bash
# Shared utilities for CHP law enforcement

# Temporary file tracking for cleanup
declare -ga _CHP_TMPFILES=()

# Cleanup trap - removes temp files on exit
trap '_chp_cleanup' EXIT

_chp_cleanup() {
    rm -f "${_CHP_TMPFILES[@]}" 2>/dev/null
}

# Helper to create tracked temporary files
# Usage: mktemp_chp [template]
# Outputs: Path to temporary file
mktemp_chp() {
    local template="${1:-chp_tmp_XXXXXX}"
    local tmpfile=$(mktemp -t "$template")
    _CHP_TMPFILES+=("$tmpfile")
    echo "$tmpfile"
}

# CHP base directory (allow override via environment)
CHP_BASE="${CHP_BASE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LAWS_DIR="${LAWS_DIR:-$CHP_BASE/docs/chp/laws}"
GUIDANCE_DIR="${GUIDANCE_DIR:-$CHP_BASE/docs/chp}"

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

log_debug() {
    if [ "${CHP_DEBUG:-false}" = "true" ]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1" >&2
    fi
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
    local law_json="$LAWS_DIR/$law_name/law.json"

    [[ ! -f "$law_json" ]] && return 1
    jq -r "if has(\"$field\") then .$field else \"\" end" "$law_json" 2>/dev/null || return 1
}

# Get law paths as space-separated string: "law_dir law_json guidance_md"
# Usage: get_law_paths <law_name>
# Outputs: Three paths separated by spaces
get_law_paths() {
    local law_name="$1"
    local law_dir="$LAWS_DIR/$law_name"
    echo "$law_dir" "$law_dir/law.json" "$law_dir/guidance.md"
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
