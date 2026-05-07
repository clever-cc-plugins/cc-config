# Claude Code Config Skills

Reusable Claude Code skills for configuration management, distributed as a Claude Code plugin. Install via the plugin system (see README).

## Key Config Files

| File                                           | Purpose                                                                 |
| ---------------------------------------------- | ----------------------------------------------------------------------- |
| `CLAUDE.md`                                    | Project instructions, loaded every message                              |
| `.claude/settings.json`                        | Permissions, hooks, environment variables                               |
| `.claude-plugin/marketplace.json`              | Plugin marketplace manifest (makes this repo a Claude Code marketplace) |
| `plugins/cc-config/.claude-plugin/plugin.json` | Plugin manifest for the cc-config plugin                                |
| `plugins/cc-config/skills/init/SKILL.md`       | Skill: Bootstrap a best-practice Claude Code config for a new project   |
| `plugins/cc-config/skills/optimize/SKILL.md`   | Skill: Audit and optimize an existing Claude Code configuration         |
| `.gitignore`                                   | Git ignore patterns                                                     |
| `.githooks/pre-commit`                         | Reminds when staged plugins are missing from sync-to-main.sh            |
| `install.sh`                                   | Deprecated install script (now a shim pointing to plugin install)       |
| `scripts/sync-to-main.sh`                      | Copies product files from dev branch to main for distribution           |

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

To use the cc-config skills locally in this repo (dogfooding), add the local marketplace once:

```
/plugin marketplace add ./
/plugin install cc-config@cc-config-skills
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

When compacting, preserve: current branch, list of modified plugins/skills, whether a sync-to-main is pending.

## Learnings

When the user corrects a mistake or points out a recurring issue, append a one-line
summary to .claude/learnings.md. Don't modify CLAUDE.md directly.
