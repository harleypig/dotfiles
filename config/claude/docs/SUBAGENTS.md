# Claude Code Subagents

A **subagent** is an isolated Claude instance with its own context window: it
takes one scoped task, does the work in its own thread, and returns *only* a
summary — the synthesized answer, not the dozens of files it read to get
there. That isolation is the whole point. It keeps a research detour, a
parallel edit, or an unbiased review out of your main conversation, so your
context stays lean and the side task starts from a clean slate. This document
is a plain-language reference for **delegation**: what a subagent is, the
built-in types, when delegating pays off and when it doesn't, the five ways to
direct one, the everyday patterns, and how to pick each subagent's model tier
and effort.

## ELI5

Plain-language one-liners that double as a quick summary of everything this
doc covers. Details are in the sections below; every source link is at the
bottom.

*Hand off a side task:*

- **a subagent** — send a helper off to do one job and report back just the
  answer, not the pile of files it read.
- **general-purpose agent** — the do-anything helper for a multi-step job that
  needs lots of tools.
- **explore agent** — a fast read-only scout: "go find where X lives across
  the codebase."
- **plan agent** — a read-only researcher that comes back with a strategy, not
  edits.

*Make delegation automatic / reusable:*

- **custom agent type** (`.claude/agents/*.md`) — a named, pre-scoped helper
  Claude reaches for on its own when a task matches.
- **CLAUDE.md policy** — a standing rule ("always review with a read-only
  subagent") read at the start of every session.
- **from a skill** — a saved procedure that spins up subagents as one of its
  steps (e.g. three parallel reviews).
- **from a hook** — a lifecycle gate that fires a check automatically (e.g.
  block finishing until tests pass).

*Tell it apart from the neighbors:* subagents **report up** to you and never
talk to each other. When helpers must coordinate *among themselves*, that's
**agent teams**; when a *script* drives the fan-out, that's a **workflow** —
both live in [Loops & Workflows][loops].

### Best practices

- **Delegate to keep the answer, not the files** — the win is a synthesized
  summary landing in your context instead of twenty raw files.
- **Start conversational, automate later** — begin by asking in plain
  language; only once a request recurs, promote it to a custom agent, a
  CLAUDE.md rule, a skill, or a hook.
- **Keep the roster lean** — a handful of well-scoped agents beats a drawer
  full of specialists; flooding Claude with options makes auto-delegation
  *less* reliable.
- **Scope the task and say what to return** — "summarize each, not the full
  file contents" is the difference between a useful report and a context
  dump.
- **Ask for a fresh, read-only agent when you want an unbiased review** — it
  doesn't inherit the assumptions or blind spots of your main thread.
- **Don't parallelize edits to the same file** — two subagents writing one
  file collide; partition by file or serialize.
- **Right-size model tier and effort per subagent** — a cheap fast model for a
  search scout, a stronger one for a security review (see *Bringing it
  together*).

## Overview

A subagent trades a little **delegation overhead** for two things you can't
get in the main thread: **context isolation** (its reads and reasoning don't
weigh down your session) and a **clean slate** (it starts fresh, free of the
main conversation's assumptions). Long sessions accumulate weight — every file
read and every tangent stays in the window, slowing responses and driving up
cost; a subagent quarantines that side work and hands back only the result.

**The one distinction to remember:** a subagent **reports up and never
sideways**. It returns its findings to *you*; it cannot message another
subagent. That single fact draws every boundary in this doc — it's why
subagents suit fan-out and review (independent tasks reporting back) but *not*
work where the helpers must talk to each other (that's agent teams), and why a
*script*, not the agents themselves, coordinates a workflow's fan-out.

### At a glance — the built-in subagent types

Three types ship built in, distinguished by **what tools they can touch** and
**whether they change anything**. Everything else is these three (or a custom
type built on the same idea).

| Type | Tools / scope | Reach for it when |
|------|---------------|-------------------|
| **general-purpose** | full tool access; multi-step | a complex task needs many tools and several steps of real work |
| **plan** | read-only; researches, then proposes | you want a strategy or implementation plan *before* any edits |
| **explore** | read-only, fast code search; reads excerpts | you need to locate code across many files quickly, not review it |

In table order: **general-purpose** is the do-anything worker for a
multi-step job — reads, edits, runs commands — and is the default when no more
specific type fits. **plan** researches the codebase read-only and comes back
with an implementation strategy, changing nothing. **explore** is the fast
read-only scout: it sweeps many files and locates code, reading excerpts
rather than whole files, so it *finds* things but doesn't audit them. All
three start fresh with no conversation history, **inherit the main
conversation's model** (Explore is capped at Opus), and several can run at
once — the [subagents reference][docs-subagents] covers the built-ins in full.
(This harness also exposes a catch-all `claude` type for anything that fits no
named agent, plus whatever custom types the repo defines — see *Directing a
subagent*.)

## When to delegate — and when not to

Delegation is a judgment call, and the two lists below are the spine of it:
the shapes of work a subagent makes *faster and cleaner*, versus the shapes it
makes *slower and messier*. The rough threshold from [the blog][blog]: **when
a task means exploring ten or more files, or involves three or more
independent pieces of work, reach for subagents.**

### When a subagent pays off

- **Research-heavy fan-out** — gathering context means reading dozens of
  files. Send scouts and get **synthesized findings** back instead of raw
  content. *E.g.* before building a feature, explore the auth patterns,
  existing notification logic, and where the new code should live — in
  parallel.
- **Multiple independent tasks** — sub-tasks with no dependencies between them
  run **in parallel** and finish in roughly the time one would. *E.g.* update
  error handling across three separate files at once.
- **A fresh perspective** — verification that shouldn't be colored by the main
  thread's history. A subagent is a **clean slate**: no inherited assumptions
  or blind spots. (Distinct from `/clear`, which resets *everything* and loses
  your history — a subagent leaves your session intact.)
- **Verification before committing** — a second opinion that catches what
  familiarity hides, without you re-reading your own reasoning.
- **Pipeline stages** — sequential phases with clean handoffs (design →
  implement → test), where each stage should focus *without* noise from the
  others' context.

### When to keep it in the main thread

- **Sequential, dependent work** — step two needs the full output of step one.
  Chaining that through delegation just adds handoff friction; keep it in one
  session.
- **Parallel edits to the *same* file** — multiple subagents writing one file
  conflict. Partition the work by file, or do it serially.
- **Small tasks** — a quick fix or a focused question. The overhead of
  spinning up and summarizing outweighs any benefit.
- **Over-engineered specialist rosters** — a custom agent for every niche
  makes auto-delegation *less* reliable, not more. Most teams settle on a few
  well-scoped agents; add one only when a real pattern recurs.
- **Work that needs the agents to coordinate** — subagents report up, never to
  each other. If helpers must exchange state mid-flight, that's **agent
  teams**, not subagents. See [agent-teams][docs-teams].

## Directing a subagent — five ways

The same isolation mechanism can be invoked five ways, escalating from
one-off to fully automatic. The guiding rule is *start conversational,
automate later*: reach down this list only when a request has proven it
recurs.

### 1. Conversational — just ask

Plain language reliably triggers delegation. Name the shape you want:
*"Use a subagent to explore how authentication works,"* *"Have a separate
agent review this for security issues,"* *"Research this in parallel — check
the API routes, database models, and frontend components simultaneously."* An
effective prompt does three things: **scope each task**, **request
parallelism explicitly**, and **specify what to return**.

```text
Use subagents to explore this codebase in parallel:

1. Find all API endpoints and summarize their purposes
2. Identify the database schema and relationships
3. Map out the authentication flow

Return a summary of each, not the full file contents.
```

A running subagent can be sent to the background (Ctrl+B) and checked with
`/tasks` — see [Observability][obs]. Claude backgrounds subagents by default
now, so they run concurrently and surface any permission prompt back in your
main session, keeping one in the foreground only when it needs the result to
continue (the [subagents reference][docs-subagents] has the details).

### 2. Custom agent types — pre-scoped specialists

Save a named subagent as a **markdown file with YAML frontmatter** in
`.claude/agents/` (project, shared with the team) or `~/.claude/agents/`
(user, across all projects); ask Claude to write one or create the file by
hand — the `/agents` command points you to the right directory. When two
scopes define the same `name`, the higher-priority one wins: managed
settings, then a `--agents` CLI flag, then project, then user, then a
plugin's `agents/`. Only `name` and `description` are required; `tools`
inherits every tool from the main conversation when omitted, and `model`
takes `sonnet`, `opus`, `haiku`, `fable`, a full model ID, or `inherit` (the
default — the main conversation's model). The body after the frontmatter
becomes the subagent's system prompt, and the [subagents
reference][docs-subagents] documents every field:

```yaml
---
name: security-reviewer
description: Reviews code changes for security vulnerabilities,
  injection risks, auth issues, and sensitive data exposure.
  Use proactively before commits touching auth, payments, or user data.
tools: Read, Grep, Glob
model: sonnet
---

You are a security-focused code reviewer. Analyze the provided
changes for injection risks, auth gaps, and sensitive data in logs
or responses. Return a prioritized list with file:line references
and a recommended fix for each.
```

The **`description` is what makes auto-delegation work** — write it about
*when to trigger*, not just capability. *"Reviews code for security issues
before commits"* routes far better than *"security expert."* Reach for a
custom type when a specialist should be automatically available for matching
work, benefits from restricted tools, or should be shared across a team. Once
saved, Claude **delegates automatically** when a task matches the
`description`; you can also invoke it explicitly — name it in a prompt,
`@agent-<name>` it, or run a whole session as it with `claude --agent <name>`.

### 3. CLAUDE.md policy — a standing rule

CLAUDE.md is read at the start of every conversation, so a rule there makes
delegation behavior consistent across sessions and teammates with no manual
ask. Use it for always-on policy: *code reviews always run in a read-only
subagent*, *research always follows this pattern*.

```markdown
## Code review standards

When asked to review code, ALWAYS use a subagent with READ-ONLY access
(Glob, Grep, Read only). The review should ALWAYS check for security
vulnerabilities, performance issues, and adherence to the patterns in
/docs/architecture.md. Return findings as a prioritized list with
file:line references.
```

See [CLAUDE.md memory docs][docs-memory].

### 4. From a skill — delegation inside a procedure

A skill (a `SKILL.md` under `.claude/skills/`) packages a multi-step workflow,
and one of its steps can fan out to subagents. This is how you standardize a
complex operation — the same fan-out every time, for everyone.

```markdown
---
name: deep-review
description: Comprehensive code review that checks security,
  performance, and style in parallel. Use when reviewing staged
  changes before a commit or PR.
---

Run three parallel subagent reviews on the staged changes:
1. Security — vulnerabilities, injection, auth, sensitive-data exposure
2. Performance — N+1 queries, needless iteration, leaks, blocking calls
3. Style — consistency with /docs/style-guide.md

Synthesize the findings into one priority-ranked summary.
```

See [skills docs][docs-skills].

### 5. From a hook — automatic on a lifecycle event

A hook fires a shell command, HTTP call, or LLM prompt at a lifecycle point,
so a check runs without anyone asking. A `Stop` hook, for instance, can block
Claude from ending its turn until tests pass — a local CI-style gate. The hook
returns `{"decision": "block", "reason": "..."}` and Claude keeps working; a
`stop_hook_active` guard prevents an infinite loop. See the [hooks
docs][docs-hooks] and the [Hooks][hooks] reference.

## Practical patterns

Four everyday shapes, each a direct application of the *when to delegate*
list. All four share one instruction: *say what to return*.

### Research before implementing

Delegate the reading so the implementation discussion starts from a
synthesized summary, not twenty open files.

```text
Before I implement user notifications, use a subagent to research:
how emails are sent today, what notification patterns already exist,
and where new notification logic should live. Summarize findings,
then we'll plan together.
```

### Parallel independent edits

One subagent per file, all at once — finishing in roughly the time one would
take, each keeping its own focus. The hard rule: the files must be
**disjoint** (no two agents touch the same one).

```text
Use parallel subagents to update error handling in src/api/users.ts,
src/api/orders.ts, and src/api/products.ts. Each should follow the
pattern in src/api/auth.ts. Work on all three simultaneously.
```

### Independent review

A fresh read-only agent that *doesn't* see the prior discussion evaluates the
code without knowing which tradeoffs you already made or rejected — so it
surfaces issues from the outside.

```text
Use a fresh subagent with read-only access to review my payment-flow
implementation. It should not see our previous discussion — I want an
unbiased review. Check for security holes, unhandled edge cases, and
error-handling gaps. Be critical.
```

### Pipelines

Sequential stages with **files as the handoff**, each stage a focused subagent
that isn't distracted by the others' concerns.

```text
Build this as a pipeline:
1. First subagent: design the API contract → docs/api-spec.md
2. Second subagent: implement the endpoints from that spec
3. Third subagent: write integration tests for the implementation
Each stage finishes before the next; use the files as the handoff.
```

## Bringing it together — model tier and effort per subagent

Because each subagent runs in isolation, each can run on its **own model
tier** and **own reasoning effort** — matching those to the job is where
delegation earns real savings, not just cleaner context. A custom agent's
frontmatter carries a `model:` — `sonnet`, `opus`, `haiku`, `fable`, a full
model ID, or `inherit` (the default) — plus an optional `effort:` field
(`low` … `max`) that overrides the session's effort while it runs; an `Agent`
call can override the model per launch, resolved ahead of the frontmatter (the
[subagents reference][docs-subagents] gives the full order). Match them to the
task's weight:

- A read-only **explore** scout or a mechanical fan-out edit → a **cheaper,
  faster** tier at **lower** effort; it's finding or applying, not deciding.
- A **security review**, an architecture **plan**, or a subtle refactor → a
  **stronger** tier at **higher** effort; the judgment is the deliverable.

Getting this right across a fan-out of a dozen agents is a real cost lever —
but the *how* (which tier for which shape of task, how effort trades against
latency and spend, the concrete assignment guidance) is its own topic. This
doc names the knob; **[Models & Effort][models]** is the reference for
choosing its setting per subagent, and is the home for the effort-level /
model-tier assignment guidance the backlog's "Sub-agents" topic calls for.

## See also — adjacent, out of scope

Subagents are one lever among several for steering how work gets done; these
neighbors handle the parts this doc deliberately leaves out:

- **Steering (umbrella)** — the full set of levers for directing Claude, of
  which delegation is one. See [Steering][steer].
- **Models & Effort** — picking a model tier and reasoning effort, per
  subagent and in general. See [Models & Effort][models].
- **Loops & Workflows** — the *breadth* neighbors: a **workflow** is a
  **script** that drives a scripted fan-out (control flow in code, results in
  script variables), whereas subagents **report up** to you; **agent teams**
  coordinate peer-to-peer. See [Loops & Workflows][loops].
- **Observability** — watching delegated work once it's running (`/tasks`,
  backgrounded agents, cost). See [Observability][obs].

## Resources

Distilled from the "Subagents in Claude Code" blog post and the official
Claude Code documentation:

- [Subagents in Claude Code][blog] — the source blog post
- [sub-agents][docs-subagents] — the subagents reference
- [agent-teams][docs-teams] — peer-coordinating agents (vs report-up ones)
- [memory / CLAUDE.md][docs-memory] — standing delegation policy
- [skills][docs-skills] — subagents inside a saved procedure
- [hooks][docs-hooks] — automatic delegation on a lifecycle event
- [Steering][steer] — the umbrella of steering levers
- [Models & Effort][models] — model-tier and effort assignment
- [Loops & Workflows][loops] — scripted fan-out and agent teams
- [Observability][obs] — watching delegated work
- [Hooks][hooks] — the hooks reference

[blog]: https://claude.com/blog/subagents-in-claude-code
[docs-subagents]: https://code.claude.com/docs/en/sub-agents
[docs-teams]: https://code.claude.com/docs/en/agent-teams
[docs-memory]: https://code.claude.com/docs/en/memory#claude-md-files
[docs-skills]: https://code.claude.com/docs/en/skills#extend-claude-with-skills
[docs-hooks]: https://code.claude.com/docs/en/hooks
[steer]: STEERING.md
[models]: MODELS-AND-EFFORT.md
[loops]: LOOPS-WORKFLOWS.md
[obs]: OBSERVABILITY.md
[hooks]: HOOKS.md
