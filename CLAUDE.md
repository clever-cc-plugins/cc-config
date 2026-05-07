# Claude Code Config Skills

Reusable Claude Code custom skills for configuration management. Install via `install.sh` (see README) or by copying into any project's `.claude/skills/` directory.

## Key Config Files

| File                                         | Purpose                                                               |
| -------------------------------------------- | --------------------------------------------------------------------- |
| `CLAUDE.md`                                  | Project instructions, loaded every message                            |
| `.claude/settings.json`                      | Permissions, hooks, environment variables                             |
| `.claude/skills/cc-config/init/SKILL.md`     | Skill: Bootstrap a best-practice Claude Code config for a new project |
| `.claude/skills/cc-config/optimize/SKILL.md` | Skill: Audit and optimize an existing Claude Code configuration       |
| `.claude/skills/cc-config/update/SKILL.md`   | Skill: Update installed skills to their latest versions               |
| `.gitignore`                                 | Git ignore patterns                                                   |
| `.githooks/pre-commit`                       | Reminds when staged skills are missing from sync-to-main.sh           |
| `install.sh`                                 | Installs all skills into a target project via curl                    |
| `scripts/sync-to-main.sh`                    | Copies product files from dev branch to main for distribution         |

## Structure

Two-branch workflow:

- `dev` — all skill edits happen here
- `main` — distribution-only; synced from dev via `scripts/sync-to-main.sh`

Never commit product files directly to `main`.

## Setup

After cloning, enable the Git hooks:

```bash
git config core.hooksPath .githooks
```

## Commands

```bash
bash scripts/sync-to-main.sh  # Sync product files from dev → main (run from dev branch)
```

## Don't

- Don't commit directly to `main` — always sync from `dev` via `sync-to-main.sh`
- Don't commit secrets or credentials to git
- Don't use `--force` flags — fix the underlying issue instead

## Compact Instructions

When compacting, preserve: current branch, list of modified skills, whether a sync-to-main is pending.

## Learnings

When the user corrects a mistake or points out a recurring issue, append a one-line
summary to .claude/learnings.md. Don't modify CLAUDE.md directly.
