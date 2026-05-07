#!/usr/bin/env bash
# sync-to-main.sh — Copies product files from dev to main and stages them.
#
# Run this from the dev branch after finishing a feature or fix.
# The script:
#   1. Verifies the working tree is clean and you are on dev
#   2. Switches to main
#   3. Checks out each product path from dev into main's working tree (staged)
#   4. Prints git status and a reminder to review before committing
#
# NOTE: Deletions are not propagated automatically. If you removed a product
# file on dev, delete it manually on main after running this script, then
# stage the deletion with `git rm`.

set -euo pipefail

PRODUCT_PATHS=(
  ".claude-plugin"
  "plugins/cc-config"
  "install.sh"
  "LICENSE"
  ".gitignore"
  "README.md"
)

# ── Guards ────────────────────────────────────────────────────────────────────

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "dev" ]]; then
  echo "error: must be run from the dev branch (currently on '$CURRENT_BRANCH')" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree is not clean — commit or stash changes before syncing" >&2
  exit 1
fi

# ── Switch to main ────────────────────────────────────────────────────────────

echo "Switching to main..."
git checkout main

# ── Sync product paths ────────────────────────────────────────────────────────

echo "Checking out product paths from dev..."
for path in "${PRODUCT_PATHS[@]}"; do
  git checkout dev -- "$path"
  echo "  synced: $path"
done

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Sync complete. Staged changes on main:"
echo "────────────────────────────────────────"
git status --short
echo "────────────────────────────────────────"
echo ""
echo "Review the diff, then commit:"
echo "  git diff --staged"
echo "  git commit"
echo ""
echo "To return to dev without committing:"
echo "  git checkout dev"
