#!/bin/bash
# Test hook detection

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/detector.sh"

# Test git hook detection
echo "Testing git hook detection..."
if [ -d .git ]; then
    echo "PASS: .git directory detected"
else
    echo "SKIP: Not in a git repository"
fi

# Test for pretool detection
echo "Testing pretool hook detection..."
if command -v pretool &> /dev/null; then
    echo "INFO: pretool is available"
else
    echo "INFO: pretool not found"
fi

# Test detect_available_hooks function
echo "Testing detect_available_hooks..."
hooks=$(detect_available_hooks)
echo "Available hooks: $hooks"
