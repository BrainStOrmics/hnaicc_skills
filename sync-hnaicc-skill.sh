#!/bin/bash
# sync-hnaicc-skill.sh
# Sync all HNAICC skills to local agents (Claude Code + Hermes).
#
# Usage: bash sync-hnaicc-skill.sh [--dry-run]
#
# This script:
# 1. Strips YAML frontmatter for Claude Code (it doesn't parse frontmatter)
# 2. Copies full SKILL.md (with frontmatter) for Hermes
# 3. Copies templates/ and references/ subdirectories where they exist

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "=== DRY RUN (no files will be modified) ==="
    echo ""
fi

# All skills to sync
SKILLS=(
    "using_HNAICC"
    "HNAICC_ssh"
    "HNAICC_sftp"
    "HNAICC_project_setup"
    "HNAICC_env_setup"
    "HNAICC_aip_submit"
    "HNAICC_job_monitor"
    "HNAICC_job_logs"
)

echo "=== HNAICC Skills Sync ==="
echo "Source: $SKILLS_DIR"
echo "Skills: ${#SKILLS[@]}"
echo ""

# Clean up deprecated skills (renamed/removed in this version)
DEPRECATED_SKILLS=("HNAICC_submit")
for skill in "${DEPRECATED_SKILLS[@]}"; do
    for base_dir in "$HOME/.claude/skills" "$HOME/.hermes/skills"; do
        if [ -d "$base_dir/$skill" ]; then
            if $DRY_RUN; then
                echo "   [dry-run] rm -rf $base_dir/$skill (deprecated)"
            else
                rm -rf "$base_dir/$skill"
                echo "   Removed deprecated: $skill"
            fi
        fi
    done
done

copy_subdirs() {
    local src_skill_dir="$1"
    local dest_skill_dir="$2"
    for subdir in templates references; do
        if [ -d "$src_skill_dir/$subdir" ]; then
            if $DRY_RUN; then
                echo "   [dry-run] cp -r $src_skill_dir/$subdir -> $dest_skill_dir/"
            else
                cp -r "$src_skill_dir/$subdir" "$dest_skill_dir/"
            fi
        fi
    done
}

# ---------- Step 1: Claude Code ----------
echo "1. Updating Claude Code skills..."
CLAUDE_SKILL_DIR="$HOME/.claude/skills"

for skill in "${SKILLS[@]}"; do
    skill_dir="$SKILLS_DIR/$skill"
    skill_md="$skill_dir/SKILL.md"

    if [ ! -f "$skill_md" ]; then
        echo "   WARNING: $skill/SKILL.md not found, skipping"
        continue
    fi

    dest="$CLAUDE_SKILL_DIR/$skill"
    if $DRY_RUN; then
        echo "   [dry-run] mkdir -p $dest"
        echo "   [dry-run] strip frontmatter -> $dest/SKILL.md"
    else
        mkdir -p "$dest"
        # Strip YAML frontmatter (Claude Code doesn't parse it)
        sed -n '/^---$/,/^---$/!p' "$skill_md" > "$dest/SKILL.md"
    fi
    copy_subdirs "$skill_dir" "$dest"
    echo "   Updated: $skill"
done

echo "   -> Target: $CLAUDE_SKILL_DIR/"
echo ""

# ---------- Step 2: Hermes Agent ----------
echo "2. Updating Hermes skills..."
HERMES_SKILL_DIR="$HOME/.hermes/skills"

if command -v hermes &> /dev/null; then
    echo "   Hermes CLI found, attempting install..."
    for skill in "${SKILLS[@]}"; do
        skill_md="$SKILLS_DIR/$skill/SKILL.md"
        [ ! -f "$skill_md" ] && continue
        if $DRY_RUN; then
            echo "   [dry-run] hermes skills install $skill_md"
        else
            hermes skills install "$skill_md" 2>/dev/null || true
        fi
        echo "   Installed via Hermes CLI: $skill"
    done
fi

# Always do manual copy (primary or fallback)
echo "   Manual copy to $HERMES_SKILL_DIR/ ..."
for skill in "${SKILLS[@]}"; do
    skill_dir="$SKILLS_DIR/$skill"
    skill_md="$skill_dir/SKILL.md"

    if [ ! -f "$skill_md" ]; then
        echo "   WARNING: $skill/SKILL.md not found, skipping"
        continue
    fi

    dest="$HERMES_SKILL_DIR/$skill"
    if $DRY_RUN; then
        echo "   [dry-run] mkdir -p $dest"
        echo "   [dry-run] cp $skill_md -> $dest/SKILL.md"
    else
        mkdir -p "$dest"
        cp "$skill_md" "$dest/SKILL.md"
    fi
    copy_subdirs "$skill_dir" "$dest"
    echo "   Updated: $skill"
done

echo "   -> Target: $HERMES_SKILL_DIR/"
echo ""

echo "=== Sync complete at $(date) ==="
echo "Verify:"
echo "  Claude: ls $CLAUDE_SKILL_DIR/ | grep HNAICC"
echo "  Hermes: ls $HERMES_SKILL_DIR/ | grep HNAICC"
