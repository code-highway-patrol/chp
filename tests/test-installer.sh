#!/bin/bash
# Test hook installation

set -e

source "$(dirname "$0")/../core/common.sh"
source "$(dirname "$0")/../core/installer.sh"

# Test: install_hook for a law
echo "Testing install_hook..."
# This should fail initially
if install_hook "test-law" "pre-commit" > /dev/null 2>&1; then
    echo "PASS: install_hook function exists"
else
    echo "FAIL: install_hook function not found or failed"
    exit 1
fi

# Test: uninstall_hook for a law
echo "Testing uninstall_hook..."
if uninstall_hook "test-law" "pre-commit" > /dev/null 2>&1; then
    echo "PASS: uninstall_hook function exists"
else
    echo "FAIL: uninstall_hook function not found or failed"
    exit 1
fi

echo "All tests passed!"
