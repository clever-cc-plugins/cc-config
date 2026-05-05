# Claude Code Config Skills

Reusable Claude Code skills for configuration management. Install skills into a
target project via `install.sh` or by copying skill folders manually.

## Skills in this Repository

| Skill           | File                                  | Purpose                                                        |
| --------------- | ------------------------------------- | -------------------------------------------------------------- |
| **cc-init**     | `.claude/skills/cc-init/SKILL.md`     | Bootstrap a best-practice Claude Code config for a new project |
| **cc-optimize** | `.claude/skills/cc-optimize/SKILL.md` | Audit and optimize an existing Claude Code configuration       |
| **cc-update**   | `.claude/skills/cc-update/SKILL.md`   | Update installed skills to their latest versions               |

## Structure

```
.claude/skills/[skill-name]/SKILL.md   one directory per skill
install.sh                              Distributes skills to target projects
```
