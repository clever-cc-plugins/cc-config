#!/usr/bin/env bash
# PreToolUse: blocks reads/edits/writes of secret .env files; allows .env.example and similar templates.
input=$(cat)
f=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null)
b=$(basename "$f")
case "$b" in
  *.example|*.sample|*.template|*.dist|example.env|sample.env) exit 0 ;;
esac
case "$b" in
  .env|.env.*)
    echo "Blocked: $b matches secret env-file pattern" >&2
    exit 2
    ;;
esac
exit 0
