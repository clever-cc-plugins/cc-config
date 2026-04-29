# Claude Code Config Skills

Reusable Claude Code custom skills for configuration management. Install via `install.sh` (see README) or by copying into any project's `.claude/skills/` directory.

## Setup

After cloning, enable the Git hooks:

```bash
git config core.hooksPath .githooks
```

## Key Config Files

| File                                  | Purpose                                                               |
| ------------------------------------- | --------------------------------------------------------------------- |
| `install.sh`                          | Installs all skills into a target project via curl                    |
| `.claude/skills/cc-init/SKILL.md`     | Skill: Bootstrap a best-practice Claude Code config for a new project |
| `.claude/skills/cc-optimize/SKILL.md` | Skill: Audit and optimize an existing Claude Code configuration       |
| `.claude/skills/cc-update/SKILL.md`   | Skill: Update installed skills to their latest versions               |
| `.gitignore`                          | Git ignore patterns                                                   |
