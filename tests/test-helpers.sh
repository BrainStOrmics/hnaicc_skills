#!/usr/bin/env bash
# Shared test utilities for HNAICC skills
# Source this file from test scripts: source "$SCRIPT_DIR/test-helpers.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Assert that a condition is true
# Usage: assert "condition" "description"
assert() {
    local condition="$1"
    local description="$2"
    if eval "$condition" > /dev/null 2>&1; then
        echo -e "  ${GREEN}[PASS]${NC} $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $description"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert that a string contains a substring
# Usage: assert_contains "haystack" "needle" "description"
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"
    if echo "$haystack" | grep -qi "$needle" 2>/dev/null; then
        echo -e "  ${GREEN}[PASS]${NC} $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $description"
        echo "    Expected to find: '$needle'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert that a string does NOT contain a substring
# Usage: assert_not_contains "haystack" "needle" "description"
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"
    if ! echo "$haystack" | grep -qi "$needle" 2>/dev/null; then
        echo -e "  ${GREEN}[PASS]${NC} $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $description"
        echo "    Should NOT contain: '$needle'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert that a file exists
# Usage: assert_file_exists "path" "description"
assert_file_exists() {
    local path="$1"
    local description="$2"
    if [[ -f "$path" ]]; then
        echo -e "  ${GREEN}[PASS]${NC} $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $description"
        echo "    File not found: $path"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Extract frontmatter value from a SKILL.md file using Python for reliability
# Usage: get_frontmatter_value "file" "key"
get_frontmatter_value() {
    local file="$1"
    local key="$2"
    python3 -c "
import re, sys
with open(sys.argv[1]) as f:
    text = f.read()
m = re.search(r'^---\n(.*?)\n---', text, re.DOTALL | re.MULTILINE)
if m:
    for line in m.group(1).split('\n'):
        if line.startswith(sys.argv[2] + ':'):
            val = line[len(sys.argv[2])+1:].strip()
            print(val)
            break
" "$file" "$key" 2>/dev/null
}

# Get word count of a file
# Usage: word_count "file"
word_count() {
    wc -w < "$1" | tr -d ' '
}

# Print test section header
# Usage: test_header "Section Name"
test_header() {
    echo ""
    echo -e "${YELLOW}=== $1 ===${NC}"
}

# Print test summary
print_summary() {
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW} Test Summary${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    else
        echo -e "  Failed: 0"
    fi
    echo ""
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}STATUS: ALL TESTS PASSED${NC}"
        return 0
    else
        echo -e "${RED}STATUS: $TESTS_FAILED TEST(S) FAILED${NC}"
        return 1
    fi
}
