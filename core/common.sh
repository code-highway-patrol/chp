#!/bin/bash
# Shared utilities for CHP law enforcement

# CHP base directory
CHP_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAWS_DIR="$CHP_BASE/docs/chp/laws"
GUIDANCE_DIR="$CHP_BASE/docs/chp"

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

# Check if a law exists
law_exists() {
    local law_name="$1"
    [ -d "$LAWS_DIR/$law_name" ]
}

# Get law metadata
get_law_meta() {
    local law_name="$1"
    local field="$2"
    if [ -f "$LAWS_DIR/$law_name/law.json" ]; then
        jq -r ".$field // empty" "$LAWS_DIR/$law_name/law.json"
    fi
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
