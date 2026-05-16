# cc-config

Reusable Claude Code skills for configuration management, distributed as a Claude Code plugin. Install via the plugin system (see README).

## Key Config Files

| File                                                   | Purpose                                                               |
| ------------------------------------------------------ | --------------------------------------------------------------------- |
| `CLAUDE.md`                                            | Project instructions, loaded every message                            |
| `.claude/settings.json`                                | Permissions, hooks, environment variables                             |
| `plugins/cc-config/.claude-plugin/plugin.json`         | Plugin manifest for the cc-config plugin                              |
| `plugins/cc-config/skills/cc-config-init/SKILL.md`     | Skill: Bootstrap a best-practice Claude Code config for a new project |
| `plugins/cc-config/skills/cc-config-optimize/SKILL.md` | Skill: Audit and optimize an existing Claude Code configuration       |
| `.gitignore`                                           | Git ignore patterns                                                   |
| `.claudeignore`                                        | Paths excluded from Claude Code indexing                              |
| `.githooks/pre-commit`                                 | Pre-commit secret scanning via gitleaks                               |

## Setup

To use the cc-config skills locally in this repo (dogfooding), install from the cc-plugins marketplace:

```
/plugin marketplace add MichaelvanLaar/cc-plugins
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
