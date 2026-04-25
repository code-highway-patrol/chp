#!/bin/bash
# Shared utilities for CHP law enforcement

declare -ga _CHP_TMPFILES=()

trap '_chp_cleanup' EXIT

_chp_cleanup() {
    rm -f "${_CHP_TMPFILES[@]}" 2>/dev/null
}

# Usage: mktemp_chp [template]
mktemp_chp() {
    local template="${1:-chp_tmp_XXXXXX}"
    local tmpfile=$(mktemp -t "$template")
    _CHP_TMPFILES+=("$tmpfile")
    echo "$tmpfile"
}

CHP_BASE="${CHP_BASE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LAWS_DIR="${LAWS_DIR:-$CHP_BASE/docs/chp/laws}"
GUIDANCE_DIR="${GUIDANCE_DIR:-$CHP_BASE/docs/chp}"

# Highlight tag style: bold white text on colored background
BG_RED='\033[41m\033[1m'
BG_GREEN='\033[42m\033[1m'
BG_ORANGE='\033[48;5;202m\033[1m'
BG_YELLOW='\033[43m\033[1m'
NC='\033[0m'

log_info() {
    echo -e " ${BG_GREEN} INFO ${NC}  $1"
}

log_error() {
    echo -e " ${BG_RED} ERROR ${NC}  $1" >&2
}

log_warn() {
    echo -e " ${BG_ORANGE} WARN ${NC}  $1"
}

log_debug() {
    if [ "${CHP_DEBUG:-false}" = "true" ]; then
        echo -e " ${BG_YELLOW} DEBUG ${NC}  $1" >&2
    fi
}

law_exists() {
    local law_name="$1"
    [ -d "$LAWS_DIR/$law_name" ]
}

get_law_meta() {
    local law_name="$1"
    local field="$2"
    local law_json="$LAWS_DIR/$law_name/law.json"

    [[ ! -f "$law_json" ]] && return 1
    jq -r "if has(\"$field\") then .$field else \"\" end" "$law_json" 2>/dev/null || return 1
}

# Outputs: "law_dir law_json guidance_md"
get_law_paths() {
    local law_name="$1"
    local law_dir="$LAWS_DIR/$law_name"
    echo "$law_dir" "$law_dir/law.json" "$law_dir/guidance.md"
}

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
