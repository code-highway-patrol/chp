#!/bin/bash
# Collect commit metrics

# Get the absolute path to CHP base directory
LAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHP_BASE="$(cd "$LAW_DIR/../../../../" && pwd)"

# Source CHP common functions
source "$CHP_BASE/core/common.sh"

METRICS_FILE="$CHP_BASE/.chp/commit-metrics.json"

# Initialize metrics file
if [ ! -f "$METRICS_FILE" ]; then
    echo '{"commits": 0, "files_changed": 0}' > "$METRICS_FILE"
fi

# Increment commit count
jq '.commits += 1' "$METRICS_FILE" > "${METRICS_FILE}.tmp"
mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

# Count changed files
# Handle edge case where HEAD~1 doesn't exist (first commit)
if git rev-parse HEAD~1 >/dev/null 2>&1; then
    changed_files=$(git diff --name-only HEAD~1 HEAD | wc -l | tr -d ' ')
else
    # First commit - count files in the initial commit
    changed_files=$(git ls-tree -r --name-only HEAD | wc -l | tr -d ' ')
fi

jq --arg cf "$changed_files" '.files_changed += ($cf | tonumber)' "$METRICS_FILE" > "${METRICS_FILE}.tmp"
mv "${METRICS_FILE}.tmp" "$METRICS_FILE"

echo "📊 Commit metrics updated"
echo "   Total commits: $(jq -r '.commits' "$METRICS_FILE")"
echo "   Files changed: $(jq -r '.files_changed' "$METRICS_FILE")"

exit 0
