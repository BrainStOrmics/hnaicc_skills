#!/usr/bin/env bash
# Run all HNAICC skill tests
# Usage: bash tests/run-all.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "========================================"
echo " HNAICC Skills Test Suite"
echo "========================================"
echo ""
echo "Project: $PROJECT_DIR"
echo "Date: $(date)"
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_TESTS=()

# Run a test script and track results
run_test() {
    local test_script="$1"
    local test_name=$(basename "$test_script" .sh)

    echo ""
    echo -e "\033[0;36m>>> Running: $test_name\033[0m"
    echo ""

    if bash "$test_script" 2>&1; then
        echo -e "\033[0;32m✓ $test_name passed\033[0m"
    else
        echo -e "\033[0;31m✗ $test_name failed\033[0m"
        FAILED_TESTS+=("$test_name")
    fi
}

# Structure tests
run_test "$SCRIPT_DIR/structure/test-skill-structure.sh"

# Content validation tests
run_test "$SCRIPT_DIR/validation/test-skill-content.sh"

# Skill triggering tests
run_test "$SCRIPT_DIR/skill-triggering/test-skill-descriptions.sh"

# Summary
echo ""
echo "========================================"
echo " Overall Test Summary"
echo "========================================"
echo ""

if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    echo -e "\033[0;32mAll test suites passed!\033[0m"
    exit 0
else
    echo -e "\033[0;31mFailed test suites:\033[0m"
    for t in "${FAILED_TESTS[@]}"; do
        echo "  - $t"
    done
    exit 1
fi
