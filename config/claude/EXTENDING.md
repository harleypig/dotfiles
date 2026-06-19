# Claude Code Extension Primitives

**Version:** v1.0.0

A reference for the building blocks used to customize Claude Code — what
each one is and when to reach for it. They are **not** interchangeable;
each sits at a different layer (passive context vs. active procedure vs.
delegated worker vs. deterministic harness action).

This is a global reference (it deploys to `~/.claude/`). It describes
Claude Code itself, not any one repo.

## At a glance

| Primitive | What it is | Active? | Runs where | Reach |
|-----------|-----------|---------|------------|-------|
| Memory / `CLAUDE.md` | Always-loaded instructions | Passive | — | Every turn |
| Rule | Scoped standing policy/reference | Passive | — | Relevant turns |
| Skill | A procedure the model invokes | Active | My context | One task, inline |
| Agent (subagent) | A delegated worker | Active | Its own context | Isolated/parallel task |
| Hook | A shell command on a lifecycle event | Active | The harness (not the model) | Deterministic enforcement |
| Command (slash) | A named, user-triggered prompt/action | Active | My context | On demand |
| MCP server | External tools/data over MCP | Active | External process/endpoint | Tools a CLI lacks |
| Plugin | A bundle of the above | — | — | Packaging / distribution |

## Grounding & sourcing (author from docs, not memory)

Before authoring **any** primitive below — and when editing one — two
requirements:

1. **Check it doesn't already exist.** Search `config/claude/` (and the
   built-in skills/commands) for a rule/skill/hook that already covers this.
   Authoring a duplicate on the false premise that none existed is a real
   past failure mode.
2. **Ground the content in authoritative sources where they exist** — the
   tool/library/API's **official documentation**, its **man page**
   (`man <tool>`, `<tool> --help`), or **local package docs**
   (`/usr/share/doc/<pkg>`) — **not memory**, which goes stale. (Context7, if
   enabled, is a convenience for the currency check — second-class, never
   required; see `rules/mcp.md`.) Where the artifact encodes a **house
   convention** with no external source, say so explicitly.

**Cite what you grounded in**, so it is auditable and re-checkable later:

- **Rules** — a brief **Sources** section (the official doc / man page the
  rule is built on); `rule-TEMPLATE.md` carries the slot.
- **Skills** — a **`SOURCE.md`** in the skill dir when it adapts or reuses
  external material (ADR-0002).

`/claude-audit` checks for this grounding and flags artifacts that lack it
(no source and not a stated house convention) — so a gap here is caught at the
next audit, not silently carried.

## Memory / `CLAUDE.md` (the foundation)

**What:** User-written instructions the harness loads every session (user,
project, and repo scope). Everything else builds on top of it.
**When:** Stable, always-relevant context — who you are, project goals,
hard conventions you want present in *every* turn.

## Rule

**What:** A scoped, standing policy or reference — here, the versioned
files under `config/claude/rules/` (= `~/.claude/rules/`), pulled in
through the memory/`CLAUDE.md` layer (optionally path-scoped via
frontmatter so a rule attaches only for relevant files). It is a
memory-organization **convention**, *not* a Claude-native auto-loading
engine and *not* a plugin component. (Cursor, by contrast, has a native,
glob-auto-discovered Rules feature; Claude keeps standing policy in the
memory layer instead — which is why a plugin can't ship a rule.)
**When:** "How we always do X" — naming, tool invocation/flags, error
posture, workflow policy. Passive guidance the model should follow, not a
procedure it runs. Reach for a rule when the knowledge is judgment-shaped
and should quietly shape behavior.

## Skill

**What:** A packaged procedure the model invokes and follows inline — a
`SKILL.md` of instructions plus optional scripts/resources. Runs in the
current context; no separate process.
**When:** A repeatable multi-step task (three or more steps, with
decisions or branches) you want done consistently — e.g. `ship-pr`,
`qa-check`, `bats-setup`. Reach for a skill when you'd write the procedure
up for a new contributor.
**Authoring:** when creating or iterating a skill, use the **skill-creator**
skill — draft it, run its evals/benchmarks on test prompts, and run its
description-trigger optimizer so the skill fires on the right requests, not
just whatever wording was first guessed. We are deliberately exercising
skill-creator on every new skill to learn its worth
(`audit/decisions-log.md`).
**Format:** our `SKILL.md` *is* the **Agent Skills open standard**
([agentskills.io](https://agentskills.io/specification)) — the format
Anthropic created and released as a cross-vendor open standard (Dec 2025). A
skill is a directory whose name matches its `SKILL.md`'s required `name`
(1–64 chars, lowercase/digits/hyphens, no leading/trailing or consecutive
hyphen) plus a required `description` (≤1024 chars: what it does *and* when to
use it), then the Markdown body and optional `scripts/` / `references/` /
`assets/`. Optional standard fields (`license`, `compatibility`, `metadata`,
`allowed-tools`) are **skipped by default** for these internal skills — add
one only when it earns its place (e.g. a vendored skill keeping its upstream
`license`). Conformance is guarded by
`tests/shell/test_skill_frontmatter.bats` — a self-hosted check of the
required-field rules above, run in the gating suite. The standard's external
`skills-ref` validator is **ICEBOXed** (noted in that test) in favour of the
self-hosted check, matching the repo's no-external-tool-to-lint-our-own-files
posture.

## Agent (subagent)

**What:** A separate Claude instance spawned via the Task/Agent tool, with
its own fresh context window, its own system prompt, and a restricted tool
set. It runs autonomously and returns only its result to the main loop.
**When:** Fan-out / parallel work, or context isolation — a focused
sub-task whose intermediate reading and output you don't want filling your
main context (broad searches, a self-contained review). Use it when you'd
hand the job to a teammate and just want the conclusion.

## Hook

**What:** A shell command the harness runs on a lifecycle event
(`PreToolUse`, `PostToolUse`, …), configured in `settings.json`. It fires
deterministically — the model does not decide whether to.
**When:** Enforcement that must not depend on the model remembering —
auto-format on edit, block a disallowed action, inject context on an
event. The `rule-coverage.py` `PostToolUse` hook is an example (nags when
a language/dependency has no matching rule).

## Command (slash command)

**What:** A named, user-triggered prompt or action (e.g. `/commit`,
`/qa`), defined under `commands/` and shippable in plugins. Typing it
expands to its prompt/instruction.
**When:** A canned action you want to fire by name on demand. Lighter than
a skill — a shortcut/prompt rather than a full procedure (though skills can
also be slash-invoked).

## MCP server

**What:** An external process or endpoint that provides tools and/or data
to the model over the Model Context Protocol. Registered by scope
(local/project/user) or bundled in a plugin.
**When:** To give the model capabilities a CLI can't, or a deliberately
restricted capability boundary. Treat as **second-class** — never depend
on one in a rule or skill (see `rules/mcp.md`).

## Plugin

**What:** An installable bundle (from a marketplace) that packages one or
more **commands, skills, agents, hooks, and/or MCP servers** — the
distribution/sharing unit. It can **not** carry rules; standing policy
lives in the memory layer, not in a shipped package.
**When:** To install someone else's capability set, or to package and
share your own. A plugin is a *container*, not a new kind of capability.

## Choosing between them

Decision shortcuts:

- Must happen every time, regardless of whether the model remembers →
  **Hook** (deterministic).
- Standing policy/knowledge that should shape behavior → **Rule** (or
  `CLAUDE.md` for always-on).
- A repeatable multi-step procedure with decisions → **Skill**.
- Work you want done in isolation or in parallel (keep big output out of
  the main thread) → **Agent**.
- A canned action you trigger by name → **Command**.
- Tools/data a CLI can't give the model → **MCP server** (second-class).
- Packaging several of these to install/share → **Plugin**.

Key contrasts:

- **Rule vs Skill** — a rule is *passive policy* ("always do X this way");
  a skill is an *active procedure* you invoke ("the steps to do X"). Both
  run in my context.
- **Skill vs Agent** — a skill runs in *my* context (I follow its steps);
  an agent runs in its *own* context and returns only a result. Use an
  agent for parallel fan-out or to keep heavy intermediate work out of the
  main thread.
- **Rule vs Hook** — a rule relies on the model choosing to follow it; a
  hook is enforced by the harness no matter what. Use a hook when "must,
  every time" (format-on-edit, block-on-condition); a rule when judgment
  is involved.
- **An agent is never a substitute for a rule** — they answer different
  questions: a rule *encodes policy*; an agent *executes a task*.

Worked examples:

- **Git workflow** → rules (branch naming, branch protection, staging
  discipline) **plus** a skill (`git-worktree-workflow`'s multi-step
  procedure). *Not* an agent: it is deterministic, touches your working
  tree, and you want its state visible in your own context — delegating it
  to an isolated worker would hide exactly what you need to see.
- **qa-check** → a skill (it orchestrates the pipeline from the repo's QA
  doc). Agents fit *underneath or around* it, not instead of it: the skill
  can *spawn* agents to run independent QA dimensions in parallel, and you
  can *invoke* qa-check via an agent to keep its verbose lint/test output
  out of your main context. Skill and agent compose — they are not an
  either/or.

### Placement: global + lazy beats per-repo copies

Once you've picked the *kind* of artifact, decide *where* it lives. DRY and
context-economy pull the same way:

1. **Global + lazy (preferred).** One copy that loads only when needed: a
   path-scoped rule (`paths:` frontmatter), an on-demand skill / agent /
   command, or an MCP server with tool-search deferral. It works across every
   repo at ~zero idle cost — e.g. the React rule lives once globally but loads
   only on `*.tsx`, in any repo that has them.
2. **Per-repo (fallback).** Only when global+lazy is not achievable —
   typically a heavy MCP server wanted in just one or two repos, because
   plugin enablement is global-only and an enabled MCP plugin is always-on.
   The **definition stays centralized** even for a single-repo server: define
   the MCP server once in `mymcp`, then turn it on per-repo with a thin
   local-scope switch (`claude mcp add <name> -- mymcp <name>`). Only a
   non-MCP feature that genuinely can't be made global+lazy gets vendored into
   the repo itself.

Avoid duplicating a capability across repos: copies drift and are
error-prone, even with an agent maintaining them. Keep it global wherever it
can be made to load lazily.

### Layer the generic over the specific

A capability that is *mostly* generic but carries language- or
framework-specific details (an API-doc generator, a test scaffolder, a
"clean-code" reviewer) should be built in **two layers** — never as one
artifact with a single stack's specifics baked in:

1. **A thin, stack-agnostic layer** describing *what* to do in terms true for
   every language — qa-check's "format, then lint, then type-check"; an
   api-documenter's "extract the public surface, document each symbol, show
   usage." It carries no Python/Go/TS-only assumptions.
2. **The stack-specific pattern it points to** — the concrete *how*, kept in a
   path-scoped rule or an on-demand skill that loads only on that stack
   (`fastapi-patterns` on `**/*.py`; a hypothetical `godoc-patterns` on
   `**/*.go`). The thin layer **delegates** here instead of hard-coding it.

Why: one language's specifics inside a generic artifact **mislead every other
repo**. An `api-documenter` that quietly assumes docstrings and type hints is
confusing — even wrong — in a Go-only repo like packwiz. Splitting the layers
keeps the generic part reusable everywhere and the specifics correct only
where they apply. This is the three-tier *Configuration Migration* model (in
`CLAUDE.md`) applied **inside** one capability — and exactly why `qa.md` is
tool-agnostic and the `fastapi.md` rule points to the `fastapi-patterns`
skill.

**When mining other repos for ideas** (the audit's *Idea sources*): a borrowed
item that fuses generic intent with one stack's specifics — like
`claude-tools`'s `api-documenter` agent — should be **split, not vendored
whole**. Lift the generic intent into a thin rule/skill, and re-home (or newly
write) the stack-specific half as a path-scoped pattern. Often the right form
is *not* the original's — adopt the idea, then choose the kind (rule/skill)
that fits, rather than copying the agent verbatim.

### Foreign to the repo → global, and front-loaded

Guidance about anything **foreign to the current repo** — a third-party
library / framework / tool, **or our own code that lives in a *different*
repo** — belongs in the **global generic layer** (a global skill or
path-scoped rule), **even if only this one repo uses it today**. "Foreign to
this repo" means "shared by nature": it already exists outside this repo and
*will* recur in another one. So author the full global artifact the **first**
time you need it, while already in context — not a repo-local half-job you
have to remember to generalize later. Front-load the grunt work; you are
spending it anyway. (ADR-0003.)

Repo-local `.claude/` is therefore reserved for *this repo's own* code,
architecture, and quirks — never for an external dependency.

This is **not** a violation of the Rule of Three (`code-style.md`), which
guards against speculatively abstracting *your own* code before the pattern is
proven. An external library is not speculative — it is already stable, and
"foreign to this repo" *is* the signal that the third instance is effectively
guaranteed. So:

- **Our own repo-specific pattern** → repo-local; wait for the third instance
  before abstracting.
- **A library/tool foreign to the repo** → global immediately, on first use.

The build/skip decision is still "do we use it at all" — but *when* we do
build, the placement is global, and the timing is now.
