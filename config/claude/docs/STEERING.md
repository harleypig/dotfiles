# Steering Claude Code

**Steering** is customizing how Claude Code behaves — the umbrella over every
mechanism that puts an instruction, a procedure, or a hard constraint in front
of the agent: `CLAUDE.md`, rules, skills, subagents, hooks, and the
system-prompt-level styles. They aren't interchangeable. Each differs on three
axes — *when it loads* into context, *how much it costs*, and *how much
authority it carries* (a suggestion the model usually follows versus code the
harness runs no matter what). This document is a plain-language reference for
all of them: what each one is, how it scores on those three axes, and the
single skill that ties the family together — **picking the cheapest mechanism
that still carries the authority the job needs**.

## ELI5

Plain-language one-liners that double as a quick summary of everything this
doc covers. Details are in the sections below; every source link is at the
bottom.

*Tell Claude a standing fact or norm:*

- **`CLAUDE.md`** — things I want you to know the whole time ("we build with
  `make`, tests live in `tests/`"). Costs tokens every turn, so keep it short.
- **rules** — a constraint that only matters for certain files ("every API
  handler validates its input"), loaded only when those files are in play.

*Get Claude to run a procedure the same way each time:*

- **skills** — a saved playbook ("here's exactly how we cut a release") that
  loads only when you reach for it.

*Do side-work without cluttering the conversation:*

- **subagents** — send a helper off to do one scoped task in its own window
  and report back just the answer.

*Make something happen for sure, not just usually:*

- **hooks** — code the harness runs on an event (format after every edit,
  block a dangerous command) — enforcement, not a polite request.

*Change Claude's whole persona or add one-off knowledge:*

- **output styles / `--append-system-prompt`** — rewrite or bolt onto the
  system prompt itself; heavy, and reserved for a real role change.

### Best practices

- **Pick the cheapest mechanism that carries the needed authority.** The whole
  game: don't pay root-`CLAUDE.md` token rent for something a path-scoped rule
  or a hook does better.
- **Standing facts and norms → `CLAUDE.md`** — and keep it under ~200 lines;
  every line is billed every turn.
- **Conditional / file-specific constraints → path-scoped rules** — scope with
  `paths:` so an unrelated area never loads them.
- **Multi-step procedures → skills** — a deploy/release checklist belongs in
  a skill, not as 30 prose lines in `CLAUDE.md`.
- **Isolated or parallel side-work → subagents** — keep deep search, log
  triage, and throwaway intermediates out of the main window.
- **"Always do X" / "never do Y" → a hook, not a sentence.** An instruction
  bends under pressure; a real guardrail has to be deterministic. "The model
  *choosing* to run the formatter" is not "the formatter *runs*."
- **Personal preferences → user/local config, not the project file** — don't
  push your tone into a shared `CLAUDE.md`.
- **Reserve output styles / system-prompt append for a genuine role change** —
  they are expensive and can drop default safety instructions.

## Overview

Every steering mechanism answers the same question — "how do I get Claude to
behave a certain way?" — but at a different price, with different force. The
organizing insight from the source is that a choice among them is really a
choice on three axes at once:

- **When it loads** — at session start (and billed every turn thereafter), or
  lazily, only when something triggers it.
- **Context cost** — how many tokens it occupies in the main window, relevant
  or not.
- **Authority** — whether Claude *may* follow it (an instruction it obeys most
  of the time) or *must* (code the harness executes regardless of the model's
  mood).

**The sentence to remember:** authority and context cost do *not* move
together. A hook has the *highest* authority (it is code, not a suggestion) at
*near-zero* main-context cost, because its config lives outside the window;
root `CLAUDE.md` has only *soft* authority yet the *highest* cost, because it
sits in context every turn. So the goal isn't "use the most powerful tool" —
it is to find the **cheapest mechanism that still carries the authority this
particular constraint needs**. The sections after the table take each
mechanism in turn.

### At a glance

| Mechanism | When it loads | Context cost | Authority | Reach for it when |
|-----------|---------------|--------------|-----------|-------------------|
| **`CLAUDE.md`** (root) | session start; stays all session (re-read after compaction) | **High** — every line billed every turn | Instructional (soft) | a standing fact/norm Claude should hold the whole time |
| **`CLAUDE.md`** (subdirectory) | on demand, when a file under that dir is read | Low — only while that area is active | Instructional (soft) | a convention specific to one code area |
| **Rules** | session start (unscoped) or when matching paths are touched (path-scoped) | **Medium** — always-on unless path-scoped | Instructional (soft) | a file-specific or cross-cutting constraint |
| **Skills** | name + description at start; body only when invoked | Low — body loads on invoke (shared budget) | Procedural (reliable playbook) | a multi-step procedure that must run consistently |
| **Subagents** | name + description + tools at start; body only when called | Low — zero main-context cost; own isolated window | Delegated (runs independently) | isolated or parallel side-work; throwaway intermediates |
| **Hooks** | fire on lifecycle events; config lives outside context | Low — outside the main window; bypasses compaction | **Deterministic (hard)** | something that must happen every time, not "usually" |
| **Output styles / `--append-system-prompt`** | injected into the system prompt (start / at invocation) | **High** — occupies the system prompt | Highest of the context-loaded methods | a real role change or one-off session knowledge |

In table order: **root `CLAUDE.md`** is the always-loaded foundation — soft
authority, highest cost, so it holds only durable facts. Its **subdirectory**
form is the same thing made lazy — loaded only when that area is touched.
**Rules** carry the same soft authority but can be *path-scoped*, trading
always-on cost for load-on-touch — the right home for a constraint that only
applies to some files. **Skills** move a *procedure* out of always-on prose:
the name and description are cheap and ambient, the body arrives only when
invoked. **Subagents** go further and move the work *out of the main window
entirely* — a separate context whose only cost back home is the final summary.
**Hooks** leave context altogether: config on disk, fired by the harness on an
event, executed as code — the only mechanism with true enforcement authority,
and nearly free in tokens. **Output styles** and **`--append-system-prompt`**
sit at the opposite extreme from hooks: maximum context weight in the system
prompt itself, for when the change is a genuine shift in persona or a one-off
knowledge injection rather than a rule or a step.

## `CLAUDE.md` — the always-on foundation

The **root `CLAUDE.md`** loads at session start and stays for the entire
session; it is memoized (read once, cached, and re-read after a compaction),
so it survives long sessions but bills every one of its lines on every turn.
That makes its context cost **high** and independent of relevance — a line
about the deploy process costs the same whether the current task touches
deploys or not. Authority is **instructional**: Claude follows it most of the
time, but it is a suggestion, not a guarantee — the official docs are explicit
that it is *"context, not enforced configuration,"* delivered as a user
message *after* the system prompt rather than as part of it, which is exactly
why a `CLAUDE.md` line can never carry a hook's hard authority [docs-memory].

`CLAUDE.md` resolves across four scopes, concatenated (not overridden) in load
order from broadest to most specific: **managed policy** (org-wide, IT-
deployed), **user** (`~/.claude/CLAUDE.md`, all your projects), **project**
(`./CLAUDE.md` or `./.claude/CLAUDE.md`, team-shared via source control), and
**local** (`./CLAUDE.local.md`, gitignored personal notes). Claude walks up
the directory tree from the working directory, so a file *closer* to where you
launched is read *last* [docs-memory]. Use it for the facts Claude should hold
*all the time* — build commands, directory layout, monorepo structure, coding
conventions, team norms — and keep it short (target under ~200 lines; longer
files consume more context and *reduce* adherence). Two anti-patterns to move
elsewhere: a 30-line procedure (a **skill**) and an "every time X, always Y"
rule (that is a **hook** — see *Hooks*). To split a long file for
*organization* use `@path/to/import` syntax (relative or absolute, recursive
to a maximum of **four hops**, and skipped inside code spans/fences) — but
note imports still load in full at launch, so they aid structure, not context
cost [docs-memory].

The **subdirectory `CLAUDE.md`** is the same mechanism made lazy: it loads
on-demand only when Claude reads a file under that directory, costs nothing
until then, and drops again once that area goes quiet. Reach for it when a
convention is real but *local* — specific to one package or module — so the
rest of the tree never pays for it. One compaction caveat: the project-root
`CLAUDE.md` is re-read from disk and re-injected after a `/compact`, but a
nested subdirectory file is *not* re-injected automatically — it reloads only
the next time Claude reads a file in that directory [docs-memory].

## Rules — scoped, conditional constraints

A **rule** is a topic-scoped Markdown file under `.claude/rules/` and carries
the same soft, instructional authority as `CLAUDE.md`, but with a loading knob
`CLAUDE.md` lacks. Unscoped, a rule loads at session start with the *same
priority as `.claude/CLAUDE.md`* and is re-injected on compaction — **medium**
cost, always on. **Path-scoped** — a `paths:` key in the file's YAML
frontmatter holding glob patterns (`src/api/**/*.ts`, `**/*.{ts,tsx}`) — it
loads only when Claude reads a matching file, dropping its cost to near zero
the rest of the time [docs-memory].

That makes rules the right home for a constraint that is *conditional* — it
binds some files, not the whole session. "All API handlers must validate input
with Zod" is a rule, path-scoped to the handler directory: present when you
edit a handler, absent otherwise. Rules also beat a nest of subdirectory
`CLAUDE.md` files when the *same* concern recurs across several locations —
write it once, scope it to the paths, rather than copy it into each area.
Personal rules live in `~/.claude/rules/` and load *before* project rules, so
project rules win on conflict [docs-memory]. The standing advice: scope
narrow-domain rules with `paths:` so an unrelated task never loads them.

## Skills — procedures on demand

A **skill** is a saved playbook — a multi-step procedure with its decision
points written down in a `SKILL.md` file whose YAML frontmatter carries a
`name` and a `description`. Only that **name and description** load at session
start (cheap and ambient — Claude reads the `description` to decide when to
auto-invoke, and the combined listing text is truncated at 1,536 characters to
bound its cost); the **full body** loads when the skill is invoked, and
invoked skills are re-injected on compaction up to a shared budget with the
oldest dropped first. Context cost is therefore **low**: you pay for the body
only when you actually run the procedure [docs-skills]. Skills follow the
open [Agent Skills][docs-skills] standard and live at three levels —
personal (`~/.claude/skills/`), project (`.claude/skills/`), and plugin — with
a personal skill overriding a project one of the same name, and any of them
overriding a bundled skill; custom `/`-commands are now just skills too.

Authority is **procedural** — a skill's value is that Claude executes the
defined steps *reliably* and the same way each time, which is exactly what an
ad-hoc prose instruction cannot promise. Reach for a skill for deploy or
release checklists, and for any reusable procedure where consistent execution
matters. Do *not* use one for context-heavy facts that must always be
available (that is `CLAUDE.md`), and don't leave a 30-line procedure inline in
`CLAUDE.md` when it should be a skill. This repo's skills are catalogued in
[`SKILLS.md`][skills-doc].

## Subagents — isolated, delegated work

A **subagent** is a helper you hand one scoped task; it runs in its **own
isolated context window** and returns only its final message (a summary plus
metadata) to the main session. It is a Markdown file with YAML frontmatter —
only `name` and `description` are required — living in `.claude/agents/`
(project) or `~/.claude/agents/` (user); `tools` inherits *all* tools when
omitted, and `model` (`sonnet` / `opus` / `haiku` / `fable` / a full ID /
`inherit`) defaults to `inherit` [docs-subagents]. At session start only its
name, description, and tool list load; the body loads only when it is called,
and becomes the subagent's *entire* system prompt (it does **not** inherit
Claude Code's main system prompt) [docs-subagents]. So its cost in the *main*
window is effectively **zero** until invoked, and even then the subagent's
intermediate reasoning never returns home — only the answer does.

Authority is **delegated execution**: the subagent runs independently, on its
own, and reports up. That shape fits work you want *out* of the main
conversation — running tasks in parallel, deep searches, log analysis, and any
side task whose intermediate results you will not reference again and that
would otherwise clutter the main thread. See [`SUBAGENTS.md`][subagents-doc]
for the full treatment.

## Hooks — deterministic enforcement

A **hook** is the odd one out, and the reason the three axes do not move
together. Its config lives *outside* the main context and it fires on a
specific lifecycle event — a file edit, a tool call, session start — so its
context cost is **low** and it **bypasses compaction entirely**. Yet its
authority is the highest of any mechanism here, because a hook is **code the
harness runs**, not text the model may choose to honor.

That is the whole point: *"the model choosing to run a formatter is different
from the formatter running automatically,"* and *"a real guardrail needs to be
deterministic."* Anything that must happen every time — run the linter after
an edit, post to Slack on completion, **block** a dangerous command (a
`PreToolUse` hook exiting **2**) — belongs in a hook, not in an "always do
X" / "never do Y" sentence that bends under pressure. The exit-code contract
is precise: **0** = success (stdout is parsed for JSON control fields), **2**
= blocking error (stderr is fed back to Claude and the action is blocked for
events like `PreToolUse` / `UserPromptSubmit` / `Stop`), any *other* non-zero =
non-blocking error [docs-hooks]. Hooks are wired in `settings.json` under a
`hooks` key — an event name (`PreToolUse`, `PostToolUse`, `SessionStart`, …),
an optional `matcher` (tool name, list, or regex), and a `command`
[docs-hooks]. Those settings themselves resolve across scopes — managed
(highest) > command-line args > local > project > user — so organization-wide,
managed settings make such guardrails non-bypassable [docs-settings]. The
events, the `settings.json` structure and the exit-code contract are their own
topic — see [`HOOKS.md`][hooks-doc].

## Output styles and `--append-system-prompt`

These two sit at the far end from hooks: they change the **system prompt
itself**, so their context cost is **high** and their authority is the highest
among the context-loaded methods (a system-prompt instruction outranks an
ordinary one). They differ mainly in persistence.

- **Output styles** are injected into the system prompt at session start and
  are never compacted. A custom style is a Markdown file (frontmatter `name` /
  `description`, then instructions) at `~/.claude/output-styles` or
  `.claude/output-styles`, selected via `/config` — which writes the
  `outputStyle` field to `.claude/settings.local.json` (the standalone
  `/output-style` command was removed) [docs-styles]. Use them only for a
  *significant role change* — turning the coding assistant into a general
  assistant, say — and only when the built-in styles (Default plus Proactive,
  Explanatory, Learning) do not fit. The risk is real: a custom style
  *drops* Claude Code's built-in software-engineering instructions — including
  safety and security guidance — unless you set `keep-coding-instructions:
  true` in the frontmatter [docs-styles].
- **`--append-system-prompt`** is passed at invocation and applies only to
  *that* run — never compacted, never persisted. It *augments* the default
  role rather than displacing it (the memory docs recommend it for
  system-prompt-level instructions that a rule or `CLAUDE.md` line can't carry
  [docs-memory]), so it is the lighter-touch choice for one-off session
  knowledge, a domain standard, or a tone preference that should not stick
  around. Prompt caching softens its cost after the first request. It is the
  usual companion to headless runs (`claude -p`) — see
  [`HEADLESS.md`][headless-doc] and the [headless reference][docs-headless].

## Bringing it together — pick the cheapest tool for the job

Every section above is one point on the cost/authority plane; steering well is
routing each need to its cheapest sufficient point. Walk the decision in this
order — stop at the first match:

1. **Does it have to happen deterministically** — enforced, not merely
   requested (block a command, always format, always notify)? → **hook**. It's
   the only mechanism with true enforcement, and it is nearly free in tokens.
   An "always/never" line in `CLAUDE.md` is the classic mis-route here.
2. **Is it a multi-step procedure** run the same way each time (deploy,
   release, a scaffold)? → **skill**. Cheap until invoked; do not inline it in
   `CLAUDE.md`.
3. **Is it isolated or parallel side-work** whose intermediates you will not
   reuse (search, log triage, a throwaway investigation)? → **subagent**. Its
   own window; only the summary comes back.
4. **Is it a constraint that binds only some files** ("handlers validate
   input")? → **path-scoped rule**. Present when those files are, absent
   otherwise.
5. **Is it a standing fact or norm** Claude needs the whole time (build
   command, layout, conventions)? → **`CLAUDE.md`** — root if global to the
   repo, subdirectory if local to one area. Keep it short.
6. **Is it a genuine change of persona, or one-off session knowledge** that no
   rule or skill captures? → **output style** (persistent role change) or
   **`--append-system-prompt`** (single invocation). These are the expensive
   last resort, not the default.

The recurring failure is reaching *up* the ladder — writing a guardrail as
a `CLAUDE.md` line (soft authority, high cost) when a hook would enforce it
for free, or inlining a procedure as prose when a skill would load it only on
demand. Reach for the lowest rung that still holds.

**This repo already lives this model.** The dotfiles config maps almost
one-to-one onto the blog's mechanisms — `CLAUDE.md` for always-on norms,
`rules/*.md` for conditional/tool-scoped constraints, `skills/*` for
procedures, and `hooks/*` for deterministic enforcement — and its
*Configuration Migration* three-tier model (generic → language → repo) is the
placement discipline layered on top: not just *which* mechanism, but at *which
scope* it belongs. Rather than restate it, see the [three-tier model in
`CLAUDE.md`][claude-md] and the language-and-tool-stack layering in
[`EXTENDING.md`][extending].

## See also — adjacent, out of scope

The mechanisms here each get their own deeper reference; this doc is the map
over them, not a substitute:

- **Hooks** — the events, `settings.json` wiring, and exit-code rules behind
  the deterministic-enforcement row. See [`HOOKS.md`][hooks-doc].
- **Skills** — authoring and cataloguing the procedural playbooks. See
  [`SKILLS.md`][skills-doc].
- **Subagents** — the isolated-delegation mechanism in full. See
  [`SUBAGENTS.md`][subagents-doc].
- **Permission modes & auto mode** — a *different* control surface: not what
  instruction loads, but which actions run without a prompt. A hook composes
  with it; the resolution order lives there. See [Permission Modes & Auto
  Mode][perm-doc].

## Resources

Distilled from the "Steering Claude Code" blog post and the official Claude
Code documentation:

- [Steering Claude Code][blog] — the source blog post
- [memory][docs-memory] — `CLAUDE.md` files and precedence
- [skills][docs-skills] — Agent Skills
- [sub-agents][docs-subagents] — subagents
- [hooks][docs-hooks] — hooks
- [output-styles][docs-styles] — output styles
- [headless][docs-headless] — `claude -p` and `--append-system-prompt`
- [settings][docs-settings] — where config and managed settings live

[blog]: https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more
[docs-memory]: https://code.claude.com/docs/en/memory
[docs-skills]: https://code.claude.com/docs/en/skills
[docs-subagents]: https://code.claude.com/docs/en/sub-agents
[docs-hooks]: https://code.claude.com/docs/en/hooks
[docs-styles]: https://code.claude.com/docs/en/output-styles
[docs-headless]: https://code.claude.com/docs/en/headless
[docs-settings]: https://code.claude.com/docs/en/settings
[hooks-doc]: HOOKS.md
[skills-doc]: SKILLS.md
[subagents-doc]: SUBAGENTS.md
[perm-doc]: PERMISSION-MODES.md
[headless-doc]: HEADLESS.md
[claude-md]: ../CLAUDE.md
[extending]: ../EXTENDING.md
