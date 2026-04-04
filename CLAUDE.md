# Claude Code Config Skills

Reusable Claude Code custom skills for configuration management. Install by symlinking or copying into any project's `.claude/skills/` directory.

## Setup

After cloning, enable the Git hooks:

```bash
git config core.hooksPath .githooks
```

## Key Config Files

| File                                  | Purpose                                                               |
| ------------------------------------- | --------------------------------------------------------------------- |
| `.claude/skills/cc-init/SKILL.md`     | Skill: Bootstrap a best-practice Claude Code config for a new project |
| `.claude/skills/cc-optimize/SKILL.md` | Skill: Audit and optimize an existing Claude Code configuration       |
| `.gitignore`                          | Git ignore patterns                                                   |
