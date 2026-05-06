#!/usr/bin/env bash
# Structure tests for HNAICC skills
# Validates SKILL.md files exist, have valid frontmatter, correct naming, etc.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/skills"

test_header "Skill Files Exist"

# All expected skills
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
    assert_file_exists "$SKILLS_DIR/$skill/SKILL.md" "$skill has SKILL.md"
done

test_header "Frontmatter Validation"

for skill in "${EXPECTED_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"

    # Check frontmatter exists
    assert "head -1 '$file' | grep -q '^---\$'" "$skill has YAML frontmatter"

    # Check name field matches directory
    name=$(get_frontmatter_value "$file" "name")
    assert "[[ '$name' == '$skill' ]]" "$skill frontmatter name matches directory ('$name')"

    # Check description exists and starts with "Use"
    desc=$(get_frontmatter_value "$file" "description")
    assert "[[ -n '$desc' ]]" "$skill has a description"
    assert "[[ '$desc' == Use* ]]" "$skill description starts with 'Use'"

    # Check version exists
    version=$(get_frontmatter_value "$file" "version")
    assert "[[ -n '$version' ]]" "$skill has a version ('$version')"
done

test_header "Description Quality (No Workflow Summary)"

# Descriptions should be triggers only, not workflow summaries
# Following Superpowers "Description Trap" lesson
for skill in "${EXPECTED_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    desc=$(get_frontmatter_value "$file" "description")

    # Should not contain step-by-step process descriptions
    assert_not_contains "$desc" "step" "$skill description doesn't contain 'step'"
done

test_header "HNAICC-Only Trigger"

# All descriptions should mention HNAICC to prevent false triggering
for skill in "${EXPECTED_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    desc=$(get_frontmatter_value "$file" "description")
    assert_contains "$desc" "HNAICC" "$skill description mentions HNAICC"
done

test_header "Related Skills Cross-Reference"

for skill in "${EXPECTED_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"

    # Should have related_skills field
    assert "grep -q 'related_skills:' '$file'" "$skill has related_skills field"

    # using_HNAICC should list all other skills
    if [[ "$skill" == "using_HNAICC" ]]; then
        for other in "HNAICC_ssh" "HNAICC_sftp" "HNAICC_project_setup" "HNAICC_env_setup" "HNAICC_aip_submit" "HNAICC_job_monitor" "HNAICC_job_logs"; do
            assert_contains "$(cat "$file")" "$other" "using_HNAICC references $other"
        done
    fi

    # Non-index skills should reference HNAICC_ssh
    if [[ "$skill" != "using_HNAICC" ]]; then
        assert_contains "$(cat "$file")" "HNAICC_ssh" "$skill references HNAICC_ssh"
    fi
done

test_header "Template Files"

# aip_submit templates should exist
assert_file_exists "$SKILLS_DIR/HNAICC_aip_submit/templates/basic_job.aip" "basic_job.aip template exists"
assert_file_exists "$SKILLS_DIR/HNAICC_aip_submit/templates/batch_from_list.sh" "batch_from_list.sh template exists"
assert_file_exists "$SKILLS_DIR/HNAICC_aip_submit/templates/batch_from_array.sh" "batch_from_array.sh template exists"

# Templates should have -A and -J parameters
for template in "$SKILLS_DIR/HNAICC_aip_submit/templates/basic_job.aip" \
                "$SKILLS_DIR/HNAICC_aip_submit/templates/batch_from_list.sh" \
                "$SKILLS_DIR/HNAICC_aip_submit/templates/batch_from_array.sh"; do
    assert "grep -q '#CSUB -A' '$template'" "$(basename $template) has -A parameter"
    assert "grep -q '#CSUB -J' '$template'" "$(basename $template) has -J parameter"
done

test_header "Token Efficiency"

# Skills should be concise (Superpowers guideline: <500 words for non-core skills)
for skill in "${EXPECTED_SKILLS[@]}"; do
    file="$SKILLS_DIR/$skill/SKILL.md"
    words=$(word_count "$file")
    if [[ $words -gt 500 ]]; then
        echo -e "  ${YELLOW}[WARN]${NC} $skill is $words words (recommended: <500)"
    else
        echo -e "  ${GREEN}[PASS]${NC} $skill is $words words (within limit)"
        ((TESTS_PASSED++))
    fi
done

print_summary
