---
name: cc-config-optimize
description: Audit and optimize an existing Claude Code configuration against current best practices. Use this skill when a user asks to review, improve, clean up, or optimize their Claude Code setup, CLAUDE.md, settings, hooks, MCP servers, or skills. Also use when the user says things like "check my config", "is my CLAUDE.md too long", "reduce token costs", "tighten permissions", or "my Claude Code setup feels bloated". This skill assumes the project has code, and possibly documentation or OpenSpec specs, that inform the optimization.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
argument-hint: "[optional: specific area to focus on, e.g. 'CLAUDE.md', 'hooks', 'costs']"
---

# Optimize Claude Code Configuration

You are auditing and improving an existing Claude Code setup. The project has code, possibly documentation, and possibly OpenSpec specifications. Your job is to identify what's good (preserve it), what's missing, what's bloated, and what violates current best practices — then fix it with the user's approval.

## Philosophy

Configuration is a multiplier, but only if it's lean. A 60-line CLAUDE.md with progressive disclosure outperforms a 300-line monolith. Three well-chosen MCP servers beat twenty poorly managed ones. Proactive compaction at 50% beats reactive auto-compact at 83%. A PostToolUse hook that runs the formatter on every edit eliminates an entire class of manual intervention forever.

The guiding question for every instruction in CLAUDE.md: "Would removing this line cause Claude to make a concrete mistake?" If no — remove it.

## Step 0: Recall learnings

If `.claude/learnings.md` exists, read all entries and apply them silently to inform this run. The `[skill-name]` tag on each entry is provenance only — all entries apply regardless of which skill wrote them. Do not announce that learnings were loaded.

If the file does not exist, proceed without mention.

## Step 1: Full inventory

Read and catalog everything that exists. Do this thoroughly before suggesting any changes.

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
- `.headroom/` (machine-local Headroom data — check for presence: `ls .headroom 2>/dev/null && echo headroom-present || echo headroom-absent`)
- `context/` (domain context files at project root — company profile, brand voice, architecture decisions, etc.)
- `context/design/` (Claude Design handoff artifacts — PROMPT.md, design-notes.md, screenshots/)
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
- Design system artifacts: `DESIGN.md` at the project root (persistent design system spec); `context/design/` for Claude Design handoff artifacts (PROMPT.md, design-notes.md, screenshots/)

### Current state metrics

Count and report:

- CLAUDE.md line count (target: 40–80, hard max: 200)
- Number of `@`-imports in CLAUDE.md
- Number of active MCP servers
- Number of skills
- Number of hooks
- Permissions: what's allowed, what's denied
- Environment variables set in settings.json
- Number of entries in `.claude/learnings.md` (if it exists)

## Step 2: Analyze against best practices

Work through each area systematically. If `$ARGUMENTS` specified a focus area, prioritize that but still scan everything.

### 2a: CLAUDE.md audit

Check for these anti-patterns:

**Bloat indicators** (things to remove or move):

- Standard language conventions Claude already knows → remove
- Rules that the configured linter/formatter already enforces → remove ("never send an LLM to do a linter's job")
- Personality instructions ("be a senior engineer", "think carefully") → remove
- File-by-file codebase descriptions → remove (Claude can read files itself)
- Domain knowledge that's rarely needed → move to a skill
- Long inline documentation → extract to a reference file and use `@`-import with a trigger condition
- Duplicated information that also exists in AGENTS.md or OpenSpec → remove from CLAUDE.md, reference instead

**Missing essentials** (things to add if absent):

- Exact build/test/lint/dev commands (not vague — actual command strings)
- Key directory structure (only non-obvious parts)
- Conventions that deviate from standard or that Claude commonly gets wrong
- Explicit "Don't" section for known failure modes
- Compact instructions (what to preserve when compacting)
- Progressive disclosure pointers for reference docs (`@path **Read when:** <trigger>`)
- Learnings section (instructs Claude to log corrections to `.claude/learnings.md` instead of modifying CLAUDE.md directly)

**Structural checks:**

- Is the file using `@`-imports for large reference material? (imports reduce token waste by up to 59%)
- If AGENTS.md exists, does CLAUDE.md import it via `@AGENTS.md` instead of duplicating content?
- If OpenSpec is used, does CLAUDE.md reference `@openspec/project.md` for project context?
- If `DESIGN.md` exists at the project root, does CLAUDE.md reference it via `@DESIGN.md **Read when:** building or editing any UI component`? Without this pointer Claude won't consult the design system when making UI decisions.
- Are there too many `IMPORTANT:` or `YOU MUST` markers? (if everything is marked important, nothing is)

### 2b: AGENTS.md audit

- Does it exist? Should it? (yes if multiple AI tools are used in the project)
- Is it genuinely tool-agnostic? (no Claude-specific features like `@`-imports inside AGENTS.md)
- Does it cover: setup commands, architecture boundaries, code style, testing, safety?
- Is there unnecessary duplication between AGENTS.md and CLAUDE.md?

### 2c: Settings audit

**Permissions:**

- Are sensitive files protected by `permissions.deny`? At minimum the real secret-bearing env files (`.env`, `.env.local`, `.env.*.local`, `.env.development`, `.env.production`, `.env.staging`, `.env.test`) and `secrets/**`.
- **Flag a broad `Read(.env.*)` or `Read(./.env.*)` deny rule as a misconfiguration.** That glob also blocks example/template files (`.env.example`, `.env.sample`, `.env.template`, `.env.dist`, `example.env`), which hold no secrets and must stay readable for documentation. Because Claude Code evaluates `deny` before `allow` with no negation in `Read()` rules, a denied path cannot be re-allowed — an `allow(.env.example)` does not override it. Recommend migrating to the enumerated deny list above (leaving example files unmatched), and pairing it with the PreToolUse secret-file guard hook for full `.env.*` coverage with the example carve-out.
- Is `permissions.deny` used instead of the deprecated `ignorePatterns`?
- Are destructive commands blocked? (`rm -rf`, and consider `curl`/`wget` unless specifically needed)
- Are safe, frequently-used commands in `permissions.allow`? (reduces approval fatigue)

**Hooks (Claude Code):**

- Is there a PostToolUse formatter hook? If a formatter exists in the project but no hook runs it, this is a high-impact gap. Valid formatter targets include code formatters (prettier, ruff, rustfmt, gofmt, php-cs-fixer) and Markdown formatters (prettier on `.md`, `markdownlint --fix`) — don't skip the audit just because the project produces content rather than code.
- Is there a PreToolUse hook protecting sensitive files? (defense in depth beyond `permissions.deny`) A `Read|Edit` guard that blocks `.env`/`.env.*` basenames while carving out `*.example`/`*.sample`/`*.template`/`*.dist`/`example.env` gives broad coverage that the enumerated deny list cannot, since deny rules must leave example files unmatched. See the secret-file guard hook in `/cc-config-init`.
- Do all hooks use `|| true` for graceful degradation? **Exception: security hooks must fail closed.** A secret-file guard must exit non-zero (block) on the bad path and must not be softened with `|| true`, or it will pass silently when its dependency (e.g. `jq`) is missing. Only formatter/lint hooks should carry `|| true`.
- Are hooks doing "block at submit" rather than "block at write"? (fewer interrupts, smoother flow)

**Git hooks and hook-manager drift:**

`/cc-config-init` creates a project-local `.githooks/pre-commit` that runs `scripts/sync-config-table.sh` and activates it via `git config core.hooksPath .githooks`. If a hook manager like Husky is added later, it takes over `core.hooksPath` — the `.githooks/pre-commit` is still present in the repo but silently stops running. This is a silent drift scenario. Check for it:

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

**Secret scanning in pre-commit hooks:**

Check if the project's active pre-commit hook (whether in `.githooks/`, `.husky/`, lefthook, or pre-commit framework) includes a secret scanner like gitleaks. If the project has sensitive files (`.env`, API keys, credentials) or `permissions.deny` entries for secrets, but no pre-commit secret scanning, recommend adding gitleaks to the active pre-commit hook:

```bash
gitleaks git --pre-commit --staged || exit 1
```

This catches secrets committed by both Claude Code and the user. Unlike `permissions.deny` (which only prevents Claude from reading existing secrets), gitleaks prevents anyone from committing new ones. Note: gitleaks must be installed separately (`brew install gitleaks`, `apt install gitleaks`, or via the project's CI toolchain). Only recommend — never install tools on the user's machine without explicit permission.

**Environment variables:**

- Is `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` set? Recommended: `50`. Default 83% is too late.
- Is `MAX_THINKING_TOKENS` set? Consider `10000` (down from default 31999) for ~70% thinking cost savings.
- Is `CLAUDE_CODE_MAX_OUTPUT_TOKENS` set? Consider `16000` to prevent unnecessarily verbose responses.
- Is `CLAUDE_CODE_SUBAGENT_MODEL` set? `haiku` gives ~80% cost savings for exploration subagents.

**`.claudeignore`:**

Check whether a `.claudeignore` file exists. This file (`.gitignore` syntax) tells Claude Code which paths to skip entirely when indexing the project, reducing invisible startup token overhead.

Flag as a "should fix" if:

- The repo has `node_modules/`, `vendor/`, `.venv/`, or other dependency trees present and no `.claudeignore` excludes them.
- Build output directories exist (`dist/`, `build/`, `.next/`, `target/`, `_site/`, `coverage/`) and are not excluded.
- Large binary or media asset folders are present that Claude would never usefully read.

Flag as "nice to have" if the repo is small and tidy but could benefit from exclusions as it grows.

Run `/context` in a fresh session to get the current startup token count — if it exceeds ~10,000 tokens before any user message, a missing `.claudeignore` is a likely contributor.

### 2d: MCP audit

- How many servers are active? (5–10 is the sweet spot for most projects)
- Are all servers actually used? Check if they match the project's real needs.
- Are secrets hardcoded or using `${VAR}` expansion?
- Is the project using `.mcp.json` (project-scope, recommended) or `~/.claude.json` (user-scope)?
- Could any MCP server be replaced by a simpler CLI tool? (e.g., `gh` CLI instead of GitHub MCP for basic operations — no permanent context overhead)
- Is Tool Search active? (auto-enabled on Sonnet 4+ / Opus 4+ when MCP tool descriptions exceed 10% of context)

### 2e: Skills audit

- Are there skills that duplicate CLAUDE.md content? → Deduplicate.
- Are skills with side effects (deploy, commit, publish) using `disable-model-invocation: true`?
- Are read-only analysis skills using `allowed-tools` restrictions?
- Are there `.claude/commands/` files that should be migrated to the skills format?
- Is skill content concise? (target <50 lines per SKILL.md, split if longer)
- If OpenSpec is used: are OpenSpec skills duplicated across multiple tool directories (`.claude/`, `.codex/`, `.gemini/`, `.github/`)? If so, flag this as a maintenance risk and suggest consolidation.
- Do skills that produce domain-specific output correctly separate context by scope? Check for three types of violations:
  - **Company-level knowledge inlined or duplicated per-skill**: brand voice, company profile, buyer personas, architecture decisions belong in `context/` (project root). Consolidate and register in the `## Context files` table in CLAUDE.md — update once, every skill reflects the change.
  - **Format-level knowledge in `context/`**: a whitepaper structure guide or blog length rules belong inside the skill's own folder, not the shared context folder.
  - **Campaign/feature briefings in `context/`**: initiative-specific briefings belong in the relevant project subfolder, not the company-scoped shared folder.
- Does each skill end with a feedback step? A skill that closes by asking "Did this output meet your expectations? If not, I'll log a correction to `.claude/learnings.md`" makes the learnings loop active rather than passive — corrections are solicited at the point of delivery, not just accumulated from future mishaps. Flag absent feedback steps as "nice to have."

### 2f: Multi-tool consistency check

If the project uses multiple AI tool directories:

- Is there a single source of truth (ideally AGENTS.md) that all tools reference?
- Are there contradictions between tool-specific configs?
- Is duplicated content maintained in sync, or is it drifting?

### 2g: Learnings review

If `.claude/learnings.md` exists:

1. Read all entries.
2. Group similar entries to identify recurring patterns (3+ similar corrections suggest a real gap in the config).
3. For each recurring pattern, propose one of:
   - Adding a concrete rule to CLAUDE.md (if it's a universal project convention).
   - Adding it to an existing or new skill (if it's domain-specific or rarely needed).
   - Adding it as a hook (if it's something that should happen deterministically, not by instruction).
4. For one-off entries that don't recur, propose deleting them.
5. Present the full list to the user grouped as "promote to config" vs "delete as one-off", with rationale for each. Wait for approval before changing anything.

If `.claude/learnings.md` does not exist but CLAUDE.md also has no Learnings section, suggest adding the Learnings section to CLAUDE.md:

```markdown
## Learnings

When the user corrects a mistake or points out a recurring issue, append a one-line
summary to .claude/learnings.md. Don't modify CLAUDE.md directly.
```

### 2h: Headroom audit

Headroom is an optional in-flight compression layer that reduces context window usage by compressing tool outputs, Bash results, logs, and code before they reach the model — a different optimization level from env vars and `.claudeignore`, which operate at startup and configuration time.

Run:

```bash
which headroom 2>/dev/null && headroom --version 2>/dev/null | head -1 || echo "headroom-not-installed"
python3 -c "import sys; print('python-ok' if sys.version_info >= (3, 10) else 'python-too-old')" 2>/dev/null || echo "python-unavailable"
ls .headroom 2>/dev/null && echo "headroom-dir-present" || echo "headroom-dir-absent"
```

**If Headroom is installed:**

1. **`.gitignore` check**: Headroom stores machine-local data in `.headroom/` — session caches and `.headroom/CLAUDE.local.md` (machine-local learnings). These must not be committed: they are per-machine, ephemeral, and will conflict across clones. If `.headroom/` is not in `.gitignore`, flag as "should fix."
2. **Integration mode**: Detect which mode is in use:
   - *MCP mode*: look for a Headroom entry in `.mcp.json`. Verify it is still in the active server list; stale entries add tool-count overhead for nothing.
   - *Proxy/wrap mode*: `headroom wrap claude` or `headroom proxy --port 8787 --code-aware` must be run before each session. If this is not documented in CLAUDE.md (or a project README), note it — teammates will not know to start it.
3. **Code-aware flag**: For code compression to activate, the proxy must be started with `--code-aware`. Without it, code files produce `tokens_saved: 0`. Flag as a note if the user is on proxy mode and this flag is not documented.
4. **Learnings coexistence**: Headroom's `.headroom/CLAUDE.local.md` and cc-config's `.claude/learnings.md` serve different purposes and should both be kept. Headroom's file captures machine-local session patterns; cc-config's file captures explicit user corrections and is team-shared (committed to git, feeds the `cc-config-optimize` promotion cycle). Do not consolidate them.

**If Headroom is not installed and Python 3.10+ is available:**

Add to "Nice to have." Do **not** add if Python is unavailable or below 3.10, or if the project is known to run exclusively in sandboxed/remote environments (CI pipelines, Claude Code on the web) — Headroom requires a persistent local process and is incompatible with those contexts.

**If Python is unavailable or below 3.10:**

Skip. Do not mention Headroom.

## Step 3: Generate findings report

Organize findings into three categories:

### Must fix (security or correctness issues)

- Missing permissions.deny for sensitive files
- Hardcoded secrets in config files
- Deprecated patterns (ignorePatterns, npm-installed Claude Code)
- Contradictory instructions
- Hook-manager conflict: `.githooks/pre-commit` present alongside an active hook manager (the sync script is not running)

### Should fix (quality and cost improvements)

- CLAUDE.md bloat (>80 lines without good reason)
- Missing formatter hook
- Missing cost-optimization env vars
- Redundant content between files
- Skills without proper frontmatter guards
- Learnings entries that should be promoted to CLAUDE.md or a skill
- Orphaned `scripts/sync-config-table.*` with no active hook wiring
- `DESIGN.md` present at project root but not referenced via `@DESIGN.md` in CLAUDE.md (Claude won't apply the design system without the pointer)
- Headroom installed but `.headroom/` not in `.gitignore`: machine-local Headroom files (session caches, `.headroom/CLAUDE.local.md`) must not be committed — they are per-machine and will break other clones

### Nice to have (polish)

- Missing progressive disclosure for reference docs
- Missing compact instructions
- Missing Learnings section in CLAUDE.md
- Skills that could be created for recurring workflows
- MCP servers that could be added or removed
- Missing secret scanner (gitleaks) in pre-commit hook
- Sync script format mismatch with project conventions (e.g., `.sh` in a Node-only repo)
- Skills producing domain-specific output without referencing the `context/` folder at the project root (company-level knowledge duplicated or inlined per-skill)
- Context scope violations: company-level knowledge buried in campaign subfolders, or format-level guidelines in `context/` instead of the relevant skill's folder
- `context/` files present but no `## Context files` table in CLAUDE.md — skills cannot discover context files without this table
- Multi-level folder project without hierarchical CLAUDE.md files: if the repo has campaign, feature, or package subfolders where context meaningfully changes, each level should have its own CLAUDE.md that @-imports the relevant context for that scope — this lets Claude inherit all relevant context when started in any subfolder, without skills needing hard-coded paths to shared files
- Skills missing a terminal feedback step that solicits corrections into the learnings loop
- PDFs, DOCX files, or HTML pages referenced in CLAUDE.md or context files without Markdown equivalents: converting them saves significant tokens (HTML→Markdown ~90% reduction, PDF→Markdown ~65–70%, DOCX→Markdown ~33%). Tools like Pandoc, Docling, or `markitdown` convert in seconds. Flag any such files found in `context/` or referenced via `@`-imports
- Missing `.claudeignore` startup token check: suggest the user run `/context` in a fresh session to measure actual startup overhead — if high, a missing or incomplete `.claudeignore` is a likely cause
- Headroom not installed but Python 3.10+ is available (and the project is not exclusively run in sandboxed/remote environments): Headroom compresses tool outputs, Bash results, and code in-flight before they reach the model — a different optimization level from env vars and `.claudeignore`. Real-workload savings: 73–92% on code-search and log-heavy tasks. Output tokens cost 5× more than input on Opus-class models, so in-flight compression compounds quickly. Install: `pip install "headroom-ai[all]"`. Start with `headroom wrap claude` (quickest path) or `headroom proxy --port 8787 --code-aware` (proxy mode; `--code-aware` is required for code compression). Run `headroom perf` after a few sessions to measure savings. Important constraint: requires a persistent local process — not compatible with remote/sandboxed sessions (Claude Code on the web, CI pipelines). If the project is used in both local and remote contexts, Headroom benefits only the local sessions.

Present the findings to the user as a concise list, grouped by category. For each finding, state: what the issue is, why it matters, and what you'd change. Ask for approval before making changes.

## Step 4: Apply approved changes

Make the approved changes. For each file modified:

- Show a before/after summary (not full diffs for large files — just the key changes).
- Explain briefly what changed and why.

When applying learnings review results:

- For entries promoted to CLAUDE.md or a skill, remove them from `.claude/learnings.md`.
- For entries marked as one-off, remove them from `.claude/learnings.md`.
- If all entries are processed, delete `.claude/learnings.md` entirely (it will be recreated naturally when the next correction occurs).

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

Preserve things that work well. Don't refactor for the sake of refactoring. If an existing config is well-structured and correct, say so and move on.

## Step 5: Final summary

After all changes:

1. List every file modified or created, with one-line descriptions of changes.
2. Report the new metrics: CLAUDE.md line count, number of active MCP servers, hooks configured, etc.
3. Compare key metrics to before (e.g., "CLAUDE.md: 247 lines → 62 lines").
4. If learnings were reviewed: report how many entries were promoted, how many deleted, and how many remain.
5. Note anything you deliberately left unchanged and why.
6. Suggest running `/cc-config-optimize` again periodically (e.g., after major features, after a few weeks of work) to prevent config drift.
7. Remind the user to commit the changes.

## Common optimization patterns

These are recurring improvements you'll often apply:

**CLAUDE.md → Skills migration:**
When CLAUDE.md contains domain knowledge that's only needed for specific tasks, extract it into a skill. The skill loads on demand (~100 tokens metadata at rest), while CLAUDE.md content loads every message.

**Monolithic docs → Progressive disclosure:**
Replace inline documentation in CLAUDE.md with `@`-import pointers:

```markdown
### API Architecture — @docs/api-architecture.md

**Read when:** Adding or modifying API endpoints
```

**AGENTS.md as single source of truth:**
If the project has both CLAUDE.md and AGENTS.md with overlapping content, consolidate the universal parts into AGENTS.md and reduce CLAUDE.md to a slim adapter:

```markdown
@AGENTS.md

## Claude-Code-specific

- <only Claude-specific additions here>
```

**OpenSpec integration:**
If OpenSpec is present, CLAUDE.md should reference it rather than duplicate project context:

```markdown
@openspec/project.md
```

**Hook-ification of repeated instructions:**
If CLAUDE.md says "always run prettier after editing" — that's a hook, not an instruction. Replace the instruction with a deterministic PostToolUse hook and remove the line from CLAUDE.md.

**Learnings graduation:**
When `.claude/learnings.md` has accumulated entries, recurring patterns graduate into CLAUDE.md rules, skills, or hooks. One-off corrections get deleted. The file stays lean or gets removed entirely until the next correction cycle.

**Hook-manager migration for sync-config-table:**
When a project gains Husky or another hook manager after `/cc-config-init` was used, the `.githooks/pre-commit` goes silent because `core.hooksPath` is taken over. Migrate the sync script into the active hook manager's pre-commit hook and remove the now-dead `.githooks/` directory.

## What NOT to do

- Don't refactor things that work well. If a config is correct and clean, say so.
- Don't add MCP servers speculatively. Only suggest servers that address a concrete gap.
- Don't create skills for workflows that haven't been repeated yet.
- Don't modify user-level files (`~/.claude/CLAUDE.md`, `~/.claude.json`) without explicit permission.
- Don't remove functionality. If something serves a purpose, keep it — just optimize how it's expressed.
- Don't make the config dependent on tools or servers the user hasn't installed.

## Feedback

**Auto-store phase.** Before asking for feedback, review this run. For each qualifying observation, append one tagged line to `.claude/learnings.md` (create with standard header if missing). Skip entries promoted or deleted by Step 2g in this run:

```text
[cc-config:cc-config-optimize] <concise fact about this project> — <YYYY-MM-DD>
```

Qualifies: something about this project that differs from what this skill assumes on a generic project; a suggestion the user explicitly accepted or rejected that deviates from skill defaults; a constraint or fact discovered that would change how this skill behaves next time.

Does not qualify: standard skill behavior applied without deviation; facts already present in CLAUDE.md, AGENTS.md, or other config files; anything a reader could determine from the repo without this skill having run; facts semantically equivalent to any existing `.claude/learnings.md` entry — when in doubt, skip.

Check for the file before appending:

```bash
ls .claude/learnings.md 2>/dev/null && echo "exists" || echo "missing"
```

Standard header when creating the file:

```markdown
# Learnings

Corrections and observations collected during configuration sessions.
Entries are tagged by skill and dated.

---
```

**Explicit feedback.** After the auto-store phase, ask:

> "Did this optimization meet your expectations? If anything needs adjusting, share it here — or press Enter to finish."

- If the user **provides a correction**: append it as a tagged entry using the same format and qualification criteria above. Confirm total entries written across both phases: "✓ N learning(s) saved to `.claude/learnings.md`."
- If the user **confirms quality or skips**: if any entries were auto-stored, confirm "✓ N learning(s) auto-saved to `.claude/learnings.md`." Then exit. If nothing was stored, skip the confirmation and exit directly.

> **Note:** Learnings are automatically recalled at the start of the next skill run. Run `/cc-config-optimize` periodically to promote recurring patterns into the configuration.
