<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/logo-dark.svg" />
    <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/logo.svg" width="220" alt="clever [cc] plugins" />
  </picture>
</p>

# <img src="assets/icon.svg" width="40" height="40" align="top" alt="" />&nbsp;cc-config

A [Claude Code](https://claude.ai/code) plugin with two skills for setting up and maintaining a best-practice Claude Code configuration. Think of it as linting for the files that tell your linter what to do.

**`/cc-config:bootstrapping-config`** bootstraps a lean configuration for a new or unconfigured project. It's a more opinionated alternative to the built-in `/init`.

**`/cc-config:auditing-config`** audits and improves an existing configuration against current best practices. Run it after a project has grown, or periodically to catch config drift.

Both skills work for software projects and for content projects (static sites, article collections, documentation sets backed by a shared knowledge base). Detection covers code toolchains (npm, cargo, pip, composer, go, and more) and content toolchains (Hugo, Jekyll, Astro, Eleventy, MkDocs, Vale, markdownlint).

Both skills draw on the consolidated recommendations from the [official Claude Code docs](https://code.claude.com/docs/en/best-practices), [Anthropic's engineering blog](https://www.anthropic.com/engineering), community configurations, and academic research on agent instruction design.

> **Breaking change (v1.0.0):** Skill names dropped the `cc-config-` prefix (`cc-config-init` became `bootstrapping-config`, and `cc-config-optimize` became `auditing-config`). Claude Code already namespaces plugin skills as `cc-config:<skill-name>`, so the prefix was redundant. Update any saved `/cc-config-...` invocations to the new short names.

## At a Glance

| Skill                             | Use it when                            | What it does                                                                                                                                            |
| --------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/cc-config:bootstrapping-config` | Starting a new or unconfigured project | Creates a lean `CLAUDE.md`, hardened permissions, formatter hooks, and cost-optimization defaults                                                       |
| `/cc-config:auditing-config`      | Auditing an existing setup             | Inventories every config file, flags anti-patterns, and reports findings in three tiers (must fix, should fix, nice to have) before it touches anything |

## Table of Contents

- [cc-config](#cc-config)
  - [At a Glance](#at-a-glance)
  - [Table of Contents](#table-of-contents)
  - [What Problem Do These Skills Solve?](#what-problem-do-these-skills-solve)
  - [Installation](#installation)
    - [Keeping Skills Current](#keeping-skills-current)
    - [Uninstalling](#uninstalling)
  - [Usage](#usage)
    - [`/cc-config:bootstrapping-config`: Bootstrap a New Project](#cc-configbootstrapping-config-bootstrap-a-new-project)
    - [`/cc-config:auditing-config`: Audit and Improve an Existing Setup](#cc-configauditing-config-audit-and-improve-an-existing-setup)
    - [Recommended Workflow](#recommended-workflow)
  - [Working with Design Systems](#working-with-design-systems)
    - [The Two Design Artifacts and Where They Live](#the-two-design-artifacts-and-where-they-live)
    - [Ordering Guideline](#ordering-guideline)
      - [A: Design First, Then Code (Most Common)](#a-design-first-then-code-most-common)
      - [B: Code First, Design Later](#b-code-first-design-later)
      - [C: No Claude Design, but an Existing DESIGN.md](#c-no-claude-design-but-an-existing-designmd)
      - [The Two Rules That Cover Every Case](#the-two-rules-that-cover-every-case)
  - [What the Skills Create and Check](#what-the-skills-create-and-check)
    - [Configuration Files](#configuration-files)
    - [Key Best Practices Applied](#key-best-practices-applied)
  - [Compatibility](#compatibility)
  - [Contributing](#contributing)
  - [License](#license)

## What Problem Do These Skills Solve?

The built-in `/init` generates a `CLAUDE.md` by scanning your repository. The result is often verbose, generic, and stuffed with information that Claude already knows, so it burns context tokens on every single message. `/init` also gives you no guidance on permissions, hooks, cost optimization, or the rest of the configuration surface beyond `CLAUDE.md`.

These skills take a different approach:

- **`/cc-config:bootstrapping-config`** creates the minimum viable configuration that is correct from day one: a slim `CLAUDE.md`, a hardened `permissions.deny`, a formatter hook if applicable, and cost-optimization defaults. It asks targeted questions instead of guessing, and it leaves TODO placeholders for commands it can't verify.

- **`/cc-config:auditing-config`** treats your existing configuration as a codebase to audit. It inventories every config file, measures the line count of `CLAUDE.md`, and checks for known anti-patterns (bloat, missing hooks, hardcoded secrets, deprecated settings). It presents the findings in three tiers (must fix, should fix, nice to have) before it touches anything.

## Installation

Open Claude Code in any project and run:

```
/plugin marketplace add clever-cc-plugins/marketplace
/plugin install cc-config@clever-cc-plugins
```

Both skills, `/cc-config:bootstrapping-config` and `/cc-config:auditing-config`, are available immediately. After you run `/cc-config:bootstrapping-config`, your project contains additional files (see [What the Skills Create and Check](#what-the-skills-create-and-check)).

### Keeping Skills Current

Auto-update is off by default for third-party marketplaces. To switch it on:

1. Run `/plugin` in Claude Code
2. Open the **Marketplaces** tab
3. Toggle auto-update for `clever-cc-plugins/marketplace`

Once it's on, Claude Code updates the skills on startup whenever a new version is available.

### Uninstalling

```
/plugin uninstall cc-config@clever-cc-plugins
```

To remove the marketplace as well (this uninstalls every plugin you installed from it):

```
/plugin marketplace remove clever-cc-plugins
```

## Usage

### `/cc-config:bootstrapping-config`: Bootstrap a New Project

Start Claude Code in your project directory and invoke the skill:

```
/cc-config:bootstrapping-config
```

You can add a brief project description to skip some questions:

```
/cc-config:bootstrapping-config Next.js 14 e-commerce platform with Stripe and Postgres
/cc-config:bootstrapping-config Hugo site, 20 tutorial articles built from a shared knowledge base, output as Markdown
```

The skill will:

1. **Scan** for existing config, project files, quality tools, sensitive files, and design system artifacts (`DESIGN.md`, `context/design/`).
2. **Ask** targeted questions about anything it can't determine. That includes whether you have shared domain knowledge (brand voice, ICP, architecture decisions, API contracts) that should live in a shared context folder for all future skills to reference.
3. **Create** these files:
   - `.claude/settings.json` with permissions, hooks (if it detected a formatter), and cost-optimization env vars
   - `CLAUDE.md` as slim project instructions (typically 20 to 40 lines), including a Key Config Files table and a Learnings section
   - `context/` as an optional shared domain context folder at the project root (brand, architecture, and so on) with placeholder files, if you confirm that there is domain knowledge to capture. It's registered in a `## Context files` table in `CLAUDE.md` so skills can discover it
   - `AGENTS.md`, only if it detects or you mention a multi-tool AI environment
   - `.gitignore` additions for personal Claude Code files
   - `scripts/sync-config-table.sh`, which keeps the Key Config Files table in `CLAUDE.md` in sync with the filesystem (including `DESIGN.md` and `context/` files)
   - `.githooks/pre-commit`, which runs the sync script before each commit
4. **Wire** `DESIGN.md` into `CLAUDE.md` via `@`-import if the file exists at the project root, so Claude consults the design system when it builds UI.
5. **Offer GitHub Actions** (for GitHub-hosted projects): asks once whether to add `claude-code-review.yml` (review of every pull request) and `claude.yml` (the `@claude` mention in issues and PRs). Both need a `CLAUDE_CODE_OAUTH_TOKEN` repository secret.
6. **Offer auto-pull on session start** (if the project is a git repo with a remote): asks once whether you work on this repo from multiple machines and want a fetch and fast-forward at the start of every session. It's opt-in and stored in the gitignored `.claude/settings.local.json`. It never merges or rebases, and it skips with a message if the history has diverged.
7. **Activate** the git hooks directory: `git config core.hooksPath .githooks` (run automatically, once per clone).
8. **Summarize** what it created, what it left out, and the high-leverage next steps, including a pointer to the `/schedule` skill for automating recurring multi-step workflows.

It deliberately does **not** set up MCP servers, create skills, or generate content it can't verify. In an empty project, those decisions are premature.

### `/cc-config:auditing-config`: Audit and Improve an Existing Setup

Run it after your project has some code, or any time you want to check the config:

```
/cc-config:auditing-config
```

You can also focus it on a specific area:

```
/cc-config:auditing-config CLAUDE.md
/cc-config:auditing-config hooks
/cc-config:auditing-config costs
```

The skill will:

1. **Recall** learnings stored in `.claude/learnings.md` from earlier runs.
2. **Inventory and analyze** every configuration file, the design system artifacts (`DESIGN.md`, `context/design/`), the project's tech stack, and the available context (code, docs, OpenSpec specs). It counts the entries in `.claude/learnings.md` and checks for bloat, missing essentials (including a Learnings section and an unreferenced `DESIGN.md`), security gaps, cost-optimization opportunities, and multi-tool consistency. For git repos with a remote that haven't opted in yet, it also checks whether auto-pull on session start would help.
3. **Review learnings:** if `.claude/learnings.md` exists, it groups the entries into recurring patterns and one-offs, proposes promoting the patterns into `CLAUDE.md`, a skill, or a hook, and then proposes deleting the resolved entries.
4. **Present** the findings grouped as must fix, should fix, and nice to have, with an explanation for each, plus a config health score from 0 to 100.
5. **Wait for your approval** before it changes anything.
6. **Apply** the approved changes with before and after summaries.
7. **Report** metrics, for example "CLAUDE.md: 247 lines to 62 lines", "Learnings: 8 entries to 0", or "Config health: 62/100 to 91/100".

### Recommended Workflow

```
Day 1:    /cc-config:bootstrapping-config           # bootstrap the config for an empty project
          ... start coding ...

Week 1:   /cc-config:auditing-config                # first optimization pass with real code context
          ... continue building ...

Ongoing:  /cc-config:auditing-config                # periodic hygiene checks
          /cc-config:auditing-config CLAUDE.md      # after CLAUDE.md has grown significantly
          /cc-config:auditing-config costs          # when token spend feels high
```

## Working with Design Systems

### The Two Design Artifacts and Where They Live

| Artifact                        | Where it lives    | What it is                                                                                                                                                                                         |
| ------------------------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DESIGN.md`                     | Project root      | Persistent design system spec (YAML tokens plus Markdown rationale). Claude Code, Cursor, Copilot, and other agents read it automatically. Think of it as `tsconfig.json` for your visual language |
| Claude Design handoff artifacts | `context/design/` | Point-in-time exports from Claude Design: `PROMPT.md`, `design-notes.md`, `screenshots/`. They are versioned alongside the code and stay out of the root clutter                                   |

`DESIGN.md` is an open-source format that originated at Google Stitch and has been adopted broadly. Claude Design's "Handoff to Claude Code" export produces a bundle of implementation-ready artifacts. The two artifacts complement each other.

### Ordering Guideline

#### A: Design First, Then Code (Most Common)

You finished (or sketched) the design in Claude Design before you set up the project config.

1. Export or author `DESIGN.md` and place it at the **project root**.
2. Place the Claude Design handoff artifacts (`PROMPT.md`, `design-notes.md`, `screenshots/`) in **`context/design/`**. Create the folder manually if needed.
3. Run **`/cc-config:bootstrapping-config`**. It detects `DESIGN.md` during the scan, wires it into `CLAUDE.md` with the right `@`-import trigger, and includes both `DESIGN.md` and the `context/design/` files in the Key Config Files table.

#### B: Code First, Design Later

You bootstrapped the project first and are adding a design system later.

1. Run **`/cc-config:bootstrapping-config`** as usual to set up the project config.
2. When the design is ready, place `DESIGN.md` at the project root and the handoff artifacts in `context/design/`.
3. Run **`/cc-config:auditing-config`**. It detects the unreferenced `DESIGN.md` and flags it as "should fix". Approve the suggestion, and it adds the `@`-import to `CLAUDE.md` and updates the Key Config Files table.

#### C: No Claude Design, but an Existing DESIGN.md

You use a different tool (Figma plus Stitch, hand-authored tokens, and so on) that already produced a `DESIGN.md`.

1. Place `DESIGN.md` at the **project root** before you run `/cc-config:bootstrapping-config`.
2. Run **`/cc-config:bootstrapping-config`**. It picks the file up automatically, and no extra steps are needed.

#### The Two Rules That Cover Every Case

1. **`DESIGN.md` always lives at the project root.** That's the community convention, and agents discover the file there without any configuration.
2. **Claude Design handoff artifacts always live in `context/design/`.** That keeps them versioned, organized, and visible in the Key Config Files table without cluttering the root.

If you add design artifacts after you ran `/cc-config:bootstrapping-config`, a single `/cc-config:auditing-config` pass closes the gap.

## What the Skills Create and Check

### Configuration Files

| File                                                        | Created by                                                                          | Purpose                                                                                                                                                               |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE.md`                                                 | `/cc-config:bootstrapping-config`                                                   | Project instructions, loaded on every message (target: 20 to 40 lines at the start, and the audit flags more than 80 lines without good reason)                       |
| `AGENTS.md`                                                 | `/cc-config:bootstrapping-config`                                                   | Vendor-neutral agent instructions (if multi-tool environment)                                                                                                         |
| `DESIGN.md`                                                 | Manual or design tool                                                               | Design system spec (YAML tokens plus Markdown rationale), wired into `CLAUDE.md` via `@`-import by `/cc-config:bootstrapping-config` and `/cc-config:auditing-config` |
| `.claude/settings.json`                                     | `/cc-config:bootstrapping-config`                                                   | Permissions, hooks, environment variables                                                                                                                             |
| `context/`                                                  | `/cc-config:bootstrapping-config` (optional)                                        | Shared domain context folder at the project root (brand, architecture, and so on), registered in a `## Context files` table in `CLAUDE.md`                            |
| `context/design/`                                           | Manual                                                                              | Claude Design handoff artifacts: `PROMPT.md`, `design-notes.md`, `screenshots/`                                                                                       |
| `.claude/learnings.md`                                      | Automatic (by skills)                                                               | Project-specific observations that skills store at the end of a run. It also captures user corrections instead of `CLAUDE.md` edits                                   |
| `scripts/sync-config-table.sh`                              | `/cc-config:bootstrapping-config`                                                   | Keeps the Key Config Files table in `CLAUDE.md` in sync, including `DESIGN.md` and `context/` files                                                                   |
| `.githooks/pre-commit`                                      | `/cc-config:bootstrapping-config`                                                   | Runs the sync script before each commit and stages `CLAUDE.md` automatically when the table changes                                                                   |
| `.claude/skills/*`                                          | Manual                                                                              | Recurring workflows (audited by `/cc-config:auditing-config`)                                                                                                         |
| `.claude/agents/*`                                          | Manual                                                                              | Custom subagent definitions (audited by `/cc-config:auditing-config` for unreferenced or overprivileged agents)                                                       |
| `.mcp.json`                                                 | Manual                                                                              | MCP server configuration (audited by `/cc-config:auditing-config`)                                                                                                    |
| `<!-- cc-config: last-optimize-run -->` marker              | `/cc-config:bootstrapping-config` and `/cc-config:auditing-config`                  | Baseline (date and commit SHA) in `CLAUDE.md` that the bundled `SessionStart` staleness-reminder hook compares against                                                |
| `.claude/settings.local.json` `env.CC_CONFIG_AUTO_GIT_PULL` | `/cc-config:bootstrapping-config` or `/cc-config:auditing-config` (optional, asked) | Personal, gitignored opt-in flag that enables the bundled auto-pull hook for this machine                                                                             |

### Key Best Practices Applied

- **Lean `CLAUDE.md`:** every line costs tokens on every message. Remove anything that the linter enforces, that Claude already knows, or that only matters sometimes (move that to a skill).
- **On-demand loading:** Claude Code expands `@`-imports into the context together with the importing file, so they organize `CLAUDE.md` and save no tokens. Material that only matters sometimes goes into path-scoped `.claude/rules/` files (`paths:` frontmatter) or into skills.
- **Domain context folder:** shared knowledge (brand voice, ICP, architecture decisions, API contracts) lives in `context/` at the project root. It's registered in a `## Context files` table in `CLAUDE.md`, so skills can discover the files and load them on demand. Claude Design handoff artifacts belong in `context/design/`.
- **Design system integration:** `DESIGN.md` at the project root is imported into `CLAUDE.md` via `@DESIGN.md` (or loaded by a path-scoped rule if it's large). Without one of these, Claude ignores the file for design decisions.
- **`permissions.deny`:** blocks `.env`, secrets, and destructive commands. It replaces the deprecated `ignorePatterns`.
- **Formatter hooks:** a deterministic `PostToolUse` hook beats an instruction like "always run prettier". The hook runs every time, while Claude might ignore the instruction.
- **Cost-optimization defaults:** an optional Haiku model for subagents (`CLAUDE_CODE_SUBAGENT_MODEL`), and a note to leave `alwaysThinkingEnabled` and `effortLevel` alone unless you need deep reasoning on every turn. `MAX_THINKING_TOKENS` is no longer recommended because current models ignore it. `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` can only lower the threshold and is likely a no-op in a typical local session.
- **Verification loops:** test commands in `CLAUDE.md` give Claude a feedback loop to check its own work. The bootstrapping skill treats this as the single most impactful principle, though no measured effect size backs it up.
- **Key Config Files auto-sync:** a pre-commit hook keeps the config file table in `CLAUDE.md` current. New files get a `TODO` placeholder, and deleted files are removed automatically. The table covers `DESIGN.md` and `context/` subdirectories. The setup uses `.githooks/` and needs no Husky dependency. It requires a one-time activation per clone, `git config core.hooksPath .githooks`, and every collaborator must run it after cloning. Without it, git skips the hook silently.
- **Learnings graduation:** at the end of each run, these skills review and store project-specific observations in `.claude/learnings.md`, and they recall the stored learnings at the start of the next run. When you correct a mistake, Claude appends a one-line correction instead of editing `CLAUDE.md`. `/cc-config:auditing-config` reviews the file: recurring patterns graduate into `CLAUDE.md` rules, skills, or hooks, and one-off entries get deleted. This keeps `CLAUDE.md` stable between audits.
- **Skill feedback loops:** the skills implement an Observe-Notice-Store-Recall (ONSR) loop. They store learnings at the end of a run and recall them at the start of the next one, with no manual action. A terminal feedback question still asks for explicit corrections at the point of delivery.
- **Audit staleness reminder:** the plugin bundles a `SessionStart` hook that fires in every project where the plugin is active. It needs no per-repo `settings.json` wiring, even if you only install `cc-config` at the user level. The hook compares a `last-optimize-run` marker (written by `/cc-config:bootstrapping-config` and `/cc-config:auditing-config` when they complete) against the repo's current commits and date. Once drift crosses a threshold (default: 20 or more commits, or 14 or more days with new activity), it nudges you to run `/cc-config:auditing-config`. It stays silent otherwise, and in repos that haven't opted into `cc-config`.
- **Auto-pull on session start (opt-in):** for multi-machine workflows where you sometimes forget to `git pull` before a session, the plugin bundles a second `SessionStart` hook that fetches and fast-forwards the current branch when you enable it. It's off by default. `/cc-config:bootstrapping-config` asks once for new git repos with a remote, and `/cc-config:auditing-config` suggests it for existing ones. Enabling it writes `CC_CONFIG_AUTO_GIT_PULL=true` to the gitignored `.claude/settings.local.json`, which makes it a personal, per-machine setting and no project convention. The hook never merges or rebases. On a dirty working tree or a diverged history, it skips the pull, reports why, and leaves the reconciliation to you or the agent.
- **Scheduling:** once recurring multi-step workflows emerge, the `/schedule` skill can automate them. It runs a chain of skills on a cron schedule and lands the output in a review folder for human sign-off.

## Compatibility

- Works with any programming language, framework, or build tool.
- Works with content projects: static-site generators (Hugo, Jekyll, Astro, Eleventy, MkDocs), article collections, documentation sets, and Markdown-driven workflows. Register knowledge bases and style guides in a `## Context files` table so skills load them on demand instead of on every message.
- Works with design-system-driven projects: it detects `DESIGN.md` at the project root and Claude Design handoff artifacts in `context/design/`, and wires them into `CLAUDE.md` correctly.
- Supports projects that use [OpenSpec](https://github.com/Fission-AI/OpenSpec/) for structured change management.
- Supports multi-tool AI environments (Codex, Gemini, Cursor, Copilot) via `AGENTS.md`.
- Requires Claude Code (CLI or IDE extension).

## Contributing

Issues and pull requests are welcome. If you've found a best practice that isn't covered, or a pattern that the skills should detect, please open an issue first so we can agree on the approach.

## License

[MIT](LICENSE), Copyright (c) 2026 Michael van Laar

---

<p align="center">
  Part of the <a href="https://github.com/clever-cc-plugins">clever-cc-plugins</a> family · <a href="https://github.com/clever-cc-plugins/marketplace">marketplace</a> · <a href="https://github.com/clever-cc-plugins/cc-concept">cc-concept</a> · <a href="https://github.com/clever-cc-plugins/cc-content">cc-content</a> · <a href="https://github.com/clever-cc-plugins/cc-career">cc-career</a> · <a href="https://github.com/clever-cc-plugins/cc-coach">cc-coach</a> · <a href="https://github.com/clever-cc-plugins/cc-handoff">cc-handoff</a> · <a href="https://github.com/clever-cc-plugins/cc-chime">cc-chime</a> · <a href="https://github.com/clever-cc-plugins/cc-chef">cc-chef</a>
</p>
