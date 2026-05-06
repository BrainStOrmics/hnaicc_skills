# HNAICC Skills Tests

Test suite for validating HNAICC cluster skills, following patterns from [Superpowers](https://github.com/obra/superpowers).

## Quick Start

```bash
# Run all tests
bash tests/run-all.sh
```

## Test Categories

### Structure Tests (`tests/structure/`)

Validate that skill files exist, have correct frontmatter, proper naming conventions, and consistent cross-references.

```bash
bash tests/structure/test-skill-structure.sh
```

**What it checks:**
- All expected SKILL.md files exist
- Frontmatter name matches directory name
- Descriptions start with "Use"
- Version field exists
- Related skills cross-references are present
- Template files have -A and -J parameters
- Skills are within word count limits

### Content Validation (`tests/validation/`)

Validate that skill content follows best practices and contains required sections.

```bash
bash tests/validation/test-skill-content.sh
```

**What it checks:**
- Checklist sections present
- Prerequisites reference SSH dependency
- "Don't use for" guidance exists
- Common Pitfalls sections present
- Critical rules mentioned (AIP env, memory limits, etc.)
- Template consistency (APP_NAME variable in batch scripts)

### Skill Triggering (`tests/skill-triggering/`)

Validate that skill descriptions contain the right keywords to trigger from naive user prompts.

```bash
bash tests/skill-triggering/test-skill-descriptions.sh
```

**What it checks:**
- Descriptions follow "Use when [condition] - [what it does]" format
- Keyword coverage matches common user queries
- Descriptions are concise (<40 words)
- No overlapping triggers between skills
- Each skill has unique trigger terms

## Prompts for Manual Testing

The `tests/skill-triggering/prompts/` directory contains sample prompts for testing skill triggering in Claude Code sessions:

```bash
# Test SSH skill
cat tests/skill-triggering/prompts/HNAICC_ssh.txt

# Test aip_submit skill
cat tests/skill-triggering/prompts/HNAICC_aip_submit.txt
```

## Integration Tests (Requires Cluster Access)

When the HNAICC cluster is accessible, integration tests can verify end-to-end workflows:

```bash
# Note: Requires network access to phssh.hnaicc.cn
bash tests/integration/test-ssh-connection.sh
```

## Test Helpers

The `tests/test-helpers.sh` file provides shared utilities:

- `assert "condition" "description"` — Generic assertion
- `assert_contains "haystack" "needle" "description"` — Substring check
- `assert_not_contains "haystack" "needle" "description"` — Negative substring check
- `assert_file_exists "path" "description"` — File existence check
- `get_frontmatter_value "file" "key"` — Extract YAML frontmatter value
- `word_count "file"` — Word count of a file
- `test_header "Section"` — Print section header
- `print_summary` — Print final pass/fail summary

## Writing New Tests

Follow the Superpowers pattern:

1. Source `test-helpers.sh` at the top
2. Use `test_header` to organize test sections
3. Use `assert`/`assert_contains`/`assert_file_exists` for checks
4. End with `print_summary` to show results

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

test_header "My New Tests"

assert_contains "some content" "keyword" "description of what's tested"
assert_file_exists "/path/to/file" "file exists"

print_summary
```
