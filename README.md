# claude-code-config-skills

Two Claude Code skills for setting up and maintaining a best-practice Claude Code configuration.

**`/cc-init`** bootstraps a lean configuration for a new or unconfigured project — a more opinionated alternative to the built-in `/init`.

**`/cc-optimize`** audits and improves an existing configuration against current best practices — useful after a project has grown, or periodically to prevent config drift.

**`/cc-update`** fetches the latest versions of all installed skills from this repository — run it any time you want to pick up improvements.

All three skills work for software projects **and** content projects (static sites, article collections, documentation sets backed by a shared knowledge base). Detection covers code toolchains (npm, cargo, pip, composer, go, …) and content toolchains (Hugo, Jekyll, Astro, Eleventy, MkDocs, Vale, markdownlint).

All three skills are grounded in the consolidated recommendations from the [official Claude Code docs](https://code.claude.com/docs/en/best-practices), [Anthropic’s engineering blog](https://www.anthropic.com/engineering), community configurations, and academic research on agent instruction design.

## What problem do these skills solve?

The built-in `/init` generates a CLAUDE.md by scanning your repository. The result is often verbose, generic, and stuffed with information Claude already knows — burning context tokens on every single message. There’s also no guidance on permissions, hooks, cost optimization, or the broader configuration surface beyond CLAUDE.md.

These skills take a different approach:

- **`/cc-init`** creates the minimum viable configuration that’s correct from day one: a slim CLAUDE.md, hardened `permissions.deny`, a formatter hook if applicable, and cost-optimization defaults. It asks targeted questions instead of guessing, and uses TODO placeholders rather than hallucinating commands it can’t verify.

- **`/cc-optimize`** treats your existing configuration as a codebase to audit. It inventories every config file, measures CLAUDE.md line count, checks for known anti-patterns (bloat, missing hooks, hardcoded secrets, deprecated settings), and presents findings in three tiers — must fix, should fix, nice to have — before touching anything.

## Installation

Run the install script from your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/MichaelvanLaar/claude-code-config-skills/main/install.sh | bash
```

This downloads `cc-init`, `cc-optimize`, and `cc-update` into `.claude/skills/`.

To install into a specific directory, or to pin to a release tag:

```bash
# Specific directory
curl -fsSL https://raw.githubusercontent.com/MichaelvanLaar/claude-code-config-skills/main/install.sh | bash -s path/to/project

# Pin to a specific tag or commit
curl -fsSL https://raw.githubusercontent.com/MichaelvanLaar/claude-code-config-skills/main/install.sh | REF=v1.0.0 bash
```

If you prefer to inspect the script before running it:

```bash
curl -fsSL https://raw.githubusercontent.com/MichaelvanLaar/claude-code-config-skills/main/install.sh -o install.sh
# Review install.sh, then:
bash install.sh
rm install.sh
```

### Directory structure after installation

```
your-project/
└── .claude/
    └── skills/
        ├── cc-init/
        │   └── SKILL.md
        ├── cc-optimize/
        │   └── SKILL.md
        └── cc-update/
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
/cc-init Hugo site, 20 tutorial articles built from a shared knowledge base, output as Markdown
```

The skill will:

1. **Scan** for existing config, project files, quality tools, and sensitive files.
2. **Ask** targeted questions about anything it can’t determine from the directory contents.
3. **Create** these files:
   - `.claude/settings.json` — permissions, hooks (if a formatter was detected), cost-optimization env vars
   - `CLAUDE.md` — slim project instructions (typically 20–40 lines), including a Key Config Files table and a Learnings section
   - `AGENTS.md` — only if a multi-tool AI environment is detected or mentioned
   - `.gitignore` additions for personal Claude Code files
   - `scripts/sync-config-table.sh` — keeps the Key Config Files table in CLAUDE.md in sync with the filesystem
   - `.githooks/pre-commit` — runs the sync script before each commit
4. **Activate** the git hooks directory: `git config core.hooksPath .githooks` (run automatically, once per clone).
5. **Summarize** what was created, what was left out, and what to do next — including an explanation of the Learnings mechanism.

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

1. **Inventory** every configuration file, the project’s tech stack, and available context (code, docs, OpenSpec specs). This now includes `.claude/learnings.md` and reports the number of entries it contains.
2. **Analyze** against best practices, checking for bloat, missing essentials (including a Learnings section), security gaps, cost optimization opportunities, and multi-tool consistency.
3. **Review learnings**: if `.claude/learnings.md` exists, group entries into recurring patterns vs. one-offs and propose promoting patterns into CLAUDE.md, a skill, or a hook — then deleting resolved entries.
4. **Present** findings grouped as must fix / should fix / nice to have, with explanations for each.
5. **Wait for your approval** before changing anything.
6. **Apply** approved changes with before/after summaries.
7. **Report** metrics (e.g., "CLAUDE.md: 247 lines → 62 lines", "Learnings: 8 entries → 0").

### `/cc-update` — Keep skills current

After the initial install, run this from within Claude Code any time you want to pull the latest versions:

```
/cc-update
```

It updates `cc-init`, `cc-optimize`, and itself — only for skills already installed in the project. Skills you have not installed are left alone.

### Recommended workflow

```
Day 1:    /cc-init                     ← Bootstrap config for empty project
          ... start coding ...

Week 1:   /cc-optimize                 ← First optimization pass with real code context
          ... continue building ...

Ongoing:  /cc-optimize                 ← Periodic hygiene checks
          /cc-optimize CLAUDE.md       ← After CLAUDE.md has grown significantly
          /cc-optimize costs           ← When token spend feels high
          /cc-update                   ← After pulling updates from this repo
```

## What the skills create and check

### Configuration files

| File                           | Created by       | Purpose                                                                     |
| ------------------------------ | ---------------- | --------------------------------------------------------------------------- |
| `CLAUDE.md`                    | `/cc-init`       | Project instructions, loaded every message (target: 40–80 lines)            |
| `AGENTS.md`                    | `/cc-init`       | Vendor-neutral agent instructions (if multi-tool environment)               |
| `.claude/settings.json`        | `/cc-init`       | Permissions, hooks, environment variables                                   |
| `.claude/learnings.md`         | auto (by Claude) | One-line corrections Claude appends instead of modifying CLAUDE.md directly |
| `scripts/sync-config-table.sh` | `/cc-init`       | Keeps the Key Config Files table in CLAUDE.md in sync                       |
| `.githooks/pre-commit`         | `/cc-init`       | Runs the sync script before each commit                                     |
| `.claude/skills/cc-update`     | `install.sh`     | Updates installed skills to their latest versions (`/cc-update`)            |
| `.claude/skills/*`             | manual           | Recurring workflows (audited by `/cc-optimize`)                             |
| `.mcp.json`                    | manual           | MCP server configuration (audited by `/cc-optimize`)                        |

### Key best practices applied

- **Lean CLAUDE.md**: every line costs tokens on every message. Remove anything the linter enforces, Claude already knows, or that’s only relevant sometimes (move to a skill).
- **Progressive disclosure**: use `@`-imports for reference docs instead of inlining them. Reduces token waste by up to 59%.
- **`permissions.deny`**: block `.env`, secrets, and destructive commands. Replaces the deprecated `ignorePatterns`.
- **Formatter hooks**: deterministic PostToolUse hooks beat instructions like "always run prettier" — the hook runs every time, the instruction might be ignored.
- **Cost-optimization defaults**: auto-compact at 50% instead of the default 83%, capped thinking tokens, optional Haiku subagents.
- **Verification loops**: test commands in CLAUDE.md so Claude can verify its own work (2–3× quality improvement).
- **Key Config Files auto-sync**: a pre-commit hook keeps the config file table in CLAUDE.md current — new files get a `TODO` placeholder, deleted files are removed automatically. Uses `.githooks/` (no Husky dependency). Requires one-time activation per clone: `git config core.hooksPath .githooks`.
- **Learnings graduation**: when Claude makes a mistake, it appends a one-line correction to `.claude/learnings.md` instead of editing CLAUDE.md directly. Running `/cc-optimize` reviews the file: recurring patterns graduate into CLAUDE.md rules, skills, or hooks; one-off entries get deleted. Keeps CLAUDE.md stable between audits.

## Compatibility

- Works with any programming language, framework, or build tool.
- Works with content projects: static-site generators (Hugo, Jekyll, Astro, Eleventy, MkDocs), article collections, documentation sets, and Markdown-driven workflows. Knowledge bases and style guides can be referenced via `@`-imports for progressive disclosure rather than inlined into CLAUDE.md.
- Supports projects using [OpenSpec](https://github.com/Fission-AI/OpenSpec/) for structured change management.
- Supports multi-tool AI environments (Codex, Gemini, Cursor, Copilot) via AGENTS.md.
- Requires Claude Code (CLI or VS Code extension).

## Contributing

Issues and pull requests are welcome. If you’ve found a best practice that isn’t covered, or a pattern that the skills should detect, please open an issue.

## License

[MIT](LICENSE)
