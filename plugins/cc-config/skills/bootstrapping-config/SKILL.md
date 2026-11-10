---
name: bootstrapping-config
description: Bootstrap a best-practice Claude Code configuration for a new or unconfigured project. Use this skill when a user asks to set up Claude Code, initialize a project, create a CLAUDE.md, or configure permissions/hooks/settings for the first time. Also use when the user says things like "set up this project", "configure Claude Code", "bootstrap config", or "better /init". This skill replaces the built-in /init with a leaner, more opinionated setup grounded in current best practices.
allowed-tools: Read, Grep, Glob, Edit(**/CLAUDE.md), Edit(.claude/**), Edit(.githooks/**), Edit(.github/workflows/**), Edit(scripts/sync-config-table.js), Edit(.husky/pre-commit), Edit(AGENTS.md), Edit(.mcp.json), Edit(.gitignore), Edit(scripts/sync-config-table.sh), Write(CLAUDE.md), Write(.claude/**), Write(.githooks/**), Write(.husky/pre-commit), Write(.gitignore), Write(.github/workflows/**), Write(scripts/sync-config-table.sh), Write(scripts/sync-config-table.js), Bash(git rev-parse:*), Bash(git log:*), Bash(git config core.hooksPath:*), Bash(jq:*), Bash(bash scripts/sync-config-table.sh), Bash(test -f:*), Bash(wc:*), Bash(date +%Y-%m-%d), Bash(chmod +x .githooks/pre-commit), Bash(chmod +x scripts/sync-config-table.sh)
argument-hint: "[optional: brief project description]"
---

# Bootstrap Claude Code Configuration

You are setting up a Claude Code configuration from scratch. The project directory may be empty or nearly empty. Your goal is to create a lean, high-quality baseline that works for any project regardless of language, framework, or tooling.

## Philosophy

Every line in CLAUDE.md costs context tokens on every single message. Frontier models follow ~150–200 instructions reliably; the system prompt already uses ~50. That leaves ~100–150 slots before quality degrades across all rules. Configuration is a multiplier on everything Claude Code does — invest in it upfront, keep it lean, let automation compound.

The single most impactful principle: give Claude a way to verify its work. If Claude has a feedback loop (tests, linters, type checkers), it can catch and fix its own mistakes before you see them.

## Step 0: Recall learnings

Read `../_shared/learnings-protocol.md` and follow its **Recall** section. The tag on each entry is provenance only — all entries apply regardless of which skill wrote them.

If the file does not exist, proceed without mention.

## Step 1: Gather context

Before creating any files, understand what you're working with.

1. Check if a git repo exists. If not, do NOT create one — just note it for the user.
2. Look for existing config: `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.mcp.json`, `context/`. If any exist, tell the user this skill is for fresh setups and suggest using `/auditing-config` instead.
3. Scan for clues about the project. Cover both code and content projects:
   - **Code**: `package.json`, `composer.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`, `Gemfile`, `pom.xml`, `build.gradle`, any `*.sln` or `*.csproj` files.
   - **Content / static sites / docs**: `hugo.toml`, `config.toml`, `config.yaml` (Hugo), `_config.yml` (Jekyll), `astro.config.*`, `.eleventy.js`, `mkdocs.yml`, `content/`, `articles/`, `posts/`, `_posts/`, dominant `.md` files, knowledge base or style guide files (`STYLE.md`, `style-guide.md`).
   - Always check `README.md` for purpose.
   - **Design system**: `DESIGN.md` at the project root (open-source format — YAML design tokens + Markdown rationale; Claude Code and other agents read it automatically). Also check `context/design/` for Claude Design handoff artifacts (PROMPT.md, design-notes.md, screenshots/).
4. Check for existing quality tools:
   - **Code**: `.eslintrc*`, `.prettierrc*`, `phpcs.xml*`, `rustfmt.toml`, `.editorconfig`, CI configs (`.github/workflows/`, `.gitlab-ci.yml`), pre-commit configs.
   - **Content**: `.vale.ini` / `vale.ini`, `.markdownlint.{json,yaml,yml}`, prettier configured for Markdown.
5. Check for sensitive files: `.env`, `.env.*`, `secrets/`, any `*credentials*` or `*secret*` files.
6. **GitHub Actions**: Check whether `.github/` exists or the git remote points to GitHub. Note the result — used in Step 4a.

If the project directory is truly empty or has minimal content, ask the user:

- What does this project produce? (e.g. a web app, a library, articles for a tutorial site, documentation)
- What stack or toolchain is involved? (e.g. Next.js + npm, Hugo, Pandoc, plain Markdown, etc.)
- Are there inputs you'll reference repeatedly, like a shared knowledge base or style guide?

If `$ARGUMENTS` was provided, use that as the project description and infer what you can. Only ask about things you genuinely cannot determine.

Regardless of project size, also ask:

- Is there domain knowledge that should live in a shared context folder for all future skills to reference? (Examples: company profile, brand voice, buyer personas, architecture decisions, API contracts, editorial standards.) See the Domain context folder section in Step 2 — ask the user what types of company-level context they have, then name and scaffold files accordingly.

## Step 2: Create .claude/settings.json

This file provides permissions, hooks, and environment variables. It goes into version control.

Build it from these components:

### Permissions

Always include `permissions.deny` for sensitive files. Adapt the patterns to what you found in Step 1:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.local)",
      "Read(./.env.*.local)",
      "Read(./.env.development)",
      "Read(./.env.production)",
      "Read(./.env.staging)",
      "Read(./.env.test)",
      "Read(./secrets/**)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(rm -rf:*)"
    ]
  }
}
```

**Prefer an enumerated deny list over a broad `Read(./.env.*)`.** The broad glob also matches example and template files (`.env.example`, `.env.sample`, `.env.template`, `.env.dist`, `example.env`), which hold no secrets and should stay readable. Evaluation order is deny → ask → allow, so an `allow` rule can never re-open a denied path. The current permissions docs describe gitignore-style negation for deny rules (e.g. `Read(*.env)` followed by `Read(!sample.env)`), but it is version-dependent and hasn't been verified for this skill — so enumerate the real secret-bearing variants and pair the list with the PreToolUse guard below for full `.env.*` coverage with the example carve-out. Read deny rules also cover `cat`/`head`/`tail` on a named file in Bash, but not `grep -r` or scripts that open files themselves.

`Bash(curl:*)`, `Bash(wget:*)` and `Bash(rm -rf:*)` deny rules only stop the usual invocation (`/usr/bin/curl` or `sh -c 'curl …'` slip past) — they are guard rails, not a security boundary. Use the sandbox when the restriction must hold. The template has no `ask` rule for `git push` on purpose: `ask` prompts even in `auto` and `bypassPermissions` mode, and its wildcards match the whole command text, so it also prompts for harmless commands that merely mention `push`. Add `"ask": ["Bash(git push*)"]` only if the user explicitly wants a push confirmation.

Adjust deny rules based on what you found:

- If there are credential files, add patterns for them.
- If SSH keys or cloud credentials exist nearby, add those too.
- If the project uses other secret-bearing env variants (e.g. `.env.ci`), add explicit `Read()` denies for them — but never for `*.example` / `*.sample` / `*.template` / `*.dist` files.

For `permissions.allow`, add entries only if you can identify concrete, safe commands from the project (e.g., `Bash(npm run test:*)`, `Bash(cargo test:*)`). If the project is too empty to know, leave `allow` out — the user will add it interactively and can persist choices via `/permissions`.

### Hooks

If you identified a formatter in Step 1, add a PostToolUse hook:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "<formatter-command> || true"
          }
        ]
      }
    ]
  }
}
```

Common formatter commands by ecosystem:

- JS/TS: `jq -r '.tool_input.file_path' | xargs npx prettier --write`
- PHP: `jq -r '.tool_input.file_path' | xargs php-cs-fixer fix`
- Rust: `jq -r '.tool_input.file_path' | xargs rustfmt`
- Python: `jq -r '.tool_input.file_path' | xargs ruff format`
- Go: `jq -r '.tool_input.file_path' | xargs gofmt -w`
- Markdown: `jq -r '.tool_input.file_path' | xargs npx prettier --write` or `jq -r '.tool_input.file_path' | xargs markdownlint --fix`

Vale is a prose linter, not a formatter — don't wire it into PostToolUse. If you want Vale to run, suggest it as a manual command in CLAUDE.md instead.

If no formatter is detected, skip the hook — don't guess. Note it in the summary for the user to add later.

For formatter hooks the `|| true` suffix is mandatory — a formatter must never crash Claude Code or block an edit. Security hooks are the exception (see below): they must fail closed, so they deliberately omit `|| true` and exit non-zero to block.

**PreToolUse — secret-file guard (recommended).** This gives the broad `.env` / `.env.*` coverage the deny list deliberately avoids, while carving out example files. Write it to `.claude/guard-secret-files.sh` and register it for `Read|Edit|Write`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/guard-secret-files.sh"
          }
        ]
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# PreToolUse: blocks reads/edits/writes of secret .env files; allows .env.example and similar templates.
command -v jq >/dev/null 2>&1 || { echo "Blocked: jq is required to check file paths" >&2; exit 2; }
input=$(cat)
f=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null)
b=$(basename "$f")
case "$b" in
  *.example|*.sample|*.template|*.dist|example.env|sample.env) exit 0 ;;
esac
case "$b" in
  .env|.env.*)
    echo "Blocked: $b matches secret env-file pattern" >&2
    exit 2
    ;;
esac
exit 0
```

The hook must exit **2** to block — any other non-zero code is a non-blocking error and the tool call proceeds. It fails closed: without `jq` it blocks instead of passing silently. Do **not** append `|| true` to it. `jq` is a prerequisite.

### Environment variables

Don't set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` by default. It can only _lower_ the compaction threshold and only applies in sessions that compact before the model's context limit, so on a typical local session it is likely a no-op. Mention it only as niche tuning for such sessions.

Don't set `MAX_THINKING_TOKENS`. Current models (Opus 4.7+, Sonnet 5+, Haiku 5.5, Fable) always use adaptive reasoning and ignore it; it only acts as a fixed budget on Opus/Sonnet 4.6 with adaptive reasoning disabled.

Optionally include `CLAUDE_CODE_SUBAGENT_MODEL: "haiku"` to route subagent work to a cheaper model. Avoid citing a savings percentage; it varies by workload, and the variable overrides every subagent's own `model:` frontmatter.

Advisory only (not a file to write): `alwaysThinkingEnabled` defaults to on, so `true` changes nothing — only `false` has an effect. `effortLevel` (`low`, `medium`, `high`, `xhigh`; unset by default) controls reasoning depth per turn; higher levels fill context faster. Leave both alone unless the user has a specific need.

### Domain context folder

Context knowledge lives at three scope levels. Explain this to the user before creating anything:

**Level 1 — Company/project scope** (`context/`): Knowledge that applies to all work in this repo. Examples: company profile, brand voice, buyer personas, architecture decisions, API contracts. One file per distinct type of knowledge — name files after what they contain, not a fixed schema. Update one file, every skill that references it reflects the change.

**Level 2 — Format scope** (inside each skill's own folder): Knowledge specific to producing one output type — a whitepaper structure guide, blog length conventions, API endpoint style rules. Belongs with the skill that uses it, not in `context/`.

**Level 3 — Campaign/feature scope** (regular project subfolders): Briefings, campaign assets, or feature specs for a specific initiative. Scoped to that subfolder — not shared globally.

If the user confirmed company-level context in Step 1, ask: "What types of company-level context do you have?" Create one file per type they describe, with a `TODO` marker and a one-line description of what belongs there. Do not prescribe filenames — use names that reflect the actual content (`company-profile.md`, `brand-voice.md`, `buyer-personas.md`, `architecture-decisions.md`, or whatever fits the project).

Also create `context/README.md` as a brief index explaining the convention:

```markdown
# Context

Company-scoped knowledge referenced by skills and CLAUDE.md files across this repo.
One file per type of knowledge — update once, every reference reflects the change.

Format-specific guidelines live inside each skill's own folder, not here.
Campaign or feature briefings live in their respective project subfolders, not here.
```

Register each context file in the `## Context files` table in CLAUDE.md (see Step 3).

**Hierarchical CLAUDE.md for multi-level projects:** If the project has a nested folder structure — a marketing monorepo with campaign subfolders, a multi-package code repo, a website with distinct content sections — suggest CLAUDE.md files at each meaningful directory level:

- Root `CLAUDE.md` → `## Context files` table listing all company-wide context files from `context/`
- Each subfolder's `CLAUDE.md` → @-imports briefings or specs scoped to that folder

When Claude Code starts in any subfolder, it reads CLAUDE.md files up the directory tree, so a session in `campaigns/product-xy/june-2026/` automatically gets company context (via root CLAUDE.md) plus campaign context (via the local CLAUDE.md). Skills invoked in that session inherit all of it without hard-coded absolute paths to shared files. Guide the user to create and maintain CLAUDE.md files at each level where the context meaningfully changes as the project structure grows.

**Claude Design handoffs:** If the project uses Claude Design (Anthropic's visual design tool), direct the user to place Claude Design handoff artifacts (PROMPT.md, design-notes.md, screenshots/) in `context/design/` — not the project root. This keeps handoff snapshots versioned alongside the codebase without cluttering the root. `DESIGN.md` is different: it is a persistent, project-wide design system spec (YAML tokens + Markdown rationale) that lives at the project root and is auto-read by Claude Code and other agents. If `DESIGN.md` already exists or is being added, import it from CLAUDE.md with `@DESIGN.md` (or, if it is large, load it via a `.claude/rules/` file with `paths:` globs for UI files) — do not copy its contents into `context/`.

## Step 3: Create CLAUDE.md

Build a project-level CLAUDE.md. Target 20–40 lines for a fresh project. It will grow as the project grows.

Structure:

```markdown
# <Project Name>

<One-line description. Stack or toolchain summary — works for code (e.g. "Next.js + Prisma") or content (e.g. "Hugo site, articles in Markdown, edited with Vale").>

## Commands

<List exact commands the project uses. Examples:

- Code projects: `npm test`, `cargo build`, `pytest tests/`
- Content/static-site projects: `hugo build`, `vale .`, `markdownlint **/*.md`, `pandoc input.md -o output.pdf`
  If unknown yet, add placeholders with TODO markers.>

## Structure

<Only if you can already identify a meaningful directory layout. Otherwise omit. For content projects, mention things like the article output directory or where the knowledge base lives.>

## Context files

<!-- cc-config: context-toc-registered -->

<Add this section only if a context/ folder was created in Step 2. Skills discover
and load these files on demand — they are not pre-loaded. One row per file, with a
short summary drawn from the file's content (10–20 words).

The Label is free-form — name it so the owner recognizes the file at a glance. The
Summary is the load-bearing field: skills match it against what they need in order to
decide whether a file is relevant, so make it specific ("Formal German, em-dash
preferred — all corporate copy" beats "Writing style guidelines"):>

| Label   | File                | Summary                 |
| ------- | ------------------- | ----------------------- |
| <label> | `context/<name>.md` | TODO: brief description |

The `<!-- cc-config: context-toc-registered -->` comment is load-bearing, not
decorative — it tells `scripts/sync-config-table.sh` that these files are already
registered here with real summaries, so it must not also list them in
`## Key Config Files` with a generic placeholder. Always include it whenever this
section is created, and keep it if the section is edited later.

## References

<Optional. `@path` imports are expanded into context together with this file — they do NOT save tokens. Use them only for files needed in every session (e.g. AGENTS.md, a short DESIGN.md). For material needed only sometimes, use `.claude/rules/<topic>.md` with `paths:` frontmatter (loads when Claude touches matching files) or a skill.

@AGENTS.md
@DESIGN.md

Only include this section if such files exist. Do not put context/ files here —
they belong in the Context files table above.>

## Conventions

<Only concrete rules that deviate from defaults or that Claude commonly gets wrong. For content projects this might be voice/tone, terminology, or output format requirements. For code projects, conventions that aren't enforced by the linter. If the project is too new, keep this minimal or omit.>

## Don't

<Explicit prohibitions. Always include at minimum:>
- Don't commit secrets or credentials to git
- Don't use --force flags — fix the underlying issue instead

## Learnings

When the user corrects a mistake or points out a recurring issue, record a one-line entry in .claude/learnings.md as `[claude:note] <observation> (corrected) — YYYY-MM-DD` (use `(stated)` when the user states a standing rule). If it contradicts an existing entry, replace that entry instead of adding a second one. Don't modify CLAUDE.md directly.

## Compact Instructions

When compacting, preserve: list of modified files, current test status, open TODOs, and key decisions made.
```

Rules for writing CLAUDE.md:

- Never include standard language conventions Claude already knows.
- Never include rules that the linter/formatter enforces — "never send an LLM to do a linter's job."
- Never include personality instructions ("be a senior engineer").
- Never include file-by-file codebase descriptions.
- Use `IMPORTANT:` or `YOU MUST` sparingly — if everything is important, nothing is.
- Prefer concrete commands over vague advice ("run `npm test -- auth.test.ts`" beats "run the relevant tests").

## Step 4: Create AGENTS.md (if multi-tool environment)

Only create this if you have evidence that other AI coding tools are used (e.g., `.codex/`, `.gemini/`, `.github/copilot/`, cursor-related configs, or the user mentions it).

AGENTS.md is the vendor-neutral standard read by Codex, Amp, Cursor, Copilot, and others. Claude Code (2.1.277+) reads it natively only when no CLAUDE.md exists, so keep a CLAUDE.md that imports it.

If created, keep it focused on universal concerns: setup commands, architecture boundaries, code style rules, testing conventions, and safety rules. Then reference it from CLAUDE.md via `@AGENTS.md`.

## Step 4a: Add Claude Code GitHub Actions (if GitHub project)

If Step 1 detected that this is a GitHub-hosted project and `.github/workflows/` does not already contain Claude Code action files, ask once:

> "Would you like to add Claude Code GitHub Actions?
>
> - **`claude-code-review.yml`** — automatically reviews every pull request when it's opened or updated
> - **`claude.yml`** — lets anyone trigger Claude by mentioning `@claude` in issues, PR comments, or PR reviews
>
> Both require a `CLAUDE_CODE_OAUTH_TOKEN` secret set in your GitHub repo settings. Add one, both, or skip."

- If the user says **yes to both** (or just "yes"): read the companion files from `github-actions/claude-code-review.yml` and `github-actions/claude.yml` (in this skill's directory) and write them to `.github/workflows/`. Create the `.github/workflows/` directory if it does not exist.
- If the user says **one only**: write only the requested file.
- If the user says **skip** or the project is not on GitHub: skip without mention in the summary.

After writing, do **not** add the workflow files to the Key Config Files table in Step 6 — the sync script already picks up `.github/workflows/` entries automatically.

Note in Step 7 if any workflow files were added: the user must add `CLAUDE_CODE_OAUTH_TOKEN` as a repository secret in GitHub Settings → Secrets and variables → Actions before the workflows will run.

## Step 4b: Offer auto-pull on session start (if git repo with a remote)

If Step 1 found a git repo with a configured remote, ask once:

> "Do you work on this repo from multiple computers and sometimes forget to `git pull` before starting a session? I can set up an automatic fetch + fast-forward at the start of every session — it never merges or rebases, and if history has diverged it skips with a message instead of touching anything. This is a personal setting (not shared with collaborators). Enable it?"

- If **yes**: create or update `.claude/settings.local.json` with `{"env": {"CC_CONFIG_AUTO_GIT_PULL": "true"}}` (merge into an existing `env` block, don't clobber other keys). The bundled `auto-git-pull.sh` `SessionStart` hook (declared in the plugin's own `hooks.json`, no project-level wiring needed) reads this flag. Confirm `.claude/settings.local.json` is covered by `.gitignore` (see Step 5) so the flag stays machine-local.
- If **no** or the project has no remote yet: skip without mention in the summary.

Do not add this file's contents to the Key Config Files table in Step 6 — `.claude/settings.local.json` is gitignored and personal, not part of the tracked config surface.

## Step 5: Update .gitignore

Append these lines if they're not already present:

```
# Claude Code — personal files
.claude/settings.local.json
.claude/local.md
```

Claude Code has no documented ignore-file mechanism (`.claudeignore` is not a supported feature). To keep Claude away from paths, use `permissions.deny` rules on `Read`; dependency and build directories are already skipped by Glob/Grep via `.gitignore`.

## Step 6: Create Key Config Files table auto-sync

Add a "Key Config Files" table to CLAUDE.md and a pre-commit hook that keeps it in sync with the filesystem. This gives Claude instant orientation on every message without manual maintenance.

### 6a: Add the table to CLAUDE.md

After the project description line, add a `## Key Config Files` section with a Markdown table listing every config file you created in the previous steps. Use this format:

```markdown
## Key Config Files

| File                    | Purpose                                    |
| ----------------------- | ------------------------------------------ |
| `CLAUDE.md`             | Project instructions, loaded every message |
| `.claude/settings.json` | Permissions, hooks, environment variables  |
| `.gitignore`            | Git ignore patterns                        |
```

Include only files that actually exist and are tracked by git (not gitignored). Write a concise, specific purpose for each.

### 6b: Install the sync script

Read the companion file `scripts/sync-config-table.sh` (in this skill's directory) and write it verbatim to `scripts/sync-config-table.sh` in the project. Create the `scripts/` directory if it does not exist. Do not retype the script from memory and do not edit it while copying — it carries a `# sync-config-table-version: N` marker on line 2 that `/auditing-config` uses to detect when a project's copy has fallen behind the plugin's. A hand-modified copy defeats that check.

The script keeps the table in sync by rebuilding it from the filesystem on each commit: it drops rows for files that no longer exist, appends rows for new config files with a `TODO` placeholder, preserves every hand-written description, and skips gitignored files.

Every directory it scans is guarded by an existence check, so the same script self-adapts to the project shape — a content project's `plugins/` scan is a no-op, a plugin repo's `context/` scan is a no-op. **Do not fork or trim it for the project at hand.** Local edits are what strand a repo on an old version.

Make the script executable: `chmod +x scripts/sync-config-table.sh`

### 6c: Create the pre-commit hook

Create `.githooks/pre-commit`:

```bash
#!/usr/bin/env bash
# Keep CLAUDE.md config file table in sync
bash scripts/sync-config-table.sh
```

Make it executable: `chmod +x .githooks/pre-commit`

### 6d: Activate the hooks directory

Run this command to tell git to use `.githooks/` instead of the default `.git/hooks/`:

```bash
git config core.hooksPath .githooks
```

This needs to be run once per clone. Note this in the summary (Step 7) so the user is aware.

**Important:** If the project already uses Husky or another hook manager, skip this entire step and note it in the summary. The sync script would conflict with existing hook infrastructure.

### 6e: Write the audit baseline marker

Add `<!-- cc-config: last-optimize-run: YYYY-MM-DD <sha> -->` to CLAUDE.md (today's date via
`date +%Y-%m-%d`, current commit via `git rev-parse HEAD` — if the repo has no commits yet,
use `HEAD` as a harmless placeholder; the bundled hook only reads a SHA it can resolve). Place
it near the `## Key Config Files` table. This gives `cc-config`'s bundled `SessionStart` hook
(`plugins/cc-config/hooks/check-optimize-staleness.sh`) a baseline from the very first commit,
so it can later remind the user to run `/auditing-config` once the project has drifted —
see that skill's "Audit staleness reminder" section for the full mechanism.

## Step 7: Present summary

After creating all files, give the user a concise summary:

1. List every file created with a one-line description — including any `context/` files if they were scaffolded.
2. Note any TODO placeholders that need filling in once the project takes shape.
3. Mention what was intentionally left out and why (e.g., "No PostToolUse hook yet because no formatter was detected — add one once you pick a formatter.").
4. Remind the user of five high-leverage next steps:
   - Run `/context` in a fresh session immediately after setup to check startup token overhead. If it exceeds ~10,000 tokens before sending a single message, something is loading too much — oversized CLAUDE.md, `@`-imports (they load eagerly), or a large number of MCP tools are common causes. `/doctor prompt-audit` can also review CLAUDE.md, rules and skills.
   - Add test/build/lint commands to CLAUDE.md once they exist.
   - Run `/auditing-config` after the project has some code to get a project-aware configuration pass.
   - Consider adding MCP servers to `.mcp.json` as needs arise (Context7 for docs, GitHub for PRs, etc.).
   - Once recurring multi-step workflows emerge, the `/schedule` skill can automate them — run a chain of skills on a cron schedule and land the output in a review folder for human sign-off before anything goes live.
5. If auto-pull on session start was enabled (Step 4b), remind the user: it's stored in `.claude/settings.local.json` (machine-local, gitignored), so it needs to be re-enabled separately on each other computer where they want it.
6. If GitHub Actions workflow files were added (Step 4a), remind the user:
   - Add `CLAUDE_CODE_OAUTH_TOKEN` as a repository secret in **GitHub Settings → Secrets and variables → Actions** before the workflows will run.
   - The token is a Claude Code OAuth token from your Anthropic account — not an API key.
7. If the Key Config Files auto-sync was set up (Step 6), remind the user:
   - The pre-commit hook requires a one-time activation per clone: `git config core.hooksPath .githooks`
   - This command was already run for the current clone, but collaborators or fresh clones need to run it too.
   - Suggest documenting it in the project README's setup instructions.
8. Explain the Learnings mechanism:
   - The skills automatically store project-specific observations to `.claude/learnings.md` at the end of each run and recall them at the start of the next — no manual action required.
   - When the user corrects a mistake, Claude also records a one-line correction in `.claude/learnings.md` (replacing a contradicted entry instead of stacking a second one) instead of modifying CLAUDE.md directly.
   - Running `/auditing-config` periodically reviews the file and proposes promoting, keeping or retiring entries by source and relevance.
9. If the Key Config Files auto-sync was set up (Step 6), also mention: `cc-config`'s bundled `SessionStart` hook will automatically nudge to run `/auditing-config` once the project has drifted noticeably from today's baseline (default: 20+ commits or 14+ days with new activity) — no setup needed, it fires in any project the plugin is active in.
10. Suggest committing the new config files to git.

## What NOT to do

- Don't run `/init`. This skill replaces it.
- Don't create MCP configs. MCP choices are project-specific and premature for an empty project.
- Don't create skills. Skills encode recurring workflows that don't exist yet.
- Don't create `.claude/local.md` or `settings.local.json`. Those are personal and should be created by the user.
- Don't over-engineer. A 20-line CLAUDE.md that's accurate beats an 80-line one full of guesses.
- Don't include information you're not confident about. TODOs are better than wrong instructions.

## Feedback

**Auto-store phase.** Read `../_shared/learnings-protocol.md` and follow its **Writing** section. Tag entries `[cc-config:bootstrapping-config]`; the source is `inferred` unless the user said it. Worth recording in this skill: a concise fact about this project that differs from what this skill assumes on a generic project; a suggestion the user explicitly accepted or rejected that deviates from skill defaults; a constraint or fact discovered that would change how this skill behaves next time.

**Explicit feedback.** After the auto-store phase, ask:

> "Did this configuration meet your expectations? If anything needs adjusting, share it here — or press Enter to finish."

- If the user provides a correction, record it per the protocol's **Writing** section with source `corrected`.
- Then follow the protocol's **Confirming** section.

> **Note:** Learnings are automatically recalled at the start of the next skill run. Run `/auditing-config` periodically to review learnings: promote, keep or retire them by source and relevance.
