#!/usr/bin/env bash
# PostToolUse: formats Markdown files with prettier after Edit/Write.
input=$(cat)
f=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
if [[ "$f" == *.md ]] && command -v prettier >/dev/null 2>&1; then
  prettier --write "$f" 2>/dev/null || true
fi
exit 0
