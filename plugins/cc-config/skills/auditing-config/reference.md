# auditing-config reference

Supporting material for `SKILL.md`. Read the relevant section when the checklist points here.

## Headroom audit

Headroom is an optional in-flight compression layer that reduces context window usage by compressing tool outputs, Bash results, logs, and code before they reach the model — a different optimization level from env vars and `.claudeignore`, which operate at startup and configuration time.

Check whether `.headroom/` exists with Glob on `.headroom/*`. Then run:

```bash
which headroom 2>/dev/null && headroom --version 2>/dev/null | head -1 || echo "headroom-not-installed"
python3 -c "import sys; print('python-ok' if sys.version_info >= (3, 10) else 'python-too-old')" 2>/dev/null || echo "python-unavailable"
```

**If Headroom is installed:**

1. **`.gitignore` check**: Headroom stores machine-local data in `.headroom/` — session caches and `.headroom/CLAUDE.local.md` (machine-local learnings). These must not be committed: they are per-machine, ephemeral, and will conflict across clones. If `.headroom/` is not in `.gitignore`, flag as "should fix."
2. **Integration mode**: Detect which mode is in use:
   - _MCP mode_: look for a Headroom entry in `.mcp.json`. Verify it is still in the active server list; stale entries add tool-count overhead for nothing.
   - _Proxy/wrap mode_: `headroom wrap claude` or `headroom proxy --port 8787 --code-aware` must be run before each session. If this is not documented in CLAUDE.md (or a project README), note it — teammates will not know to start it.
3. **Code-aware flag**: For code compression to activate, the proxy must be started with `--code-aware`. Without it, code files produce `tokens_saved: 0`. Flag as a note if the user is on proxy mode and this flag is not documented.
4. **Learnings coexistence**: Headroom's `.headroom/CLAUDE.local.md` and cc-config's `.claude/learnings.md` serve different purposes and should both be kept. Headroom's file captures machine-local session patterns; cc-config's file captures explicit user corrections and is team-shared (committed to git, feeds the `auditing-config` promotion cycle). Do not consolidate them.

**If Headroom is not installed and Python 3.10+ is available:**

Add to "Nice to have." Do **not** add if Python is unavailable or below 3.10, or if the project is known to run exclusively in sandboxed/remote environments (CI pipelines, Claude Code on the web) — Headroom requires a persistent local process and is incompatible with those contexts.

**If Python is unavailable or below 3.10:**

Skip. Do not mention Headroom.

## Audit staleness reminder

`cc-config` ships a `SessionStart` hook (`plugins/cc-config/hooks/check-optimize-staleness.sh`,
declared in `plugins/cc-config/hooks/hooks.json`) that fires in every project the plugin is
active in — no per-repo `.claude/settings.json` wiring needed, since plugin-declared hooks
apply automatically wherever the plugin is installed. On session start it reads the
`last-optimize-run` marker this step writes, compares it against the repo's current commit
count and date, and — only if the project has drifted noticeably since that baseline (default
thresholds: 20+ commits, or 14+ days with at least one new commit) — emits a short reminder
suggesting `/auditing-config`. It never blocks anything and stays silent otherwise,
including in repos that don't use `cc-config` at all (it only speaks up if it also finds
`scripts/sync-config-table.sh`, i.e. clear evidence the project already opted in).
This step is what keeps that hook's comparison meaningful — without a fresh marker, every
session in an active repo would eventually trip the threshold and nag regardless of how
recently an audit actually ran.

## Common optimization patterns

These are recurring improvements you'll often apply:

**CLAUDE.md → Skills migration:**
When CLAUDE.md contains domain knowledge that's only needed for specific tasks, extract it into a skill. The skill loads on demand (~100 tokens metadata at rest), while CLAUDE.md content loads every message.

**Monolithic docs → on-demand loading:**
`@`-imports are expanded into context together with the importing file, so they organize a CLAUDE.md but don't reduce its cost. Move content needed only for part of the codebase into `.claude/rules/<topic>.md` with `paths:` frontmatter (loads when Claude touches matching files), or into a skill (loads on demand):

```markdown
---
paths:
  - "src/api/**"
---

# API architecture
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
When `.claude/learnings.md` has accumulated entries, standing rules (stated or corrected entries, or related groups) graduate into CLAUDE.md rules, skills, or hooks. Superseded or covered entries are retired; the rest stay. The file stays lean or gets removed entirely until the next correction cycle.

**Hook-manager migration for sync-config-table:**
When a project gains Husky or another hook manager after `/bootstrapping-config` was used, the `.githooks/pre-commit` goes silent because `core.hooksPath` is taken over. Migrate the sync script into the active hook manager's pre-commit hook and remove the now-dead `.githooks/` directory.
