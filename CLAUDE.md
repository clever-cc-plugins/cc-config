# cc-config

Reusable Claude Code skills for configuration management, distributed as a Claude Code plugin. Install via the plugin system (see README).

## Key Config Files

| File                                                   | Purpose                                                               |
| ------------------------------------------------------ | --------------------------------------------------------------------- |
| `.claude/format-markdown.sh`                           | PostToolUse hook: formats Markdown files with prettier after edits    |
| `.claude/guard-secret-files.sh`                        | PreToolUse hook: blocks reads/edits/writes of secret .env files       |
| `.claudeignore`                                        | Paths excluded from Claude Code indexing                              |
| `CLAUDE.md`                                            | Project instructions, loaded every message                            |
| `.claude/settings.json`                                | Permissions, hooks, environment variables                             |
| `.githooks/pre-commit`                                 | Secret scanning (gitleaks) + CLAUDE.md table sync                     |
| `.github/workflows/claude-code-review.yml`             | Automatic PR review via Claude Code                                   |
| `.github/workflows/claude.yml`                         | Trigger Claude via @claude mentions in issues/PRs                     |
| `.gitignore`                                           | Git ignore patterns                                                   |
| `plugins/cc-config/.claude-plugin/plugin.json`         | Plugin manifest for the cc-config plugin                              |
| `plugins/cc-config/skills/cc-config-init/SKILL.md`     | Skill: Bootstrap a best-practice Claude Code config for a new project |
| `plugins/cc-config/skills/cc-config-optimize/SKILL.md` | Skill: Audit and optimize an existing Claude Code configuration       |
| `scripts/sync-config-table.sh`                         | Keeps Key Config Files table in sync on each commit                   |

## Setup

To use the cc-config skills locally in this repo (dogfooding), install from the clever-cc-plugins marketplace:

```
/plugin marketplace add clever-cc-plugins/marketplace
/plugin install cc-config@clever-cc-plugins
```

## Don't

- Don't commit secrets or credentials to git
- Don't use `--force` flags — fix the underlying issue instead

## Compact Instructions

When compacting, preserve: current branch and list of modified plugins/skills.

## Learnings

When the user corrects a mistake or points out a recurring issue, append a one-line
summary to .claude/learnings.md. Don't modify CLAUDE.md directly.
