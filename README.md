# claude-code-config-skills

Two Claude Code skills for setting up and maintaining a best-practice Claude Code configuration.

**`/cc-init`** bootstraps a lean configuration for a new or unconfigured project — a more opinionated alternative to the built-in `/init`.

**`/cc-optimize`** audits and improves an existing configuration against current best practices — useful after a project has grown, or periodically to prevent config drift.

Both skills are grounded in the consolidated recommendations from the [official Claude Code docs](https://code.claude.com/docs/en/best-practices), [Anthropic’s engineering blog](https://www.anthropic.com/engineering), community configurations, and academic research on agent instruction design.

## What problem do these skills solve?

The built-in `/init` generates a CLAUDE.md by scanning your repository. The result is often verbose, generic, and stuffed with information Claude already knows — burning context tokens on every single message. There’s also no guidance on permissions, hooks, cost optimization, or the broader configuration surface beyond CLAUDE.md.

These skills take a different approach:

- **`/cc-init`** creates the minimum viable configuration that’s correct from day one: a slim CLAUDE.md, hardened `permissions.deny`, a formatter hook if applicable, and cost-optimization defaults. It asks targeted questions instead of guessing, and uses TODO placeholders rather than hallucinating commands it can’t verify.

- **`/cc-optimize`** treats your existing configuration as a codebase to audit. It inventories every config file, measures CLAUDE.md line count, checks for known anti-patterns (bloat, missing hooks, hardcoded secrets, deprecated settings), and presents findings in three tiers — must fix, should fix, nice to have — before touching anything.

## Installation

Copy the `.claude/skills/` directory into your project:

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/claude-code-config-skills.git /tmp/cc-skills

# Copy the skills into your project
cp -r /tmp/cc-skills/.claude/skills/cc-init YOUR_PROJECT/.claude/skills/cc-init
cp -r /tmp/cc-skills/.claude/skills/cc-optimize YOUR_PROJECT/.claude/skills/cc-optimize

# Clean up
rm -rf /tmp/cc-skills
```

Or, if you just want to bootstrap a brand new project from scratch:

```bash
# Create project directory and clone skills into it
mkdir my-new-project && cd my-new-project
git clone https://github.com/YOUR_USERNAME/claude-code-config-skills.git /tmp/cc-skills
mkdir -p .claude/skills
cp -r /tmp/cc-skills/.claude/skills/cc-init .claude/skills/cc-init
cp -r /tmp/cc-skills/.claude/skills/cc-optimize .claude/skills/cc-optimize
rm -rf /tmp/cc-skills

# Start Claude Code and bootstrap
claude
# Then type: /cc-init
```

### Directory structure after installation

```
your-project/
└── .claude/
    └── skills/
        ├── cc-init/
        │   └── SKILL.md
        └── cc-optimize/
            └── SKILL.md
```

After running `/cc-init`, additional files are created in your project (see [What the skills create and check](#what-the-skills-create-and-check)).

## Usage

### `/cc-init` — Bootstrap a new project

Start Claude Code in your project directory and invoke the skill:

```
/cc-init
```

Or with a brief project description to skip some questions:

```
/cc-init Next.js 14 e-commerce platform with Stripe and Postgres
```

The skill will:

1. **Scan** for existing config, project files, quality tools, and sensitive files.
2. **Ask** targeted questions about anything it can’t determine from the directory contents.
3. **Create** these files:
   - `.claude/settings.json` — permissions, hooks (if a formatter was detected), cost-optimization env vars
   - `CLAUDE.md` — slim project instructions (typically 20–40 lines), including a Key Config Files table
   - `AGENTS.md` — only if a multi-tool AI environment is detected or mentioned
   - `.gitignore` additions for personal Claude Code files
   - `scripts/sync-config-table.sh` — keeps the Key Config Files table in CLAUDE.md in sync with the filesystem
   - `.githooks/pre-commit` — runs the sync script before each commit
4. **Activate** the git hooks directory: `git config core.hooksPath .githooks` (run automatically, once per clone).
5. **Summarize** what was created, what was left out, and what to do next.

It deliberately does **not** set up MCP servers, create skills, or generate content it can’t verify. Those decisions are premature for an empty project.

### `/cc-optimize` — Audit and improve an existing setup

After your project has some code (or anytime you want to check the config):

```
/cc-optimize
```

Or focused on a specific area:

```
/cc-optimize CLAUDE.md
/cc-optimize hooks
/cc-optimize costs
```

The skill will:

1. **Inventory** every configuration file, the project’s tech stack, and available context (code, docs, OpenSpec specs).
2. **Analyze** against best practices, checking for bloat, missing essentials, security gaps, cost optimization opportunities, and multi-tool consistency.
3. **Present** findings grouped as must fix / should fix / nice to have, with explanations for each.
4. **Wait for your approval** before changing anything.
5. **Apply** approved changes with before/after summaries.
6. **Report** metrics (e.g., "CLAUDE.md: 247 lines → 62 lines").

### Recommended workflow

```
Day 1:    /cc-init                     ← Bootstrap config for empty project
          ... start coding ...

Week 1:   /cc-optimize                 ← First optimization pass with real code context
          ... continue building ...

Ongoing:  /cc-optimize                 ← Periodic hygiene checks
          /cc-optimize CLAUDE.md       ← After CLAUDE.md has grown significantly
          /cc-optimize costs           ← When token spend feels high
```

## What the skills create and check

### Configuration files

| File                           | Created by | Purpose                                                          |
| ------------------------------ | ---------- | ---------------------------------------------------------------- |
| `CLAUDE.md`                    | `/cc-init` | Project instructions, loaded every message (target: 40–80 lines) |
| `AGENTS.md`                    | `/cc-init` | Vendor-neutral agent instructions (if multi-tool environment)    |
| `.claude/settings.json`        | `/cc-init` | Permissions, hooks, environment variables                        |
| `scripts/sync-config-table.sh` | `/cc-init` | Keeps the Key Config Files table in CLAUDE.md in sync            |
| `.githooks/pre-commit`         | `/cc-init` | Runs the sync script before each commit                          |
| `.claude/skills/*`             | manual     | Recurring workflows (audited by `/cc-optimize`)                  |
| `.mcp.json`                    | manual     | MCP server configuration (audited by `/cc-optimize`)             |

### Key best practices applied

- **Lean CLAUDE.md**: every line costs tokens on every message. Remove anything the linter enforces, Claude already knows, or that’s only relevant sometimes (move to a skill).
- **Progressive disclosure**: use `@`-imports for reference docs instead of inlining them. Reduces token waste by up to 59%.
- **`permissions.deny`**: block `.env`, secrets, and destructive commands. Replaces the deprecated `ignorePatterns`.
- **Formatter hooks**: deterministic PostToolUse hooks beat instructions like "always run prettier" — the hook runs every time, the instruction might be ignored.
- **Cost-optimization defaults**: auto-compact at 50% instead of the default 83%, capped thinking tokens, optional Haiku subagents.
- **Verification loops**: test commands in CLAUDE.md so Claude can verify its own work (2–3× quality improvement).
- **Key Config Files auto-sync**: a pre-commit hook keeps the config file table in CLAUDE.md current — new files get a `TODO` placeholder, deleted files are removed automatically. Uses `.githooks/` (no Husky dependency). Requires one-time activation per clone: `git config core.hooksPath .githooks`.

## Compatibility

- Works with any programming language, framework, or build tool.
- Supports projects using [OpenSpec](https://github.com/Fission-AI/OpenSpec/) for structured change management.
- Supports multi-tool AI environments (Codex, Gemini, Cursor, Copilot) via AGENTS.md.
- Requires Claude Code (CLI or VS Code extension).

## Contributing

Issues and pull requests are welcome. If you’ve found a best practice that isn’t covered, or a pattern that the skills should detect, please open an issue.

## License

[MIT](LICENSE)
