# Learnings Protocol

_Last updated: 2026-11-10_

`.claude/learnings.md` is the project's memory between sessions. It holds what a future run on this project needs to know but cannot read from the request, `CLAUDE.md` or the registered context files. Every clever-cc-plugins skill reads and writes it by this protocol. This file is identical in every plugin; change it in all plugin repos at once.

## Entry format

One line per entry, a blank line between entries:

```text
[<plugin>:<skill>] <observation> (<source>) — <YYYY-MM-DD>
```

- The tag names the skill that wrote the entry. It is provenance, not a filter: every skill applies every relevant entry.
- `<source>` records how the entry is known:
  - `stated`: the user said it as a standing preference, rule or fact.
  - `corrected`: the user corrected an output. The entry records the corrected behaviour, not the mistake.
  - `inferred`: the skill concluded it from the run. The user has not confirmed it.
- Entries without a source marker predate this protocol. Treat them as `stated`, and do not rewrite them only to add a marker. Many were stored silently and may be old guesses, so a review judges their source from the wording.

## Recall

Before any other work, read `.claude/learnings.md` in full if it exists. Apply the entries relevant to this run. When two entries conflict, `stated` and `corrected` beat `inferred`; between equal sources the newer date wins, and between equal sources and equal dates the line lower in the file wins. When an entry conflicts with `CLAUDE.md` or a registered context file, the file wins: the entry is stale, and a review should retire it. Never announce this step. Mention an entry only when it changes what you do.

## Writing

Record what a future run on this project would need and could not read from the request, `CLAUDE.md` or the context files: preferences, constraints, project facts, corrections, and non-default choices the user accepted. Do not record standard behaviour applied without deviation, details that only mattered for this run, or anything an existing entry already says. Prefer one precise entry over several partial ones. When in doubt, skip.

Before writing, compare the new observation with every existing entry, under any tag:

1. **An equivalent entry exists:** write nothing. If the new source is stronger (`stated` or `corrected` over `inferred`), update that entry's source and date in place instead.
2. **The observation contradicts or updates an existing entry:**
   - New source `stated` or `corrected`, or both `inferred`: replace the old line in place with the new entry. The new line carries the current skill's tag, even if the old line had another tag. This is intended: the entry now belongs to the plugin that last confirmed it, so a review that filters by its own plugin's tags sees it only from then on (`auditing-config` reads every tag).
   - New source `inferred`, old entry `stated`, `corrected` or unmarked: keep the old entry and write nothing. If this run gave real reason to doubt it, ask the user before changing anything.
3. **Otherwise:** append the new entry at the end of the file.

Locate a line you replace or update by its full text, so the edit cannot hit a similar line. Never leave two entries in the file that contradict each other.

If the file does not exist, create it with this header first:

```markdown
# Learnings

Observations and corrections collected by clever-cc-plugins skills. One entry per line: `[plugin:skill] observation (stated|corrected|inferred) — YYYY-MM-DD`.

---
```

## Confirming

At the end of the skill's feedback step, after the user has answered or skipped the feedback question, show every entry this run wrote or replaced, including corrections recorded from the user's answer, verbatim, in one block. Mark new entries with `+` and every changed entry (a replacement, or a source or date upgraded in place under Writing rule 1) with `~`, followed by the line it replaced:

```text
Saved to .claude/learnings.md:
+ [cc-content:linkedin-post] Links go in the post body, never in the first comment (stated) — 2026-11-10
~ [cc-content:linkedin-post] Hashtags are optional, two at most (corrected) — 2026-11-10
  replaces: [cc-content:linkedin-post] Use 3–5 hashtags (inferred) — 2026-10-02
```

Follow the block with one line inviting the user to drop or change any of these. Apply their answer if they give one. If the run wrote nothing, say nothing about learnings.

## Reviewing

Review skills (`session-wrap`, `learnings-promotion`, `auditing-config`) consolidate the file. Each review skill sets its scope (which tags, which entries) and its promotion targets. These rules are shared:

1. Read the entries in scope, plus `CLAUDE.md` and the registered context files.
2. Group entries that express the same underlying concern, however they are worded.
3. Propose one action per group or single entry, stating the entry count, the sources and a one-line reason:
   - **Promote:** a standing rule. That is any `stated` or `corrected` entry, or a group of agreeing `inferred` entries that you judge still relevant and likely true; say why, because repetition alone does not make an inference true. For an unmarked entry the source is unknown: judge from its wording whether the user said it, and say so in the proposal. Frequency is a signal, not a threshold: one stated rule can qualify, and three unconfirmed inferences can still be wrong. Choose the narrowest target that reaches every run needing the rule: a skill's guidelines, a context file or a voice guide before `CLAUDE.md`, which every session loads.
   - **Keep:** still true and useful, but not yet a standing rule. Typically a single `inferred` entry.
   - **Retire:** already covered by `CLAUDE.md` or a context file (name the file), contradicted by one of them, superseded by a newer entry, or tied to a situation that is over. Never retire a `corrected` or `stated` entry only because a file contradicts it: if the file is the one that is out of date, propose updating the file and keep the entry until the user has decided.
4. Apply nothing before the user decides each proposal: promote, keep or retire. Remove promoted and retired entries from `.claude/learnings.md`; leave kept entries unchanged. When no entries remain below the header, delete the file, or leave only the header if you cannot delete files.
