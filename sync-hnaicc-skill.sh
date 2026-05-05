#!/bin/bash
# sync-hnaicc-skill.sh
# Sync HNAICC_submit skill to Claude Code and Hermes from this repo
#
# Usage: bash sync-hnaicc-skill.sh
#
# This script:
# 1. Updates Claude Code skill (from SKILL.md, strips frontmatter)
# 2. Updates Hermes skill (from SKILL.md)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MD="$SCRIPT_DIR/skills/HNAICC_submit/SKILL.md"
SKILL_NAME="HNAICC_submit"

echo "=== HNAICC Submit Skill Sync ==="
echo "Source: $SKILL_MD"
echo ""

if [ ! -f "$SKILL_MD" ]; then
    echo "ERROR: SKILL.md not found at $SKILL_MD"
    exit 1
fi

# Step 1: Update Claude Code skill
echo "1. Updating Claude Code skill..."
CLAUDE_SKILL_DIR="$HOME/.claude/skills"
mkdir -p "$CLAUDE_SKILL_DIR/$SKILL_NAME"

# Strip YAML frontmatter for Claude
sed -n '/^---$/,/^---$/!p' "$SKILL_MD" > "$CLAUDE_SKILL_DIR/$SKILL_NAME/SKILL.md"

# Copy templates and references
cp -r "$SCRIPT_DIR/skills/$SKILL_NAME/templates" "$CLAUDE_SKILL_DIR/$SKILL_NAME/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/skills/$SKILL_NAME/references" "$CLAUDE_SKILL_DIR/$SKILL_NAME/" 2>/dev/null || true

echo "   Claude Code skill updated: $CLAUDE_SKILL_DIR/$SKILL_NAME/"

# Step 2: Update Hermes skill
echo "2. Updating Hermes skill..."
if command -v hermes &> /dev/null; then
    hermes skills install "$SKILL_MD" 2>/dev/null && \
        echo "   Hermes skill installed via hermes skills install" || \
        echo "   Hermes install failed, trying manual copy..."

    # Fallback: manual copy
    HERMES_SKILL_DIR="$HOME/.hermes/skills"
    if [ -d "$HERMES_SKILL_DIR" ]; then
        mkdir -p "$HERMES_SKILL_DIR/$SKILL_NAME"
        cp "$SKILL_MD" "$HERMES_SKILL_DIR/$SKILL_NAME/SKILL.md"
        cp -r "$SCRIPT_DIR/skills/$SKILL_NAME/templates" "$HERMES_SKILL_DIR/$SKILL_NAME/" 2>/dev/null || true
        cp -r "$SCRIPT_DIR/skills/$SKILL_NAME/references" "$HERMES_SKILL_DIR/$SKILL_NAME/" 2>/dev/null || true
        echo "   Hermes skill updated: $HERMES_SKILL_DIR/$SKILL_NAME/"
    fi
else
    HERMES_SKILL_DIR="$HOME/.hermes/skills"
    mkdir -p "$HERMES_SKILL_DIR/$SKILL_NAME"
    cp "$SKILL_MD" "$HERMES_SKILL_DIR/$SKILL_NAME/SKILL.md"
    cp -r "$SCRIPT_DIR/skills/$SKILL_NAME/templates" "$HERMES_SKILL_DIR/$SKILL_NAME/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/skills/$SKILL_NAME/references" "$HERMES_SKILL_DIR/$SKILL_NAME/" 2>/dev/null || true
    echo "   Hermes skill updated (manual copy): $HERMES_SKILL_DIR/$SKILL_NAME/"
fi

echo ""
echo "=== Sync complete at $(date) ==="
echo "Verify:"
echo "  Claude: ls $CLAUDE_SKILL_DIR/$SKILL_NAME/"
echo "  Hermes: hermes skills list | grep $SKILL_NAME"
