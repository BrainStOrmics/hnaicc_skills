#!/usr/bin/env bash
# Content validation tests for HNAICC skills
# Validates skill content follow best practices from Superpowers
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/skills"

SKILLS_WITH_CHECKLIST=(
    "HNAICC_ssh"
    "HNAICC_sftp"
    "HNAICC_project_setup"
    "HNAICC_env_setup"
    "HNAICC_aip_submit"
    "HNAICC_job_monitor"
    "HNAICC_job_logs"
)

test_header "Checklist Pattern"

# Skills should have a Checklist section at the top (Superpowers pattern)
for skill in "${SKILLS_WITH_CHECKLIST[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    assert "grep -qi '## Checklist' '$file'" "$skill has a Checklist section"
done

test_header "Prerequisites / SSH Dependency"

# Skills (except using_HNAICC) should reference SSH dependency
for skill in "${SKILLS_WITH_CHECKLIST[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    assert_contains "$(cat "$file")" "HNAICC_ssh" "$skill references HNAICC_ssh as dependency"
done

test_header "Next Steps Guidance"

for skill in "${SKILLS_WITH_CHECKLIST[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    content=$(cat "$file")
    # At least one of these should be present
    has_next_steps=false
    if grep -q "## Next Steps" "$file" 2>/dev/null; then
        has_next_steps=true
    fi
    assert "[[ '$has_next_steps' == true ]]" "$skill has next steps guidance"
done

test_header "Don't Use For Sections"

# Non-index skills should have "Don't use for" guidance to prevent misuse
for skill in "${SKILLS_WITH_CHECKLIST[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    assert_contains "$(cat "$file")" "Don't use for" "$skill has 'Don't use for' guidance"
done

test_header "Common Pitfalls"

# All skills should have a Common Pitfalls section
for skill in "${SKILLS_WITH_CHECKLIST[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    assert "grep -qi 'Common Pitfalls' '$file'" "$skill has Common Pitfalls section"
done

test_header "Critical AIP Environment Rule"

# Skills that use cluster commands should mention the AIP environment requirement
AIP_DEPENDENT_SKILLS=(
    "HNAICC_aip_submit"
    "HNAICC_job_monitor"
    "HNAICC_job_logs"
    "HNAICC_env_setup"
)

for skill in "${AIP_DEPENDENT_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    assert_contains "$(cat "$file")" "source /opt/skyformai/etc/aip.sh" "$skill mentions AIP environment loading"
done

test_header "CPU Count Guidance in aip_submit"

submit_file="$SKILLS_DIR/HNAICC_aip_submit/SKILL.md"
assert_contains "$(cat "$submit_file")" "11GB" "aip_submit mentions 11GB/core memory rule"
assert_contains "$(cat "$submit_file")" "ceil" "aip_submit has CPU calculation guidance"

test_header "-A vs -J Naming in aip_submit"

submit_content=$(cat "$submit_file")
assert_contains "$submit_content" "project-level" "aip_submit explains -A is project-level"
assert_contains "$submit_content" "unique" "aip_submit explains -J is unique per job"

test_header "Batch Submission sleep Rule"

assert_contains "$(cat "$submit_file")" "sleep 1" "aip_submit mentions sleep 1 between csub calls"

test_header "SSH Key Permissions"

ssh_content=$(cat "$SKILLS_DIR/HNAICC_ssh/SKILL.md")
assert_contains "$ssh_content" "600" "HNAICC_ssh mentions 600 permissions"
assert_contains "$ssh_content" "chmod" "HNAICC_ssh mentions chmod"

test_header "Template Consistency"

# Batch templates should use APP_NAME variable
for template in "$SKILLS_DIR/HNAICC_aip_submit/templates/batch_from_list.sh" \
                "$SKILLS_DIR/HNAICC_aip_submit/templates/batch_from_array.sh"; do
    assert_contains "$(cat "$template")" "APP_NAME" "$(basename $template) uses APP_NAME variable"
done

print_summary
