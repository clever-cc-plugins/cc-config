# claude-code-config-skills

Three Claude Code skills for setting up and maintaining a best-practice Claude Code configuration.

**`/cc-config:init`** bootstraps a lean configuration for a new or unconfigured project — a more opinionated alternative to the built-in `/init`.

**`/cc-config:optimize`** audits and improves an existing configuration against current best practices — useful after a project has grown, or periodically to prevent config drift.

**`/cc-config:update`** fetches the latest versions of all installed skills from this repository — run it any time you want to pick up improvements.

All three skills work for software projects **and** content projects (static sites, article collections, documentation sets backed by a shared knowledge base). Detection covers code toolchains (npm, cargo, pip, composer, go, …) and content toolchains (Hugo, Jekyll, Astro, Eleventy, MkDocs, Vale, markdownlint).

All three skills are grounded in the consolidated recommendations from the [official Claude Code docs](https://code.claude.com/docs/en/best-practices), [Anthropic's engineering blog](https://www.anthropic.com/engineering), community configurations, and academic research on agent instruction design.

## Table of Contents

- [What problem do these skills solve?](#what-problem-do-these-skills-solve)
- [Installation](#installation)
- [Usage](#usage)
  - [`/cc-config:init` — Bootstrap a new project](#cc-init--bootstrap-a-new-project)
  - [`/cc-config:optimize` — Audit and improve an existing setup](#cc-optimize--audit-and-improve-an-existing-setup)
  - [`/cc-config:update` — Keep skills current](#cc-update--keep-skills-current)
  - [Recommended workflow](#recommended-workflow)
- [Working with design systems](#working-with-design-systems)
  - [The two design artifacts and where they live](#the-two-design-artifacts-and-where-they-live)
  - [Ordering guideline](#ordering-guideline)
- [What the skills create and check](#what-the-skills-create-and-check)
  - [Configuration files](#configuration-files)
  - [Key best practices applied](#key-best-practices-applied)
- [Compatibility](#compatibility)
- [Contributing](#contributing)
- [License](#license)

## What problem do these skills solve?

The built-in `/init` generates a CLAUDE.md by scanning your repository. The result is often verbose, generic, and stuffed with information Claude already knows — burning context tokens on every single message. There's also no guidance on permissions, hooks, cost optimization, or the broader configuration surface beyond CLAUDE.md.

These skills take a different approach:

- **`/cc-config:init`** creates the minimum viable configuration that's correct from day one: a slim CLAUDE.md, hardened `permissions.deny`, a formatter hook if applicable, and cost-optimization defaults. It asks targeted questions instead of guessing, and uses TODO placeholders rather than hallucinating commands it can't verify.

- **`/cc-config:optimize`** treats your existing configuration as a codebase to audit. It inventories every config file, measures CLAUDE.md line count, checks for known anti-patterns (bloat, missing hooks, hardcoded secrets, deprecated settings), and presents findings in three tiers — must fix, should fix, nice to have — before touching anything.

## Installation

Run the install script from your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/MichaelvanLaar/claude-code-config-skills/main/install.sh | bash
```

This downloads `init`, `optimize`, and `update` into `.claude/skills/cc-config/`.

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
        └── cc-config/
            ├── init/
            │   └── SKILL.md
            ├── optimize/
            │   └── SKILL.md
            └── update/
                └── SKILL.md
```

After running `/cc-config:init`, additional files are created in your project (see [What the skills create and check](#what-the-skills-create-and-check)).

## Usage

### `/cc-config:init` — Bootstrap a new project

Start Claude Code in your project directory and invoke the skill:

```
/cc-config:init
```

Or with a brief project description to skip some questions:

```
/cc-config:init Next.js 14 e-commerce platform with Stripe and Postgres
/cc-config:init Hugo site, 20 tutorial articles built from a shared knowledge base, output as Markdown
```

The skill will:

1. **Scan** for existing config, project files, quality tools, sensitive files, and design system artifacts (`DESIGN.md`, `.claude/context/design/`).
2. **Ask** targeted questions about anything it can't determine — including whether there is shared domain knowledge (brand voice, ICP, architecture decisions, API contracts) that should live in a shared context folder for all future skills to reference.
3. **Create** these files:
   - `.claude/settings.json` — permissions, hooks (if a formatter was detected), cost-optimization env vars
   - `CLAUDE.md` — slim project instructions (typically 20–40 lines), including a Key Config Files table and a Learnings section
   - `.claude/context/` — optional shared domain context folder (brand, architecture, etc.) with placeholder files, if the user confirms domain knowledge to capture; Claude Design handoff artifacts belong in `.claude/context/design/`
   - `AGENTS.md` — only if a multi-tool AI environment is detected or mentioned
   - `.gitignore` additions for personal Claude Code files
   - `scripts/sync-config-table.sh` — keeps the Key Config Files table in CLAUDE.md in sync with the filesystem (including `DESIGN.md` and `.claude/context/` files)
   - `.githooks/pre-commit` — runs the sync script before each commit
4. **Wire** `DESIGN.md` into CLAUDE.md via `@`-import if the file exists at the project root, so Claude automatically consults the design system when building UI.
5. **Activate** the git hooks directory: `git config core.hooksPath .githooks` (run automatically, once per clone).
6. **Summarize** what was created, what was left out, and four high-leverage next steps — including a pointer to the `/schedule` skill for automating recurring multi-step workflows.

It deliberately does **not** set up MCP servers, create skills, or generate content it can't verify. Those decisions are premature for an empty project.

### `/cc-config:optimize` — Audit and improve an existing setup

After your project has some code (or anytime you want to check the config):

```
/cc-config:optimize
```

Or focused on a specific area:

```
/cc-config:optimize CLAUDE.md
/cc-config:optimize hooks
/cc-config:optimize costs
```

The skill will:

1. **Inventory** every configuration file, design system artifacts (`DESIGN.md`, `.claude/context/design/`), the project's tech stack, and available context (code, docs, OpenSpec specs). This now includes `.claude/learnings.md` and reports the number of entries it contains.
2. **Analyze** against best practices, checking for bloat, missing essentials (including a Learnings section and an unreferenced `DESIGN.md`), security gaps, cost optimization opportunities, and multi-tool consistency.
3. **Review learnings**: if `.claude/learnings.md` exists, group entries into recurring patterns vs. one-offs and propose promoting patterns into CLAUDE.md, a skill, or a hook — then deleting resolved entries.
4. **Present** findings grouped as must fix / should fix / nice to have, with explanations for each.
5. **Wait for your approval** before changing anything.
6. **Apply** approved changes with before/after summaries.
7. **Report** metrics (e.g., "CLAUDE.md: 247 lines → 62 lines", "Learnings: 8 entries → 0").

### `/cc-config:update` — Keep skills current

After the initial install, run this from within Claude Code any time you want to pull the latest versions:

```
/cc-config:update
```

It updates `cc-config:init`, `cc-config:optimize`, and itself — only for skills already installed in the project. Skills you have not installed are left alone.

### Recommended workflow

```
Day 1:    /cc-config:init                     ← Bootstrap config for empty project
          ... start coding ...

Week 1:   /cc-config:optimize                 ← First optimization pass with real code context
          ... continue building ...

Ongoing:  /cc-config:optimize                 ← Periodic hygiene checks
          /cc-config:optimize CLAUDE.md       ← After CLAUDE.md has grown significantly
          /cc-config:optimize costs           ← When token spend feels high
          /cc-config:update                   ← After pulling updates from this repo
```

## Working with design systems

### The two design artifacts and where they live

| Artifact                        | Where it lives            | What it is                                                                                                                                                                                |
| ------------------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DESIGN.md`                     | Project root              | Persistent design system spec — YAML tokens + Markdown rationale. Auto-read by Claude Code, Cursor, Copilot, and other agents. Think of it like `tsconfig.json` for your visual language. |
| Claude Design handoff artifacts | `.claude/context/design/` | Point-in-time exports from Claude Design: `PROMPT.md`, `design-notes.md`, `screenshots/`. Versioned alongside code, out of root clutter.                                                  |

`DESIGN.md` is an open-source format (originated from Google Stitch, broadly adopted). Claude Design's "Handoff to Claude Code" export produces a bundle of implementation-ready artifacts — these two things are complementary, not competing.

### Ordering guideline

#### A — Design first, then code (most common)

You have finished (or sketched) the design in Claude Design before setting up the project config.

1. Export or author `DESIGN.md` and place it at the **project root**.
2. Place Claude Design handoff artifacts (`PROMPT.md`, `design-notes.md`, `screenshots/`) in **`.claude/context/design/`** — create the folder manually if needed.
3. Run **`/cc-config:init`**. It detects `DESIGN.md` during the scan, wires it into CLAUDE.md with the right `@`-import trigger, and includes both `DESIGN.md` and `.claude/context/design/` files in the Key Config Files table automatically.

#### B — Code first, design later

You bootstrapped the project first and are adding a design system later.

1. Run **`/cc-config:init`** as usual to set up the project config.
2. When the design is ready: place `DESIGN.md` at the project root and handoff artifacts in `.claude/context/design/`.
3. Run **`/cc-config:optimize`**. It detects the unreferenced `DESIGN.md` and flags it as "should fix" — approve the suggestion and it adds the `@`-import to CLAUDE.md and updates the Key Config Files table.

#### C — No Claude Design, but an existing DESIGN.md

You use a different tool (Figma + Stitch, hand-authored tokens, etc.) that already produced a `DESIGN.md`.

1. Place `DESIGN.md` at the **project root** before running `/cc-config:init`.
2. Run **`/cc-config:init`** — it picks it up automatically. No extra steps needed.

#### The two rules that cover every case

1. **`DESIGN.md` always lives at the project root** — this is the community convention; agents discover it there without any configuration.
2. **Claude Design handoff artifacts always live in `.claude/context/design/`** — this keeps them versioned, organized, and visible in the Key Config Files table without polluting the root.

If you add design artifacts after running `/cc-config:init`, a single `/cc-config:optimize` pass closes the gap.

## What the skills create and check

### Configuration files

| File                              | Created by                   | Purpose                                                                                                                                   |
| --------------------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE.md`                       | `/cc-config:init`            | Project instructions, loaded every message (target: 40–80 lines)                                                                          |
| `AGENTS.md`                       | `/cc-config:init`            | Vendor-neutral agent instructions (if multi-tool environment)                                                                             |
| `DESIGN.md`                       | manual / design tool         | Design system spec — YAML tokens + Markdown rationale; wired into CLAUDE.md via `@`-import by `/cc-config:init` and `/cc-config:optimize` |
| `.claude/settings.json`           | `/cc-config:init`            | Permissions, hooks, environment variables                                                                                                 |
| `.claude/context/`                | `/cc-config:init` (optional) | Shared domain context folder — brand, architecture, etc.; skills reference files here via progressive disclosure                          |
| `.claude/context/design/`         | manual (user)                | Claude Design handoff artifacts: `PROMPT.md`, `design-notes.md`, `screenshots/`                                                           |
| `.claude/learnings.md`            | auto (by Claude)             | One-line corrections Claude appends instead of modifying CLAUDE.md directly                                                               |
| `scripts/sync-config-table.sh`    | `/cc-config:init`            | Keeps the Key Config Files table in CLAUDE.md in sync — including `DESIGN.md` and `.claude/context/` files                                |
| `.githooks/pre-commit`            | `/cc-config:init`            | Runs the sync script before each commit                                                                                                   |
| `.claude/skills/cc-config/update` | `install.sh`                 | Updates installed skills to their latest versions (`/cc-config:update`)                                                                   |
| `.claude/skills/*`                | manual                       | Recurring workflows (audited by `/cc-config:optimize`)                                                                                    |
| `.mcp.json`                       | manual                       | MCP server configuration (audited by `/cc-config:optimize`)                                                                               |

### Key best practices applied

- **Lean CLAUDE.md**: every line costs tokens on every message. Remove anything the linter enforces, Claude already knows, or that's only relevant sometimes (move to a skill).
- **Progressive disclosure**: use `@`-imports for reference docs instead of inlining them. Reduces token waste by up to 59%.
- **Domain context folder**: shared knowledge (brand voice, ICP, architecture decisions, API contracts) lives in `.claude/context/` — update once, every skill that references it reflects the change. Claude Design handoff artifacts belong in `.claude/context/design/`.
- **Design system integration**: `DESIGN.md` at the project root is wired into CLAUDE.md via `@DESIGN.md **Read when:** building or editing any UI component`. Without this pointer Claude ignores the file for design decisions.
- **`permissions.deny`**: block `.env`, secrets, and destructive commands. Replaces the deprecated `ignorePatterns`.
- **Formatter hooks**: deterministic PostToolUse hooks beat instructions like "always run prettier" — the hook runs every time, the instruction might be ignored.
- **Cost-optimization defaults**: auto-compact at 50% instead of the default 83%, capped thinking tokens, optional Haiku subagents.
- **Verification loops**: test commands in CLAUDE.md so Claude can verify its own work (2–3× quality improvement).
- **Key Config Files auto-sync**: a pre-commit hook keeps the config file table in CLAUDE.md current — new files get a `TODO` placeholder, deleted files are removed automatically. Covers `DESIGN.md` and `.claude/context/` subdirectories. Uses `.githooks/` (no Husky dependency). Requires one-time activation per clone: `git config core.hooksPath .githooks`.
- **Learnings graduation**: when Claude makes a mistake, it appends a one-line correction to `.claude/learnings.md` instead of editing CLAUDE.md directly. Running `/cc-config:optimize` reviews the file: recurring patterns graduate into CLAUDE.md rules, skills, or hooks; one-off entries get deleted. Keeps CLAUDE.md stable between audits.
- **Skill feedback loops**: skills should end with a step that asks for feedback and logs corrections to `.claude/learnings.md`, making the learnings loop active rather than passive.
- **Scheduling**: once recurring multi-step workflows emerge, the `/schedule` skill can automate them — run a chain of skills on a cron schedule and land the output in a review folder for human sign-off.

## Compatibility

- Works with any programming language, framework, or build tool.
- Works with content projects: static-site generators (Hugo, Jekyll, Astro, Eleventy, MkDocs), article collections, documentation sets, and Markdown-driven workflows. Knowledge bases and style guides can be referenced via `@`-imports for progressive disclosure rather than inlined into CLAUDE.md.
- Works with design-system-driven projects: detects `DESIGN.md` at the project root and Claude Design handoff artifacts in `.claude/context/design/`, and wires them into CLAUDE.md correctly.
- Supports projects using [OpenSpec](https://github.com/Fission-AI/OpenSpec/) for structured change management.
- Supports multi-tool AI environments (Codex, Gemini, Cursor, Copilot) via AGENTS.md.
- Requires Claude Code (CLI or VS Code extension).

## Contributing

Issues and pull requests are welcome. If you've found a best practice that isn't covered, or a pattern that the skills should detect, please open an issue.

## License

[MIT](LICENSE)
