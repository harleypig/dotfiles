# Audit icebox

Deferred Claude-agent-config decisions — **considered, "not now."** This is
the audit-scope home for the `ICEBOX:` marker (`rules/code-style.md`): a
deferred / maybe-someday decision to revisit on a **trigger** or **on
request**, for cases that have no single code location to pin an in-code
`ICEBOX:` comment to.

**This is not a todo file.** Items here are *not* open work — the
[`BACKLOG.md`](BACKLOG.md) holds will-do tasks. The boundary with the other
"not now" homes:

- **Mined external** candidate deferred `SKIP-until <trigger>` →
  [`mining-census.md`](mining-census.md) *Watch list* (a terse trigger→adopt
  table tied to the survey record). **Not here.**
- **Our own** deferred finding / decision, with its context → **here.**
- **Will do it** → `BACKLOG.md`.

Each entry states its **revisit condition**: a concrete trigger (an upstream
issue landing, a feature becoming needed) or "**on request only**" (the
classic `ICEBOX:` semantics). `claude-audit` scans this file each run —
alongside the mining files and the Watch list — to surface any fired trigger;
otherwise it leaves these alone.

## Statusline: the native below-prompt indicator lines can't be hidden

**Revisit if** anthropics/claude-code **#27916** or **#48246** lands a hide
option for the native indicators.

The **auto-accept / permission-mode** indicator (`⏵⏵ auto mode on`), the
**running-subagent / task** line, and the **`· PR #N`** badge have **no
off-switch** (settings, env, or flag) as of 2026-06-19 — verified against the
Claude Code docs and by re-examining `claude-hud` (which sets no suppression
key, can't even read the permission mode, and only stacks a transcript-parsed
agents line *on top of* the native one). The only documented `statusLine` hide
field is `hideVimModeIndicator`; the full set of `statusLine` sub-fields is
`type` / `command` / `padding` / `refreshInterval` / `hideVimModeIndicator` /
`subagentStatusLine` (the last **formats** subagent rows — it does **not**
hide the native line). Consequence: reconstructing any of these (PR#,
permission mode, agents) in our own statusline would only **duplicate** the
un-hideable native badge, so it isn't worth it — the permission mode and PR#
are both in the data (permission mode in the **transcript**
`permission-mode`/`mode` entries; `.pr.number` in the **stdin** JSON), they
just can't replace the native display. Until an upstream hide option lands,
only the vim indicator was controllable (and is done).

## Statusline: heavier / transcript-driven candidates

**Revisit if** the plain `X%` context gauge stops being enough, or a
transcript-driven line becomes wanted.

The heavier statusline candidates — the **tools/agents lines** and a **todos
`(2/5)`** counter — are transcript-driven and deferred. *(2026-06-19: project
path, session duration, output speed, and token totals were skipped by the
user; the context progress-bar glyph is the `SKIP-until` item on the
[`mining-census.md`](mining-census.md) Watch list — revisit there if the plain
`X%` stops being enough.)*

## Commit & changelog tooling (commitizen, git-cliff, conventional-changelog)

**Revisit when** a repo wants tool-driven conventional-commit authoring or
`cz`-style version bumping (→ commitizen), or a changelog **generated** from
git history rather than hand-written (→ git-cliff / conventional-changelog).

Evaluated 2026-06-20 and **not adopted** — the agent and the dotfiles repo
already cover the need without these tools:

- **Conventional commits** are mandated in `rules/git.md` *Commit Messages*
  and authored directly by the agent; no `commitizen` (`cz`) CLI, config, or
  hook is used or needed.
- **The changelog** is **manual** keep-a-changelog, written at merge-time
  (`ship-pr` Step 4.5), grouped by date because the dotfiles repo isn't
  release-versioned. `.claude/QA.md` records *Generated changelog: N/A*.

If a repo *does* adopt one — a release-versioned component repo wanting a
git-history changelog, or a team wanting enforced `cz` commits / `cz bump` —
author the tool rule **then**, global and on first use (ADR-0003): a
`commitizen.md` and/or a generator rule (weigh **git-cliff** vs
**conventional-changelog**), wired into `qa.md` dim 13 (a generated changelog
is a Format-class prep step) and the release flow (the `release-tag` skill).

## TODO-file structure hook (enforce/remind `rules/todo.md` on edits)

**Revisit if** planning-doc structure drift becomes a *recurring* problem that
the `rules/todo.md` + `todo-organize` skill + `qa-check` audit half does not
catch in practice.

Considered during the todo-management build (PRs #164–#165) and **deferred by
decision.** A hook is for *deterministic, must-happen* enforcement, but TODO
routing is a **judgment** call — a hook can't reliably tell whether an item is
in the *right* `## <X> Setup` section. The most a hook could do is *inject a
routing reminder* when a `TODO.md` / `ROADMAP.md` / `BACKLOG.md` is edited
(the way `merge-finalization.py` injects its checklist) — cheap, but likely
noise once the rule + skill exist. A structural *validator* (warn on a `##`
heading that is neither `<X> Setup` nor a known project/audit) was also
weighed but risks false positives from per-repo project names. Build the
reminder and/or validator only if drift recurs despite the rule and the
qa-check audit.
