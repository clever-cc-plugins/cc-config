# cc-config

Reusable Claude Code skills for configuration management, distributed as a Claude Code plugin. Install via the plugin system (see README).

## Key Config Files

| File                                                   | Purpose                                                                 |
| ------------------------------------------------------ | ----------------------------------------------------------------------- |
| `CLAUDE.md`                                            | Project instructions, loaded every message                              |
| `.claude/settings.json`                                | Permissions, hooks, environment variables                               |
| `.claude-plugin/marketplace.json`                      | Plugin marketplace manifest (makes this repo a Claude Code marketplace) |
| `plugins/cc-config/.claude-plugin/plugin.json`         | Plugin manifest for the cc-config plugin                                |
| `plugins/cc-config/skills/cc-config-init/SKILL.md`     | Skill: Bootstrap a best-practice Claude Code config for a new project   |
| `plugins/cc-config/skills/cc-config-optimize/SKILL.md` | Skill: Audit and optimize an existing Claude Code configuration         |
| `install.sh`                                           | Deprecated install script (now a shim pointing to plugin install)       |
| `.gitignore`                                           | Git ignore patterns                                                     |
| `.claudeignore`                                        | Paths excluded from Claude Code indexing                                |
| `.githooks/pre-commit`                                 | Pre-commit secret scanning via gitleaks                                 |

## Setup

To use the cc-config skills locally in this repo (dogfooding), add the local marketplace once:

```
/plugin marketplace add ./
/plugin install cc-config@cc-config
```

## Don't

- Don't commit secrets or credentials to git
- Don't use `--force` flags — fix the underlying issue instead

## Compact Instructions

When compacting, preserve: current branch and list of modified plugins/skills.

## Learnings

When the user corrects a mistake or points out a recurring issue, append a one-line
summary to .claude/learnings.md. Don't modify CLAUDE.md directly.
