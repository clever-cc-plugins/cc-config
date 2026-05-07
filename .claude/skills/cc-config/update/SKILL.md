---
name: update
description: Update the cc-config skills (init, optimize, update) to their latest versions from the source repository. Use when the user says "update skills", "get the latest cc-config skills", "refresh skills", "update cc-init", "update cc-optimize", or similar.
allowed-tools: Bash, Read
---

# Update Claude Code Skills

Fetch the latest versions of the installed skills from `MichaelvanLaar/claude-code-config-skills` and replace the local copies.

## Step 1: Check prerequisites

Verify `.claude/skills/cc-config/` exists in the current directory:

```bash
ls .claude/skills/cc-config/ 2>/dev/null || echo "NOT_FOUND"
```

If the directory is missing, abort and tell the user: "No `.claude/skills/cc-config/` directory found. Run `install.sh` from the source repository first — see the README at github.com/MichaelvanLaar/claude-code-config-skills."

## Step 2: Detect installed skills

```bash
for skill in init optimize update; do
  [ -f ".claude/skills/cc-config/$skill/SKILL.md" ] && echo "$skill: installed" || echo "$skill: not installed"
done
```

Update rules:

- **`update`** — always update (enables self-update).
- **`init` and `optimize`** — only if already installed. Do not install skills the user has not chosen to install.

## Step 3: Download and replace

```bash
BASE_URL="https://raw.githubusercontent.com/MichaelvanLaar/claude-code-config-skills/main"

for skill in update init optimize; do
  target=".claude/skills/cc-config/$skill/SKILL.md"
  if [ "$skill" = "update" ] || [ -f "$target" ]; then
    mkdir -p ".claude/skills/cc-config/$skill"
    if curl -fsSL "$BASE_URL/.claude/skills/cc-config/$skill/SKILL.md" -o "$target"; then
      echo "✓ updated cc-config:$skill"
    else
      echo "✗ failed to update cc-config:$skill"
    fi
  else
    echo "— skipped cc-config:$skill (not installed)"
  fi
done
```

## Step 4: Report and wrap up

After the downloads complete:

1. List each skill: updated, skipped, or failed.
2. If `cc-config:init` was skipped (not installed), mention: "`cc-config:init` is available but not installed. Run `install.sh` to add it — see github.com/MichaelvanLaar/claude-code-config-skills."
3. Remind the user to commit the updated files: `git add .claude/skills/cc-config/ && git commit`.

## What NOT to do

- Do not install `cc-config:init` or `cc-config:optimize` if they were not already present.
- Do not run any skill after updating.
- Do not modify any other project files.

## Feedback

Before ending the session, ask: "Were all skills updated successfully? If anything went wrong, I'll log it to `.claude/learnings.md`."
