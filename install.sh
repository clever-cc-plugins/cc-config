#!/usr/bin/env bash
# Install Claude Code skills from MichaelvanLaar/claude-code-config-skills.
# Usage:
#   bash install.sh                   # install into current directory
#   bash install.sh path/to/project   # install into a specific directory
#   REF=v1.2.0 bash install.sh        # pin to a specific tag or commit

set -euo pipefail

REPO="MichaelvanLaar/claude-code-config-skills"
REF="${REF:-main}"
BASE_URL="https://raw.githubusercontent.com/$REPO/$REF"
TARGET="${1:-.}"
SKILLS=(init optimize update)

if ! command -v curl &>/dev/null; then
  echo "error: curl is required but not found. Install curl and try again." >&2
  exit 1
fi

echo "Installing Claude Code skills into $TARGET/.claude/skills/cc-config/ (ref: $REF)"
echo ""

for skill in "${SKILLS[@]}"; do
  dir="$TARGET/.claude/skills/cc-config/$skill"
  mkdir -p "$dir"
  if curl -fsSL "$BASE_URL/.claude/skills/cc-config/$skill/SKILL.md" -o "$dir/SKILL.md"; then
    echo "  ✓ cc-config:$skill"
  else
    echo "  ✗ cc-config:$skill (download failed)" >&2
    exit 1
  fi
done

echo ""
echo "Done. Start Claude Code in $TARGET and run:"
echo "  /cc-config:init      — bootstrap a new or unconfigured project"
echo "  /cc-config:optimize  — audit and improve an existing setup"
echo ""
echo "To keep skills current, run /cc-config:update from within Claude Code."
