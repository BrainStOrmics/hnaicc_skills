#!/usr/bin/env bash
# Skill triggering tests
# Validates that skill descriptions contain the right keywords to trigger from naive user prompts
# Following Superpowers pattern: descriptions should have concrete triggers, not workflow summaries
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/skills"

test_header "Description Format (Use when...)"

EXPECTED_SKILLS=(
    "using_HNAICC"
    "HNAICC_ssh"
    "HNAICC_sftp"
    "HNAICC_project_setup"
    "HNAICC_env_setup"
    "HNAICC_aip_submit"
    "HNAICC_job_monitor"
    "HNAICC_job_logs"
)

for skill in "${EXPECTED_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    desc=$(get_frontmatter_value "$file" "description")
    # Accept both "Use when" and "Use ONLY when" formats
    if [[ "$skill" == "using_HNAICC" ]]; then
        assert_contains "$desc" "Use ONLY when" "$skill description starts with 'Use ONLY when'"
    else
        assert_contains "$desc" "Use when" "$skill description starts with 'Use when'"
    fi
done

test_header "Keyword Coverage (What users would type)"

# Test that descriptions contain keywords matching common user queries

# SSH skill should trigger on SSH-related terms
ssh_desc=$(get_frontmatter_value "$SKILLS_DIR/HNAICC_ssh/SKILL.md" "description")
assert_contains "$ssh_desc" "connecting" "SSH skill mentions 'connecting'"
assert_contains "$ssh_desc" "credential" "SSH skill mentions 'credential'"

# SFTP skill should trigger on file transfer terms
sftp_desc=$(get_frontmatter_value "$SKILLS_DIR/HNAICC_sftp/SKILL.md" "description")
assert_contains "$sftp_desc" "transferr" "SFTP skill mentions 'transfer'"

# aip_submit should trigger on job submission terms
submit_desc=$(get_frontmatter_value "$SKILLS_DIR/HNAICC_aip_submit/SKILL.md" "description")
assert_contains "$submit_desc" "submit" "aip_submit mentions 'submit'"
assert_contains "$submit_desc" "script" "aip_submit mentions 'script'"
assert_contains "$submit_desc" "csub" "aip_submit mentions 'csub'"

# job_monitor should trigger on status check terms
monitor_desc=$(get_frontmatter_value "$SKILLS_DIR/HNAICC_job_monitor/SKILL.md" "description")
assert_contains "$monitor_desc" "status" "job_monitor mentions 'status'"
assert_contains "$monitor_desc" "queue" "job_monitor mentions 'queue'"

# job_logs should trigger on log-related terms
logs_desc=$(get_frontmatter_value "$SKILLS_DIR/HNAICC_job_logs/SKILL.md" "description")
assert_contains "$logs_desc" "log" "job_logs mentions 'log'"
assert_contains "$logs_desc" "error" "job_logs mentions 'error'"

# env_setup should trigger on environment terms
env_desc=$(get_frontmatter_value "$SKILLS_DIR/HNAICC_env_setup/SKILL.md" "description")
assert_contains "$env_desc" "environment" "env_setup mentions 'environment'"
assert_contains "$env_desc" "conda" "env_setup mentions 'conda'"

# project_setup should trigger on project terms
project_desc=$(get_frontmatter_value "$SKILLS_DIR/HNAICC_project_setup/SKILL.md" "description")
assert_contains "$project_desc" "project" "project_setup mentions 'project'"
assert_contains "$project_desc" "directory" "project_setup mentions 'directory'"

test_header "Description Length (Concise Triggers)"

# Descriptions should be concise - just triggers, not process summaries
# Superpowers guideline: descriptions are for triggering, not instruction
for skill in "${EXPECTED_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    desc=$(get_frontmatter_value "$file" "description")
    words=$(echo "$desc" | wc -w | tr -d ' ')
    if [[ $words -gt 40 ]]; then
        echo -e "  ${YELLOW}[WARN]${NC} $skill description is $words words (recommended: <40)"
    else
        echo -e "  ${GREEN}[PASS]${NC} $skill description is $words words (concise)"
        ((TESTS_PASSED++))
    fi
done

test_header "No Overlapping Triggers"

# Descriptions should be distinct enough to avoid false triggering
# Check that each skill has unique trigger words
declare -A desc_map
for skill in "${EXPECTED_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    desc=$(get_frontmatter_value "$file" "description")
    desc_map["$skill"]="$desc"
done

# SSH should be unique about connection/credentials
assert_contains "${desc_map[HNAICC_ssh]}" "connect" "SSH has unique connection trigger"

# SFTP should be unique about transfer/upload/download
assert_contains "${desc_map[HNAICC_sftp]}" "transferr\|upload\|download" "SFTP has unique transfer trigger"

# aip_submit should be unique about csub/script creation
assert_contains "${desc_map[HNAICC_aip_submit]}" "csub\|script" "aip_submit has unique submit trigger"

# job_monitor should be unique about status/queue
assert_contains "${desc_map[HNAICC_job_monitor]}" "status\|queue" "job_monitor has unique status trigger"

# job_logs should be unique about logs/output/errors
assert_contains "${desc_map[HNAICC_job_logs]}" "log\|output\|error" "job_logs has unique log trigger"

test_header "Using_HNAICC as Index"

# using_HNAICC should be the catch-all entry point
using_desc=$(get_frontmatter_value "$SKILLS_DIR/using_HNAICC/SKILL.md" "description")
assert_contains "$using_desc" "Entry point" "using_HNAICC identifies as entry point"
assert_contains "$using_desc" "index" "using_HNAICC identifies as index"

print_summary
