#!/bin/bash
# End-to-end hook system test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "CHP Universal Hook System - End-to-End Test"
echo "==========================================="
echo ""

# Setup
export CHP_DEBUG=true

echo "1. Testing hook registry..."
./core/hook-registry.sh init > /dev/null 2>&1
if [ -f ".chp/hook-registry.json" ]; then
    echo "   ✓ Registry initialized"
else
    echo "   ✗ Registry initialization failed"
    exit 1
fi

echo ""
echo "2. Testing hook detection..."
if ./core/detector.sh all > /dev/null 2>&1; then
    echo "   ✓ Hooks detected"
else
    echo "   ✗ Hook detection failed"
    exit 1
fi

echo ""
echo "3. Creating test law..."
if ./commands/chp-law create e2e-test-law --hooks=pre-commit > /dev/null 2>&1; then
    if [ -d "docs/chp/laws/e2e-test-law" ]; then
        echo "   ✓ Test law created"
    else
        echo "   ✗ Law directory not found"
        exit 1
    fi
else
    echo "   ✗ Law creation failed"
    exit 1
fi

echo ""
echo "4. Testing hook registration..."
if ./commands/chp-hooks registry | grep -q "e2e-test-law"; then
    echo "   ✓ Hook registered"
else
    echo "   ✗ Hook registration failed"
    echo "   Registry contents:"
    ./commands/chp-hooks registry
    exit 1
fi

echo ""
echo "5. Testing chp-hooks list..."
if ./commands/chp-hooks list > /dev/null 2>&1; then
    echo "   ✓ Hook list works"
else
    echo "   ✗ Hook list failed"
    exit 1
fi

echo ""
echo "6. Testing chp-status..."
if ./commands/chp-status > /dev/null 2>&1; then
    echo "   ✓ Status command works"
else
    echo "   ✗ Status command failed"
    exit 1
fi

echo ""
echo "7. Cleanup..."
if ./commands/chp-law delete e2e-test-law > /dev/null 2>&1; then
    if [ ! -d "docs/chp/laws/e2e-test-law" ]; then
        echo "   ✓ Test law deleted"
    else
        echo "   ✗ Law directory still exists"
        exit 1
    fi
else
    echo "   ✗ Law deletion failed"
    exit 1
fi

echo ""
echo "==========================================="
echo "All end-to-end tests passed!"
echo "==========================================="
