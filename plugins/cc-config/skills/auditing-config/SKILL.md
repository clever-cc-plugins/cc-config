---
name: auditing-config
description: Audit and optimize an existing Claude Code configuration against current best practices. Use this skill when a user asks to review, improve, clean up, or optimize their Claude Code setup, CLAUDE.md, settings, hooks, MCP servers, or skills. Also use when the user says things like "check my config", "is my CLAUDE.md too long", "reduce token costs", "tighten permissions", or "my Claude Code setup feels bloated". This skill assumes the project has code, and possibly documentation or OpenSpec specs, that inform the optimization.
allowed-tools: Read, Grep, Glob, Edit(**/CLAUDE.md), Edit(.claude/**), Edit(.githooks/**), Edit(.github/workflows/**), Edit(scripts/sync-config-table.js), Edit(.husky/pre-commit), Edit(AGENTS.md), Edit(.mcp.json), Edit(.gitignore), Edit(scripts/sync-config-table.sh), Write(CLAUDE.md), Write(.claude/**), Write(.githooks/**), Write(.husky/pre-commit), Write(.gitignore), Write(.github/workflows/**), Write(scripts/sync-config-table.sh), Write(scripts/sync-config-table.js), Bash(git rev-parse:*), Bash(git log:*), Bash(git config core.hooksPath:*), Bash(jq:*), Bash(bash scripts/sync-config-table.sh), Bash(test -f:*), Bash(wc:*), Bash(date +%Y-%m-%d), Bash(chmod +x .githooks/pre-commit), Bash(rm .githooks/pre-commit), Bash(rmdir .githooks), Bash(chmod +x scripts/sync-config-table.sh)
argument-hint: "[optional: specific area to focus on, e.g. 'CLAUDE.md', 'hooks', 'costs']"
---

# Optimize Claude Code Configuration

You are auditing and improving an existing Claude Code setup. The project has code, possibly documentation, and possibly OpenSpec specifications. Your job is to identify what's good (preserve it), what's missing, what's bloated, and what violates current best practices — then fix it with the user's approval.

## Philosophy

Configuration is a multiplier, but only if it's lean. A 60-line CLAUDE.md with progressive disclosure outperforms a 300-line monolith. Three well-chosen MCP servers beat twenty poorly managed ones. A PostToolUse hook that runs the formatter on every edit eliminates an entire class of manual intervention forever.

The guiding question for every instruction in CLAUDE.md: "Would removing this line cause Claude to make a concrete mistake?" If no — remove it.

## Step 0: Recall learnings

Read `../_shared/learnings-protocol.md` and follow its **Recall** section. The tag on each entry is provenance only — all entries apply regardless of which skill wrote them.

If the file does not exist, proceed without mention.

## Step 1–2: Inventory and analysis

Step 1 (inventory) and Step 2 (analysis) below are read-heavy — dozens of files whose content
feeds into three tiered findings lists. Do this reading directly, in the main conversation:
work through the checklist sections in order, read each file as you reach it, and keep running
notes of the metrics and findings as you go rather than re-reading anything. The interactive
approval (Step 3) and the actual edits (Step 4) happen afterward, in the same thread, so the
user can see and steer them.

If `$ARGUMENTS` specifies a focus area, still work through every section below, but prioritize
reading and depth on the sections that match it.

The **Configuration files**, **Project context**, and **Current state metrics** bullets below
are the inventory scope for Step 1. The `### 2x` sections that follow are the Step 2 analysis
checklist — work through them in order (2a, 2a-bis, 2b, ... 2i), reading whatever each one
needs as you reach it.

### Configuration files

- `CLAUDE.md` (project root and any subdirectories)
- `AGENTS.md`
- `.claude/settings.json` and `.claude/settings.local.json`
- `.claude/local.md`
- `.claude/rules/*.md`
- `.claude/skills/*/SKILL.md`
- `.claude/commands/*.md` (legacy format)
- `.claude/agents/*.md`
- `.claude/learnings.md`
- `.headroom/` (machine-local Headroom data — check for presence with Glob on `.headroom/*`)
- `context/` (domain context files at project root by convention — company profile, brand voice, architecture decisions, etc.; if CLAUDE.md's `## Context files` table registers a different location, use that instead)
- `context/design/` (Claude Design handoff artifacts — PROMPT.md, design-notes.md, screenshots/ — under the registered context location)
- `DESIGN.md` (root-level design system spec — YAML tokens + Markdown rationale; auto-read by Claude Code and other agents)
- `.mcp.json` (project root)
- `~/.claude/CLAUDE.md` (user level — read but don't modify without asking)
- `~/.claude.json` (user-level MCP — read but don't modify without asking)

### Project context

- Package manager and dependencies (package.json, composer.json, Cargo.toml, etc.)
- Build/test/lint commands (scripts in package.json, Makefile targets, etc.)
- Formatter and linter configs (.prettierrc, .eslintrc, phpcs.xml, rustfmt.toml, etc.)
- CI/CD configuration
- Content-project artifacts: static-site configs (`hugo.toml`, `_config.yml`, `astro.config.*`, `mkdocs.yml`), prose tooling (`.vale.ini`, `.markdownlint.*`), shared knowledge bases or style guides referenced from CLAUDE.md
- OpenSpec artifacts (`openspec/` directory, `openspec/project.md`, change specs)
- Documentation (`docs/`, `README.md`, architecture docs)
- Directory structure and apparent architecture patterns
- Hook managers and their hook files (`.husky/`, `lefthook.yml`, `.pre-commit-config.yaml`)
- Project-local git hooks directory (`.githooks/`) and sync scripts (`scripts/sync-config-table.{sh,js}`)
- Design system artifacts: `DESIGN.md` at the project root (persistent design system spec); `context/design/` (or the registered context location's `design/` subfolder) for Claude Design handoff artifacts (PROMPT.md, design-notes.md, screenshots/)

### Current state metrics

Count and report:

- CLAUDE.md word count via `wc -w` (a token-density proxy; line count alone doesn't reflect token load since line length varies) — target ~300–600 words for a lean project-root file, higher only if `@`-imports carry the bulk of the detail out of the main file
- Number of `@`-imports in CLAUDE.md
- Number of active MCP servers
- Number of skills
- Number of hooks
- Permissions: what's allowed, what's denied
- Environment variables set in settings.json
- Number of entries in `.claude/learnings.md` (if it exists)

## Analysis checklist (2a–2i)

This is Step 2, analysis against best practices, performed directly in the main thread. Work
through each section below in order, reading whatever files it needs.

### 2a: CLAUDE.md audit

Check for these anti-patterns:

**Bloat indicators** (things to remove or move):

- Standard language conventions Claude already knows → remove
- Rules that the configured linter/formatter already enforces → remove ("never send an LLM to do a linter's job")
- Personality instructions ("be a senior engineer", "think carefully") → remove
- File-by-file codebase descriptions → remove (Claude can read files itself)
- Domain knowledge that's rarely needed → move to a skill
- Long inline documentation needed only sometimes → move to a `.claude/rules/<topic>.md` with `paths:` frontmatter or to a skill (both load on demand). An `@`-import does not help here: imported files are expanded into context with the importing file
- Duplicated information that also exists in AGENTS.md or OpenSpec → remove from CLAUDE.md, reference instead

**Missing essentials** (things to add if absent):

- Exact build/test/lint/dev commands (not vague — actual command strings)
- Key directory structure (only non-obvious parts)
- Conventions that deviate from standard or that Claude commonly gets wrong
- Explicit "Don't" section for known failure modes
- Compact instructions (what to preserve when compacting)
- On-demand loading for reference docs (path-scoped `.claude/rules/` or skills; `@`-imports load eagerly)
- Learnings section (instructs Claude to log corrections to `.claude/learnings.md` instead of modifying CLAUDE.md directly)

**Structural checks:**

- Is large reference material loaded eagerly via `@`-imports that every session pays for? Imports organize a file but don't reduce context cost — flag big imports that are only sometimes relevant and propose path-scoped rules or a skill instead. Also check size: the docs recommend under 200 lines per CLAUDE.md.
- If AGENTS.md exists, does CLAUDE.md import it via `@AGENTS.md` instead of duplicating content? (Claude Code 2.1.277+ reads AGENTS.md natively only when no CLAUDE.md exists in or above the working directory.)
- If OpenSpec is used, does CLAUDE.md reference `@openspec/project.md` for project context?
- If `DESIGN.md` exists at the project root, does CLAUDE.md import it via `@DESIGN.md` (small file) or does a `.claude/rules/` file with UI `paths:` globs load it (large file)? Without either, Claude won't consult the design system when making UI decisions.
- If the registered context location (`context/` by convention, or wherever CLAUDE.md's `## Context files` table points) contains files, does CLAUDE.md have a `## Context files` table registering them? Without this table, skills can't discover which context files exist or judge their relevance — they only find files they're explicitly pointed to. Note: this is a plain Markdown table, not an `@`-import — the table itself loads every message, but each underlying file loads only when a skill judges it relevant to the current task from its Summary.
- Are there too many `IMPORTANT:` or `YOU MUST` markers? (if everything is marked important, nothing is)

**Correctness checks** (verify against reality, not just structure):

- For each command referenced in CLAUDE.md (build/test/lint/dev/deploy), verify it exists in the actual manifest (package.json scripts, Makefile targets, Cargo.toml, composer.json, etc.). Flag any command that would fail — renamed script, deleted target, wrong path.
- For each file path referenced (via `@`-import, the `## Context files` table, or inline mention outside those two), verify with `test -f` that it resolves. Flag broken references.
- Flag stack/version claims that contradict the actual dependency manifest (e.g., CLAUDE.md says "Node 16" but `package.json` `engines` says `>=20`).

### 2a-bis: Key Config Files table hygiene

`sync-config-table.sh` (v5+) can only judge whether a file is _config-shaped_ (it matched a
scanned directory/extension) — never whether it's _important enough_ for a lean CLAUDE.md to
carry a row for. That importance call is this skill's job, not the script's. Two things to
check every audit:

**Stale placeholder rows.** Grep the table for `TODO: add description`. For each match, decide:

- The file is genuinely worth a row → write the real one-line purpose.
- The file isn't worth tracking in this table at all (e.g. it's already documented elsewhere in
  CLAUDE.md, or it's boilerplate nobody needs to orient on) → don't just delete the row. The
  script rebuilds the table from the filesystem on every commit, so a bare deletion gets the row
  silently re-added with the same placeholder next time the file is touched. Instead, add it to
  the `key-config-excluded` block (create the block if absent, anywhere in CLAUDE.md):

  ```markdown
  <!-- cc-config: key-config-excluded
  path/to/file.ext — one-line reason — YYYY-MM-DD
  -->
  ```

  The path must match exactly what the table used (repo-relative, matching the script's own
  path construction). The reason and date are for human/agent context only — the script only
  reads the path before the first em-dash.

**Excluded-list review.** If a `key-config-excluded` block exists, re-examine every entry:

- If the referenced path no longer exists on disk, remove that entry — it's dead weight.
- If the file has grown in scope or importance since it was excluded (check `git log` for
  significant recent activity, or judge from its current content) such that a row would now
  earn its keep, remove the entry. The next sync run will pick the file back up automatically
  and add it with a placeholder purpose — treat that placeholder the same way as any other
  stale-TODO finding above (write the real description, don't leave it).
- Otherwise leave the entry as-is; don't re-litigate a still-valid exclusion every audit.

### 2b: AGENTS.md audit

- Does it exist? Should it? (yes if multiple AI tools are used in the project)
- Is it genuinely tool-agnostic? (no Claude-specific features like `@`-imports inside AGENTS.md)
- Does it cover: setup commands, architecture boundaries, code style, testing, safety?
- Is there unnecessary duplication between AGENTS.md and CLAUDE.md?

### 2c: Settings audit

**Permissions:**

- Are sensitive files protected by `permissions.deny`? At minimum the real secret-bearing env files (`.env`, `.env.local`, `.env.*.local`, `.env.development`, `.env.production`, `.env.staging`, `.env.test`) and `secrets/**`.
- **Flag a broad `Read(.env.*)` or `Read(./.env.*)` deny rule** unless it is followed by a negation carve-out for example files (e.g. `Read(!.env.example)`; the docs describe gitignore-style `!` negation in deny lists, but it is version-dependent — verify before relying on it). Without a carve-out the glob blocks `.env.example`/`.env.sample`/`.env.template`/`.env.dist`/`example.env`, which hold no secrets, and an `allow` can never re-open a denied path (deny → ask → allow). The safe default remains the enumerated list above plus the PreToolUse secret-file guard.
- Read deny rules cover `cat`/`head`/`tail` on a named file in Bash but not `grep -r` or scripts that open files themselves; `Bash(curl:*)`/`Bash(wget:*)` denies miss `/usr/bin/curl` and `sh -c`. Treat them as guard rails, not a boundary — suggest the sandbox only if the user needs a real one.
- A `permissions.ask` rule for `git push` is the user's choice, never a finding either way: it forces a prompt even in `auto` and `bypassPermissions` mode, and its wildcard also prompts for harmless commands that merely mention `push`. Only if `ask` has a push rule, check that `allow` uses named git subcommands (`Bash(git status *)`, …) rather than a blanket `Bash(git *)`, which would approve pushes the `ask` rule can't match (aliases, `git -c`). Without an `ask` rule a blanket `Bash(git *)` is harmless — don't flag it.
- Is `permissions.deny` used instead of the deprecated `ignorePatterns`?
- Are destructive commands blocked? (`rm -rf`, and consider network download commands unless specifically needed)
- Are safe, frequently-used commands in `permissions.allow`? (reduces approval fatigue)

**Hooks (Claude Code):**

- Is there a PostToolUse formatter hook? If a formatter exists in the project but no hook runs it, this is a high-impact gap. Valid formatter targets include code formatters (prettier, ruff, rustfmt, gofmt, php-cs-fixer) and Markdown formatters (prettier on `.md`, `markdownlint --fix`) — don't skip the audit just because the project produces content rather than code.
- Is there a PreToolUse hook protecting sensitive files? (defense in depth beyond `permissions.deny`) A `Read|Edit|Write` guard (matcher must include `Write`) that blocks `.env`/`.env.*` basenames while carving out `*.example`/`*.sample`/`*.template`/`*.dist`/`example.env` gives broad coverage that the enumerated deny list cannot, since deny rules must leave example files unmatched. See the secret-file guard script in `/bootstrapping-config`; flag an inline `jq` one-liner that exits 0 when `jq` is missing (fails open) and a relative `bash .claude/…` command (use `$CLAUDE_PROJECT_DIR`).
- Do all hooks use `|| true` for graceful degradation? **Exception: security hooks must fail closed.** A secret-file guard must exit **2** (any other non-zero code is non-blocking and the call proceeds) on the bad path and must not be softened with `|| true`, or it will pass silently when its dependency (e.g. `jq`) is missing. Only formatter/lint hooks should carry `|| true`.

**Git hooks and hook-manager drift:**

`/bootstrapping-config` creates a project-local `.githooks/pre-commit` that runs `scripts/sync-config-table.sh` and activates it via `git config core.hooksPath .githooks`. If a hook manager like Husky is added later, it takes over `core.hooksPath` — the `.githooks/pre-commit` is still present in the repo but silently stops running. This is a silent drift scenario. Check for it:

1. Detect hook managers:
   - Husky: `husky` in `package.json` devDependencies, or `.husky/` directory present
   - Lefthook: `lefthook.yml` or `lefthook` in devDependencies
   - pre-commit: `.pre-commit-config.yaml`
2. Detect cc-init hook infrastructure: `.githooks/pre-commit` exists and references `sync-config-table`
3. If both are present, flag as **conflict** and propose one of these migrations:
   - **Migrate to the hook manager** (recommended if the hook manager is the project standard): move the `sync-config-table` invocation into the hook manager's pre-commit config (e.g., append it to `.husky/pre-commit`), then delete `.githooks/pre-commit` and — if empty — the `.githooks/` directory. Optionally run `git config --unset core.hooksPath` so the setting doesn't confuse future contributors.
   - **Keep the project-local hook** (only if the hook manager was added by mistake or is being removed): leave `.githooks/` in place and note that the user needs to resolve which hook system owns `core.hooksPath`.
4. Also check if `scripts/sync-config-table.*` exists but `.githooks/pre-commit` is missing entirely — the script is orphaned and never runs. Same proposal: wire it into the active hook manager or recreate the `.githooks/` setup.
5. If the sync script exists in a variant that doesn't match the filesystem conventions of the project (e.g., a `.sh` script in a Node-only project where the team prefers `.js`), note it as a nice-to-have for harmonization but don't force the change.

**Sync script version drift:**

`scripts/sync-config-table.sh` is copied into a project once, at init time, and nothing updates it afterwards — a plugin update does not reach into repos that were already initialized. Bug fixes to the script therefore only land when this skill runs. Check for it on every audit:

1. Read the version marker from the project's copy: `grep -m1 'sync-config-table-version:' scripts/sync-config-table.sh`. A copy predating the versioning scheme has no marker — treat that as version 0.
2. Read the marker from the plugin's canonical copy. It lives in the sibling `bootstrapping-config` skill directory, i.e. `../bootstrapping-config/scripts/sync-config-table.sh` relative to this skill's own directory. If you cannot locate it, say so and skip this check — do not fall back to guessing a version or reconstructing the script from memory.
3. If the project's version is lower or absent, the copy is stale. **Show the user a diff of the two files and ask before overwriting.** Never overwrite silently: the marker only tells you the copy is old, not whether the user hand-edited it, and an unattended clobber would discard their changes without a trace.
4. On confirmation, copy the plugin's file over the project's and re-apply `chmod +x`. Report which version replaced which.
5. If the versions match, say nothing — this is a no-op on an up-to-date repo, and a clean audit shouldn't spend the user's attention on it.

If the diff shows the project's copy was customized (scan rules added or removed rather than just older core logic), point out that the canonical script guards every scan with a directory check and self-adapts, so the customization is probably unnecessary — but let the user decide. Preserving a deliberate local fork is better than a refresh they didn't expect.

**Secret scanning in pre-commit hooks:**

Check if the project's active pre-commit hook (whether in `.githooks/`, `.husky/`, lefthook, or pre-commit framework) includes a secret scanner like gitleaks. If the project has sensitive files (`.env`, API keys, credentials) or `permissions.deny` entries for secrets, but no pre-commit secret scanning, recommend adding gitleaks to the active pre-commit hook:

```bash
gitleaks git --pre-commit --staged || exit 1
```

This catches secrets committed by both Claude Code and the user. Unlike `permissions.deny` (which only prevents Claude from reading existing secrets), gitleaks prevents anyone from committing new ones. Note: gitleaks must be installed separately (`brew install gitleaks`, `apt install gitleaks`, or via the project's CI toolchain). Only recommend — never install tools on the user's machine without explicit permission.

**Environment variables:**

- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`: can only _lower_ the compaction threshold and only applies in sessions that compact before the model's context limit. On a plain local setup it is likely a no-op — flag as probably ineffective unless the project demonstrably needs it.
- `MAX_THINKING_TOKENS`: no effect on Opus 4.7+, Sonnet 5+, Haiku 5.5 or Fable (always adaptive); it is only a fixed budget on Opus/Sonnet 4.6 with adaptive reasoning disabled. Flag as obsolete and suggest removing it.
- `CLAUDE_CODE_MAX_OUTPUT_TOKENS`: defaults and caps vary by model; raising it shrinks the context available before auto-compaction. A low value can truncate long answers — only keep it if there's a reason.
- `CLAUDE_CODE_SUBAGENT_MODEL`: `haiku` lowers cost for exploration subagents (no savings percentage — it varies). It overrides every subagent's own `model:` frontmatter, so check that's desired for judgment-heavy subagents the project defines.
- `alwaysThinkingEnabled` and `effortLevel` (in `settings.json`, not `env`): thinking is on by default, so `alwaysThinkingEnabled: true` changes nothing — only `false` has an effect. `effortLevel` accepts `low`/`medium`/`high`/`xhigh` (unset by default); higher levels fill context faster. Flag only a high setting with no stated reason.

**Auto-pull on session start:**

`cc-config` bundles a `SessionStart` hook (`plugins/cc-config/hooks/auto-git-pull.sh`) that fetches and fast-forwards the current branch at the start of every session — but only when the project has opted in via `CC_CONFIG_AUTO_GIT_PULL=true` in the `env` block of `.claude/settings.local.json`. It never merges or rebases; on divergence it skips and surfaces a message instead. This is a personal multi-machine workflow preference, not a project convention — never write it to the committed `.claude/settings.json`, and never enable it without asking.

Check whether the flag is set. If it is **not** set and the project is a git repo with a remote, surface it as a nice-to-have suggestion (see below) rather than enabling it unprompted — most projects don't need it, and it's the kind of thing only the user asking to work across multiple machines actually wants.

**`.claudeignore`:**

`.claudeignore` is not a documented Claude Code feature (absent from the settings reference and docs index), so it likely has no effect. If one exists, flag it as a "should fix": explain it probably doesn't reduce token use and propose `permissions.deny` `Read` rules for paths Claude must not read (dependency trees and build output are already skipped by Glob/Grep via `.gitignore`). Never recommend creating one. To check startup overhead, run `/context` in a fresh session; above ~10,000 tokens, look at CLAUDE.md size, eager `@`-imports and MCP tool count, and try `/doctor prompt-audit`.

### 2d: MCP audit

- How many servers are active? (5–10 is the sweet spot for most projects)
- Are all servers actually used? Check if they match the project's real needs.
- Are secrets hardcoded or using `${VAR}` expansion?
- Is the project using `.mcp.json` (project-scope, recommended) or `~/.claude.json` (user-scope)?
- Could any MCP server be replaced by a simpler CLI tool? (e.g., `gh` CLI instead of GitHub MCP for basic operations — no permanent context overhead)
- Is Tool Search / deferred tool loading active? Current Claude Code models can defer MCP tool schemas and fetch them on demand once tool descriptions get large — the exact model gating and threshold aren't reliably documented, so don't cite specific numbers; just note whether the project's tool count is small enough that this isn't a concern, or large enough to be worth checking.

### 2e: Skills audit

- Are there skills that duplicate CLAUDE.md content? → Deduplicate.
- Are skills with side effects (deploy, commit, publish) using `disable-model-invocation: true`?
- Are read-only analysis skills using `allowed-tools` restrictions?
- Are there `.claude/commands/` files that should be migrated to the skills format?
- Is skill content concise? (docs: keep SKILL.md under 500 lines and move reference material to supporting files; `description` + `when_to_use` are truncated at 1,536 characters)
- If OpenSpec is used: are OpenSpec skills duplicated across multiple tool directories (`.claude/`, `.codex/`, `.gemini/`, `.github/`)? If so, flag this as a maintenance risk and suggest consolidation.
- Do skills that produce domain-specific output correctly separate context by scope? Check for three types of violations:
  - **Company-level knowledge inlined or duplicated per-skill**: brand voice, company profile, buyer personas, architecture decisions belong in the registered context location (`context/` by convention, project root). Consolidate and register in the `## Context files` table in CLAUDE.md — update once, every skill reflects the change.
  - **Format-level knowledge in the shared context location**: a whitepaper structure guide or blog length rules belong inside the skill's own folder, not the shared context folder.
  - **Campaign/feature briefings in the shared context location**: initiative-specific briefings belong in the relevant project subfolder, not the company-scoped shared folder.
- If a `## Context files` table exists, validate its rows:
  - **Malformed rows**: don't follow `Label | File | Summary` (missing or extra cells).
  - **Orphaned paths**: the `File` value doesn't resolve to an existing file. Check with `test -f`, resolving the path relative to the CLAUDE.md file that contains the table — not the repository root (paths follow the same resolution rule as `@`-imports, so a nested CLAUDE.md's table is relative to its own directory).
  - **Duplicates**: two rows share the same Label or the same File path.
  - **Vague summaries** (soft check — human judgment): a summary too generic to act as a relevance signal, e.g. "Writing style guidelines for the company" instead of "Formal German, em-dash preferred, no exclamation marks — all corporate copy." Flag as a suggestion, not a hard rule.
- Does each skill end with a feedback step? A skill that closes by asking "Did this output meet your expectations? If not, I'll log a correction to `.claude/learnings.md`" makes the learnings loop active rather than passive — corrections are solicited at the point of delivery, not just accumulated from future mishaps. Flag absent feedback steps as "nice to have."
- For each custom subagent in `.claude/agents/*.md` (project-local) or, in a plugin repo, `plugins/*/agents/*.md` (plugin-bundled): is it actually referenced anywhere (grep skills, hooks, and CLAUDE.md for its name in an `Agent(...)`/`subagent_type:` context — for a plugin-bundled agent, that's its plugin-scoped `plugin-name:agent-name` form)? An unreferenced custom agent is dead weight the same way an unused MCP server is. Does its `tools:` allowlist match what it actually needs — a subagent with side effects (writes, deploys) granted `Write`/`Edit`/`Bash` it doesn't use is worth flagging the same way an overbroad skill `allowed-tools` list would be.

### 2f: Multi-tool consistency check

If the project uses multiple AI tool directories:

- Is there a single source of truth (ideally AGENTS.md) that all tools reference?
- Are there contradictions between tool-specific configs?
- Is duplicated content maintained in sync, or is it drifting?

### 2g: Learnings review

If `.claude/learnings.md` exists, review every entry under any tag. Read `../_shared/learnings-protocol.md` and follow its **Reviewing** section. Promotion targets: CLAUDE.md (a universal project convention), an existing or new skill (domain-specific or rarely needed), or a hook (something that should happen deterministically, not by instruction). Present the proposals to the user as "promote / keep / retire", with rationale for each. Wait for approval before changing anything.

If `.claude/learnings.md` does not exist but CLAUDE.md also has no Learnings section, suggest adding the Learnings section to CLAUDE.md:

```markdown
## Learnings

When the user corrects a mistake or points out a recurring issue, record a one-line entry in .claude/learnings.md as `[claude:note] <observation> (corrected) — YYYY-MM-DD` (use `(stated)` when the user states a standing rule). If it contradicts an existing entry, replace that entry instead of adding a second one. Don't modify CLAUDE.md directly.
```

### 2h: Headroom audit

Optional in-flight compression layer. Check `.headroom/` with Glob, then follow the "Headroom audit" section of [reference.md](reference.md) (gitignore check, integration mode, install suggestion, and when to skip silently).

### 2i: Cross-file duplication (hierarchical CLAUDE.md trees)

Relevant when a project uses multiple CLAUDE.md files across folder levels (common with the cc-content context-TOC pattern) — Claude Code auto-loads every CLAUDE.md up the directory chain, so content should live once at the shallowest level it applies to.

1. Discover all CLAUDE.md files in the tree: `find . -name CLAUDE.md -not -path '*/node_modules/*' -not -path '*/vendor/*'`
2. Read all discovered files.
3. Compare content across levels — not just identical strings, but near-duplicate rules, conventions, or command lists restated at multiple levels.
4. Distinguish **acceptable repetition** (a one-line pointer restating scope, e.g. "This file covers the `api/` package only") from **true duplication** (the same rule or command list copy-pasted across levels).
5. Flag true duplicates: content should move to the shallowest common ancestor; deeper-level files should only add what's specific to that scope.

## Step 3: Generate findings report

Using the metrics and findings gathered in Step 1–2, organize findings into three categories:

### Must fix (security or correctness issues)

- Missing permissions.deny for sensitive files
- Hardcoded secrets in config files
- Deprecated patterns (ignorePatterns, npm-installed Claude Code)
- Contradictory instructions
- Hook-manager conflict: `.githooks/pre-commit` present alongside an active hook manager (the sync script is not running)
- CLAUDE.md documents a command that doesn't exist in the actual manifest (renamed script, deleted target, wrong path) — Claude will confidently run something that fails
- CLAUDE.md references a file path (outside `@`-imports and the `## Context files` table) that doesn't resolve

### Should fix (quality and cost improvements)

- CLAUDE.md bloat (>80 lines without good reason)
- Missing formatter hook
- Obsolete or ineffective env vars (`MAX_THINKING_TOKENS` on current models, `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` on plain local setups)
- `.claudeignore` present (not a documented feature; likely no effect)
- Broad `Read(.env.*)` deny without a negation carve-out, or a secret-file guard hook that fails open / omits `Write`
- Blanket `Bash(git *)` in `allow` while `permissions.ask` has a `git push` rule (the blanket rule approves pushes the `ask` rule can't match)
- Redundant content between files
- Skills without proper frontmatter guards
- Learnings entries that should be promoted to CLAUDE.md or a skill
- Orphaned `scripts/sync-config-table.*` with no active hook wiring
- `scripts/sync-config-table.sh` older than the plugin's canonical copy (stale or missing version marker) — the repo is stranded on a version with known bugs
- `DESIGN.md` present at project root but neither imported via `@DESIGN.md` nor loaded by a path-scoped rule (Claude won't apply the design system without it)
- Context files present in the registered context location but no `## Context files` table in CLAUDE.md — skills cannot discover context files without this table
- `## Context files` table has malformed rows (not `Label | File | Summary`), duplicate Label/File values, or File paths that don't resolve to an existing file
- `## Context files` table exists but is missing the `<!-- cc-config: context-toc-registered -->` marker comment right after the heading (v4+ `sync-config-table.sh` greps for this exact string, not the heading text, to decide whether `context/` files belong in `## Key Config Files` too — without the marker, the sync script will re-list every context file there with a generic placeholder, duplicating the registered table). Add the marker; don't rename or reword it.
- `## Key Config Files` table lists individual `context/*.md` files with a generic/placeholder Purpose even though a populated `## Context files` table already registers them with real summaries — a sign the marker is missing or `sync-config-table.sh` predates v4
- `## Key Config Files` table has one or more `TODO: add description` rows (see 2a-bis) — write the real description, or move the file to the `key-config-excluded` block if it's not worth a row at all
- `key-config-excluded` block (see 2a-bis) has an entry whose path no longer exists, or whose file has demonstrably grown important enough to reconsider
- Headroom installed but `.headroom/` not in `.gitignore`: machine-local Headroom files (session caches, `.headroom/CLAUDE.local.md`) must not be committed — they are per-machine and will break other clones
- True duplicate content across nested CLAUDE.md files in a hierarchical tree (see 2i) — should live once at the shallowest common ancestor

### Nice to have (polish)

- Large, rarely needed reference content loaded eagerly via `@`-imports (move to path-scoped rules or a skill)
- Missing compact instructions
- Missing Learnings section in CLAUDE.md
- Skills that could be created for recurring workflows
- MCP servers that could be added or removed
- Missing secret scanner (gitleaks) in pre-commit hook
- Sync script format mismatch with project conventions (e.g., `.sh` in a Node-only repo)
- Skills producing domain-specific output without referencing the registered context location (`context/` by convention, project root) — company-level knowledge duplicated or inlined per-skill
- Context scope violations: company-level knowledge buried in campaign subfolders, or format-level guidelines in the shared context location instead of the relevant skill's folder
- `## Context files` table summaries too vague to act as a relevance signal for skills (soft check — human judgment, e.g. "Writing style guidelines" instead of naming the specific tone, audience, or rules)
- CLAUDE.md stack/version claims that don't match the actual dependency manifest (e.g., states "Node 16" while `package.json` `engines` says `>=20`)
- Multi-level folder project without hierarchical CLAUDE.md files: if the repo has campaign, feature, or package subfolders where context meaningfully changes, each level should have its own CLAUDE.md that @-imports the relevant context for that scope — this lets Claude inherit all relevant context when started in any subfolder, without skills needing hard-coded paths to shared files. Any `## Context files` table in a nested CLAUDE.md follows the same path convention as the root one: `File` values are relative to that CLAUDE.md's own location, not the repository root.
- Skills missing a terminal feedback step that solicits corrections into the learnings loop
- PDFs, DOCX files, or HTML pages referenced in CLAUDE.md or context files without Markdown equivalents: converting them saves significant tokens (HTML→Markdown ~90% reduction, PDF→Markdown ~65–70%, DOCX→Markdown ~33%). Tools like Pandoc, Docling, or `markitdown` convert in seconds. Flag any such files found in the registered context location or referenced via `@`-imports
- Startup token overhead unmeasured: suggest `/context` in a fresh session (and `/doctor prompt-audit`) if CLAUDE.md is large or many imports/MCP servers are present
- Headroom not installed but Python 3.10+ is available and the project runs locally (not only in remote/sandboxed sessions): offer it per [reference.md](reference.md) — unverified vendor savings figures live there; don't quote them as facts
- `CC_CONFIG_AUTO_GIT_PULL` not set and the project is a git repo with a configured remote: ask whether the user works on this repo from multiple machines and forgets to `git pull` before starting a session. If yes, offer to set `CC_CONFIG_AUTO_GIT_PULL=true` in the `env` block of `.claude/settings.local.json` (create the file if absent) so the bundled `auto-git-pull.sh` `SessionStart` hook fast-forwards the branch automatically, skipping (with a message) if history has diverged. Never enable this without asking, and never write it to the committed `.claude/settings.json`.

Present the findings to the user as a concise list, grouped by category. For each finding, state: what the issue is, why it matters, and what you'd change. Ask for approval before making changes.

### Config health score

Compute a single score from the categorized findings above — it reads directly off the counts you already produced, not a separate rubric:

```
score = max(0, 100 − 10 × must_fix_count − 4 × should_fix_count − 1 × nice_to_have_count)
```

Report this score once now (the "before" score) and again in Step 5 after approved changes are applied (the "after" score), so the user sees a concrete before/after (e.g. "Config health: 62/100 → 91/100") rather than only a word-count delta.

## Step 4: Apply approved changes

Make the approved changes. For each file modified:

- Show a before/after summary (not full diffs for large files — just the key changes).
- Explain briefly what changed and why.

When applying learnings review results:

- Remove promoted and retired entries from `.claude/learnings.md`; leave kept entries unchanged.
- If no entries remain below the header, delete `.claude/learnings.md`, or leave only the header if you cannot delete files (it will be recreated when the next observation is recorded).

When resolving hook-manager conflicts:

- If migrating to Husky: append the sync-script call to `.husky/pre-commit` (create it if missing), delete `.githooks/pre-commit`, remove the empty `.githooks/` directory, and suggest the user runs `git config --unset core.hooksPath` on each clone.
- If migrating to Lefthook or pre-commit: add the appropriate entry to the respective config file instead.
- Never delete `scripts/sync-config-table.*` itself — the script is still useful, only the wiring changes.

When resolving the Headroom gitignore gap:

Append `.headroom/` to `.gitignore`. Place it under the existing Claude Code personal-files block if one exists, or at the end of the file with a short comment:

```
# Headroom — machine-local session cache and learnings
.headroom/
```

Do not create `.headroom/` or any files inside it — Headroom manages that directory itself.

When enabling auto-pull on session start:

Add or merge `env.CC_CONFIG_AUTO_GIT_PULL: "true"` into `.claude/settings.local.json` (create it with `{"env": {"CC_CONFIG_AUTO_GIT_PULL": "true"}}` if the file doesn't exist yet; merge into the existing `env` block if it does — don't clobber other keys). Confirm this file is already covered by `.gitignore` (`.claude/settings.local.json` is part of the standard ignore block) so the flag stays machine-local and never lands in a shared config.

Preserve things that work well. Don't refactor for the sake of refactoring. If an existing config is well-structured and correct, say so and move on.

## Step 5: Final summary

After all changes:

1. List every file modified or created, with one-line descriptions of changes.
2. Report the new metrics: CLAUDE.md word count, number of active MCP servers, hooks configured, etc.
3. Compare key metrics to before (e.g., "CLAUDE.md: 1,850 words → 480 words").
4. Recompute the config health score from whatever findings remain unresolved and report the before/after (e.g. "Config health: 62/100 → 91/100").
5. If learnings were reviewed: report how many entries were promoted, retired and kept.
6. Note anything you deliberately left unchanged and why.
7. Update the audit marker in CLAUDE.md so the bundled `SessionStart` staleness hook (see
   "Audit staleness reminder" below) has a fresh baseline to compare future commits against:

   ```bash
   date +%Y-%m-%d      # today's date
   git rev-parse HEAD  # current commit SHA
   ```

   Write or replace the line `<!-- cc-config: last-optimize-run: YYYY-MM-DD <sha> -->`
   anywhere in CLAUDE.md (reuse the existing line if one is already present, e.g. right after
   the `## Key Config Files` table, alongside `key-config-excluded` if that block exists —
   don't scatter multiple copies of this marker across the file). This step runs even if this
   audit found nothing to fix — a clean audit still resets the baseline.

8. Suggest running `/auditing-config` again periodically (e.g., after major features, after a few weeks of work) to prevent config drift. Mention that the bundled `SessionStart` hook will also nudge automatically once enough commits accumulate since the marker just written, so this is a backstop, not the primary way it's kept current.
9. Remind the user to commit the changes.

### Audit staleness reminder

The bundled `SessionStart` hook compares the `last-optimize-run` marker written above against the repo's commit count and date and nudges when the project drifts (defaults: 20+ commits, or 14+ days with new commits). Keeping the marker fresh is what makes that comparison meaningful. Mechanism details: "Audit staleness reminder" in [reference.md](reference.md).

## Common optimization patterns

See "Common optimization patterns" in [reference.md](reference.md): CLAUDE.md → skills migration, conditional loading via path-scoped rules, AGENTS.md as source of truth, OpenSpec, hook-ification, learnings graduation, hook-manager migration.

## What NOT to do

- Don't refactor things that work well. If a config is correct and clean, say so.
- Don't add MCP servers or create skills speculatively. Only suggest servers that address a concrete gap, and skills for workflows that have already been repeated.
- Don't modify user-level files (`~/.claude/CLAUDE.md`, `~/.claude.json`) without explicit permission.
- Don't remove functionality. If something serves a purpose, keep it — just optimize how it's expressed.
- Don't make the config dependent on tools or servers the user hasn't installed.

## Feedback

**Auto-store phase.** Read `../_shared/learnings-protocol.md` and follow its **Writing** section. Tag entries `[cc-config:auditing-config]`; the source is `inferred` unless the user said it. Skip entries promoted or retired by 2g in this run. Worth recording in this skill: a concise fact about this project that differs from what this skill assumes on a generic project; a suggestion the user explicitly accepted or rejected that deviates from skill defaults; a constraint or fact discovered that would change how this skill behaves next time.

**Explicit feedback.** After the auto-store phase, ask:

> "Did this optimization meet your expectations? If anything needs adjusting, share it here — or press Enter to finish."

- If the user provides a correction, record it per the protocol's **Writing** section with source `corrected`.
- Then follow the protocol's **Confirming** section.

> **Note:** Learnings are automatically recalled at the start of the next skill run. Run `/auditing-config` periodically to review learnings: promote, keep or retire them by source and relevance.
