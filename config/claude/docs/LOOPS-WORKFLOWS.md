# Claude Code Loops & Workflows

Claude Code can do more than answer one prompt at a time. A **loop** keeps a
task going *over time* — repeating, waiting, or retrying until a stop
condition is met. A **workflow** spreads a single task *across many agents*
working at once. This document is a plain-language reference for both
families: the underlying concepts, how each command and mode behaves, how
they compose, and when to reach for which — plus the adjacent pieces for
running work unattended, watching it, and driving it from scripts.

## ELI5

Plain-language one-liners that double as a quick summary of everything this
doc covers. Details are in the sections below; every source link is at the
bottom.

*Make Claude repeat / keep going:*

- **`/loop`** — do this again every so often until I stop you ("check my PR
  every 5 minutes").
- **`/goal`** — keep trying until you hit this target or run out of tries.
- **`/schedule`** — run this on a timer (or a GitHub event) in the cloud,
  even with my laptop off.
- **`/background`** — take this whole session off my screen and keep going;
  I'll check back.
- **a background job** — run one command off to the side and ping me when
  it's done.

*Make many Claudes work at once:*

- **a workflow** — a script that spins up many helper agents to chew through
  lots of things in parallel.
- **subagents** — send a helper to do one side task and report back.
- **agent teams** *(experimental)* — several Claude sessions that message
  each other and split the work (all for one human user).
- **`/batch`** — a ready-made "big change" helper: split a job into pieces,
  one agent per piece, each opening its own PR.

*Let it run without babysitting:*

- **auto mode / permission modes** — pre-approve the safe stuff so it doesn't
  stop to ask.

*Watch what's running:*

- **`/tasks`** (all background work), **`/workflows`** (workflow progress +
  cost), **`claude agents`** (detached sessions), **`/usage`** (spend).

*Drive it from a script / CI:*

- **`claude -p`** (headless) with **`--resume`** / **`--continue`**.

A *different*, event-driven family (react to events instead of repeating) is
out of scope here — see [hooks][docs-hooks] and [channels][docs-channels].

### Best practices

- **Define explicit stop/success criteria and turn caps** — vague goals
  burn tokens.
- **Match the interval to how often things actually change** — don't poll
  every 5 minutes for hourly work.
- **Use scripts for deterministic steps**; reserve reasoning for judgment.
- **Add a verification step** — e.g. a second agent running `/code-review`
  — so the loop self-checks before finishing.
- **Keep the codebase clean and documented** — Claude mirrors existing
  patterns.
- **Pilot dynamic workflows on small workloads** before scaling.
- **Watch cost** with `/usage` (skills, subagents, MCPs), `/goal` (turns
  and tokens), and `/workflows` (per-agent usage).

## What a loop is

A **loop** is an agent repeating cycles of work until a stop condition is
met. The concept is about *how a task is triggered and when it stops*, not
a distinct feature. The skill is in **scoping the exit condition** and
**right-sizing the cadence and cost**.

**Loop vs. workflow, in a sentence:** a **loop** repeats *one* line of work
*over time* (again, and again, until done); a **workflow** runs *one* pass
that spreads *across* many agents at once. Loops are about **when / how
often**; workflows are about **how wide**. The two major sections below take
each in turn.

## The primitive concepts at a glance

The building blocks of the family — some are commands (`/loop`, `/goal`,
`/background`), others are concepts (a background job, a workflow, an agent
team) — distinguished by **whether each iteration restarts a fresh agent**
and **what paces the work**. Everything below is a combination of these.

| Primitive concept | Fresh agent per iteration? | Paced by | Runs until | Reach for it when |
|-------------------|----------------------------|----------|------------|-------------------|
| **Background job** | no — detaches the task | n/a (runs once) | it completes (harness pings you) | you want one thing done off to the side while you keep working |
| **`/loop`** | yes — like a new session each tick | an **interval** (fixed `5m`, or self-paced) | you stop it / 7-day expiry | attended, recurring work where each pass should reassess |
| **`/goal`** | yes — each turn | a **condition** (back-to-back, no sleep) | goal met **or** max turns | driving to a verifiable outcome, with a try-cap |
| **Workflow** | spawns many **targeted** agents | a **script**, codified up front | the script completes | one run needs breadth beyond a single agent's context |
| **`/background`** | no — detaches the current session | n/a (runs once, detached) | it finishes or you stop it | hands-off local work without tying up your terminal |
| **Agent teams** *(experimental)* | each teammate, own context | peer coordination via a shared task list | the shared goal is met | work where the agents must message each other |

In table order: a **background job** runs one thing off to the side — dumb
(a shell `watch`) or smart (a backgrounded subagent) — defined by
*single-shot + notify-on-done*, not by being dumb. **`/loop`** is
time-paced: wake every N and reassess. **`/goal`** is condition-paced:
sprint back-to-back until done or capped. A **workflow** is a single
scripted run that fans out to many targeted agents. **`/background`**
detaches the session you are already in (local, runs once, frees your
terminal). **Agent teams** are workflow's peer-coordinated cousin — several
Claude sessions that message each other rather than a script driving them
(experimental, opt-in via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).

Each can embed the others (a `/loop` tick can run a workflow; a workflow
stage can block on a background job) — but, as the sections below show, it
does not always make sense to.

## Loops

**Loops are about time** — repeating one line of work until a stop condition
is met. This family is `/loop` and `/goal` (the two loop commands), the
cloud `/schedule`, the `auto mode` gate that lets them run unattended, and
how a real loop differs from a dumb shell loop.

### The four kinds of loop

| Kind | Trigger | Stops when | Use for |
|------|---------|------------|---------|
| **Turn-based** | you prompt | Claude decides it's done | one-off tasks |
| **Goal-based** (`/goal`) | prompt + success criteria | goal met *or* max turns | tasks with a verifiable exit |
| **Time-based** (`/loop`, `/schedule`) | an interval / event | work done or you cancel | recurring work, monitoring |
| **Proactive** | event/schedule, no human present | each run's goal met | triage, upgrades, migrations |

These map onto the primitives: **turn-based** is no loop primitive at all
(one prompt); **goal-based** is `/goal`; **time-based** is `/loop` /
`/schedule`; **proactive** composes `/schedule` + workflow + `/goal` + auto
mode. Examples from the blog:

- Goal-based: `/goal get the homepage Lighthouse score to 90 or above,
  stop after 5 tries`
- Time-based: `/loop 5m check my PR, address review comments, and fix
  failing CI`
- Proactive: `/schedule every hour: check #project-feedback for bug
  reports`

### `/loop` — local, session-scoped repetition

Runs a prompt repeatedly while you stay in the current session. Both the
interval and the prompt are optional. Three modes:

- **Fixed interval:** `/loop 5m check the deploy` — runs on a cron-like
  schedule.
- **Self-paced:** `/loop check the deploy` — Claude picks dynamic
  intervals (roughly 1 minute to 1 hour) based on what it observes.
- **Maintenance:** `/loop` alone — runs the built-in maintenance prompt
  (continue unfinished work, tend the PR, cleanup), or your custom
  `.claude/loop.md`.

**When it stops:**

- You press `Esc` (clears the pending wakeup).
- After **7 days** of inactivity (auto-expiry).
- In self-paced mode, Claude can end it once the task is provably
  complete.
- You start a new conversation (session-scoped; restorable with
  `--resume` if not expired).
- Claude Code exits or the machine sleeps.

**Scope:** local machine only — your machine must stay on and the session
must stay open.

### `/goal` — condition-paced, with a try-cap

Runs turns **back-to-back** — no sleep between them — until it either meets
an explicit success condition **or** hits a maximum number of tries. It is
*condition-paced*, not time-paced: a sprint to a verifiable outcome with a
safety cap. Example: `/goal get the homepage Lighthouse score to 90 or
above, stop after 5 tries`. Use it when the outcome is clearly defined and
checkable; the turn cap keeps a runaway from burning tokens.

### `/schedule` — cloud, persistent routines

Creates a **routine**: a saved config (prompt + repos + connectors) that
runs on Anthropic-managed cloud infrastructure, persisting independently
of any local session or machine state. Three trigger types:

- **Scheduled** — recurring (hourly to weekly, or custom cron at a ≥ 1-hour
  interval) or one-off at a specific timestamp.
- **API** — an HTTP endpoint callable from CI, alerting, or other systems.
- **GitHub** — reacts to repo events (PR opened/closed/synchronized,
  releases).

**Scope:** Anthropic cloud — works whether your machine is on or off.

### Auto mode — a permission gate, not a loop

Auto mode is not itself a loop, but it lives here because it is what lets a
loop run unattended. **It is a permission classifier, not repetition.** It
evaluates each tool call against a rule set before it runs:

- Allows routine, internal operations automatically (e.g. committing to
  your own repo).
- Blocks destructive/irreversible actions (`hard_deny`: force-push,
  exfiltration).
- Blocks risky actions with a prompt option (`soft_deny`: prod deploys,
  destructive commands).
- Configured via `autoMode.environment`, `autoMode.allow`,
  `autoMode.soft_deny`, and `autoMode.hard_deny` in settings.

It is a **gate**, not a task. Without auto mode, a `/loop` or routine would
stop and ask "run this command?" for every tool call. With it, both run
unattended.

Auto mode (`auto`) is one of several **permission modes** — alongside
`acceptEdits` (auto-approve edits + filesystem commands), `dontAsk` (deny
anything not allowlisted), and a full bypass — that set how much unattended
work may do without asking. See [permission-modes][docs-perm].

### How they differ

| Aspect | `/loop` | `/schedule` | Auto mode |
|--------|---------|-------------|-----------|
| **Purpose** | repeat a task locally | run a task persistently in cloud | remove permission prompts |
| **Trigger** | time (cron or self-paced) | time, API, or GitHub event | N/A — a classifier |
| **Lifetime** | session-scoped; 7-day max | persists across restarts | session setting |
| **Machine on?** | yes | no | N/A |
| **Autonomy** | autonomous in session (respects perms) | fully autonomous | removes prompts from both |

A **proactive loop** composes them: `/schedule` (when/where) + `/goal`
(stop condition) + auto mode (no prompts) + dynamic workflows (multi-agent
orchestration) = a self-managing system that runs without your session
open or your laptop on.

### `/loop` vs a `while` loop (and background jobs)

A `/loop` and a shell `while` loop both "keep going until done," so it is
easy to conflate them. The difference is the **layer the repetition
happens at**, and therefore **whether each iteration has a brain**.

- **`while` / `gh run watch`** — repetition happens in the *shell*, inside
  a single agent turn. `while :; do done? && break; sleep 30; done` is a
  blocking poll of a fixed check. Claude is not awake between iterations;
  it re-executes a *command*, not a *judgment*. Cheap, and it does exactly
  the one thing it was coded to do.
- **`/loop`** — repetition happens at the *agent* layer. Each iteration is
  a fresh Claude turn: the model wakes, re-reads the world, and decides
  what to do this time. It re-runs a *judgment*, so it can adapt ("CI
  failed → read the log → write a fix → push → keep watching"). Costs
  tokens per tick.

| | repeats a… | intelligence per iteration? | cost |
|---|------------|-----------------------------|------|
| `while` / `gh run watch` | command | no | ~free |
| `/loop` | judgment (a whole turn) | yes | tokens per tick |

In BASIC-pseudocode terms, `gh run watch` is the dumb inner poll:

```text
10 check status
20 if still running goto 10
```

and `/loop` is a loop over whole agent turns:

```text
10 agent WAKES FRESH, reads the world
20 do real work (arbitrary, intelligent)
30 SLEEP interval
40 if agent judges not-done goto 10
```

Three things that pseudocode makes precise:

- **Line 10 is a fresh start, not a resume** — the GOTO re-invokes the
  agent from scratch (context largely reset). It is `RUN` again, not
  `CONTINUE`, which is why each iteration can behave differently.
- **There is a `SLEEP` before the GOTO lands** — not a tight spin; line 30
  waits the interval (fixed like `5m`, or self-paced) before re-entering.
- **"if not done" is a judgment, not a flag** — the agent looks at the
  world and reasons about whether it is done; there is no mechanical
  `done=1`.

And the nesting falls out: **line 20 can itself contain a `gh run watch`
while/do loop.** The dumb blocking poll lives inside one intelligent
iteration — `while` is a loop *body*, `/loop` is a loop *over agent turns*.

**Often you need neither.** In this harness a backgrounded blocking call
(e.g. a background `gh run watch`) is **auto-notified on completion** — you
get "wake me when CI is done" without a foreground `while` burning a turn
*and* without a `/loop` burning tokens re-thinking every tick. The harness
does the waiting; Claude re-engages once, when there is something new to
reason about. (That backgrounded call is a **background job** — the workflow
family's building block, defined in the next major section.)

The rule of thumb that falls out:

- **Wait** for a fixed condition → block or background a command (no brain
  needed while waiting).
- **React/adapt** on each check → `/loop` (brain needed each time).
- **Left the room, or it recurs** → `/loop` or `/schedule`.

### Choosing a loop type

- **Turn-based** when exploring and deciding.
- **Goal-based** when the outcome is clearly defined.
- **Time-based** when work follows a schedule or external trigger.
- **Proactive** when work is recurring and well-structured.

Iterate after watching where a loop stalls or over-reaches; don't build
overly complex automation from the start.

## Workflows

**Workflows are about breadth** — running one task across many agents at
once, rather than repeating one task over time. This family covers the
background job (the building block you wait on), the Workflow tool itself,
`/background`, and agent teams, plus how to choose among the ways to run
many agents and what makes a good fan-out.

### Background jobs — one thing off to the side

A **background job** runs one unit of work off to the side and the harness
pings you when it finishes. It is *single-shot* (no cadence) and defined by
*notify-on-done*, not by being dumb — the unit can be a blind shell poll
(`gh run watch`) **or** an intelligent backgrounded subagent. It is not
itself a workflow, but it is the building block a workflow stage (or a
`/loop` tick) **blocks on** when it needs to wait for something external. For
how a background job differs from a `/loop` — shell-layer waiting vs
agent-layer repetition — see *`/loop` vs a `while` loop* in the Loops
section above.

### What a workflow is

A **workflow** (the Workflow tool; invoked with `ultracode` or "use a
workflow") is a JavaScript script that orchestrates many subagents at scale.
Claude writes the script for the task you describe, and a runtime runs it in
the background while your session stays responsive. The **script is the
orchestrator** — the plan is codified in code, and results live in script
variables rather than your context, which is what lets one run fan out to
dozens or hundreds of agents without blowing context. "**Dynamic**" refers
to the *generation*: Claude authors the script on the fly for your ask; save
it and it becomes a reusable command (the orchestration is then fixed). Best
for large, homogeneous, parallel work — see *What makes a good workflow fit*.
See [workflows][docs-workflows-tool].

### `/background` — detach the whole session

`/background` takes the session you are **already in** and detaches it to
keep running locally, freeing your terminal; pass a prompt to send one more
instruction before it detaches. Unlike `/loop` (interval-driven) or
`/schedule` (cloud), it is a one-shot local detach of the current work —
"keep going without me on this screen." Monitor and re-attach detached
sessions with `claude agents` (see *Watching unattended work*).

### Agent teams (experimental)

**Agent teams** are multiple **Claude sessions** — not people — working
together for a single human user: each teammate runs in its own context,
they share a task list and **message each other**, with a lead coordinating.
Experimental and opt-in (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). Unlike a
workflow (a script drives disposable subagents that only report up), agent
teams coordinate *among themselves* — reach for them when the agents
genuinely need to talk, not just fan out. See [agent-teams][docs-teams].

### Three ways to run many agents

Delegating to *other* agents comes in three shapes — pick by how much the
agents need to coordinate:

- **Subagents** — you hand a helper one scoped side task; it runs in its own
  context and **reports back to you**. They don't talk to each other. The
  lightweight default (`/agents` manages them; `/fork` is a variant that
  inherits your full context). See [sub-agents][docs-subagents].
- **Workflows** — a **script** orchestrates the fan-out: dozens of agents,
  codified control flow, results in script variables. Best for large,
  homogeneous, parallel work.
- **Agent teams** *(experimental)* — several Claude sessions with a **shared
  task list** who **message each other**, a lead coordinating. For work where
  the agents genuinely need to coordinate, not just fan out.

Rule of thumb: **report-up → subagents; scripted fan-out → workflow; peer
coordination → agent team.** `/batch` (below) is a ready-made skill built on
the subagents-in-worktrees pattern.

### Skills vs. workflows (why `ship-pr` is a skill)

"Workflow" in everyday English means "a process with steps," so a
multi-step **skill** like `ship-pr` feels like a workflow. In the precise
sense used here it is not — the two are different animals:

| | **Skill** (e.g. `ship-pr`) | **Workflow** (the Workflow tool) |
|---|----------------------------|----------------------------------|
| Written in | Markdown prose (+ optional shell helper) | JavaScript |
| Who orchestrates | **Claude**, reading the steps, judging each one | **the script**, deterministically |
| Plan lives in | Claude's context | code, outside context |
| Shape | **sequential** procedure with decision points | **fan-out** — many parallel subagents |
| Executor | the main agent, one thread | spawned subagents |

`ship-pr` is textbook skill: it is inherently **sequential** (commit →
push → open PR → watch CI → merge → tag → cleanup, each step depending on
the last), it has **human-approval gates** (merge only with explicit
approval), and it **composes other skills** (`release-tag`,
`retrospective`, `shell-startup-guard`) — all prose-level, Claude as the
one executor. Its `ship.sh` helper is just the deterministic git/gh bits
pulled into a script ("use scripts for deterministic work" *within* a
skill); it orchestrates no agents.

**The litmus:** a workflow's defining move is **spawning targeted
subagents under codified (scripted) control flow.** `ship-pr` never spawns
an agent — it *is* the one agent walking a checklist, so it is a skill. The
only place a workflow would appear near it is the reverse nesting: a
workflow that invokes `ship-pr` once per branch to ship several independent
branches in parallel — the workflow does the fan-out, the skill does each
linear ship.

### Can a loop run a workflow?

Yes — each `/loop` tick is a fresh agent turn, and a turn can invoke a
workflow (e.g. `/loop 30m /audit-endpoints`), so the whole fan-out re-runs
each iteration. But it is a **narrow niche**, because loops and workflows
overlap on the "repeat" axis and there are usually better tools:

- **A workflow can already loop internally** (loop-until-dry, for-each-
  batch). If the repetition is *within one job*, put the loop inside the
  script — you do not need `/loop` around it.
- **`/schedule` beats `/loop` for unattended recurrence.** "Run this
  nightly" is a scheduled routine, not a session loop.

So `/loop` + workflow earns its place only when **all** of these hold at
once:

1. You are **attended / in-session** (else `/schedule`).
2. The task **recurs on a cadence** (else run the workflow once).
3. **Each run needs fresh fan-out** (else a plain `/loop` with one agent is
   enough).

A scenario that fits: while actively working, `/loop 30m` re-runs a
workflow that reviews *every* open PR in parallel and posts a digest —
cadence from the loop, breadth-per-run from the workflow, live in-session
so you act on each digest immediately. Walk away and it should have been
`/schedule`; only one PR and it should have been a plain background watch.

### What makes a good workflow fit

A workflow's shape is "many independent items → one agent each, in parallel,
orchestrated by a script." But *having* discrete items is a **necessary, not
sufficient** condition. A good fit clears a higher bar:

- **Real independence, not "usually."** Items must not share files or depend
  on each other's order — parallel agents writing the same file collide.
  Where writes overlap, isolate them (the Workflow tool's
  `isolation: 'worktree'` gives each agent its own git worktree) or partition
  the shared parts into a final serial stage.
- **Homogeneity.** Fan-out codifies cleanly when it is *the same operation
  over similar items*. Wildly different tasks each need bespoke handling —
  hard to script, easy to get wrong at scale.
- **Verifiability.** Each item's result should be independently checkable (a
  verify stage), or the run produces N unreviewed changes at once.
- **Bounded & specified.** Ambiguous items that need a human decision do not
  fan out well — you would parallelize guessing.

Two contrasting examples make the bar concrete.

**A directory of Terraform modules — strong fit.** A tree like
`tfmods/<module>/` is close to ideal: **directory-partitioned** (each agent
owns one module's mostly-disjoint files), **homogeneous** (create/update a
module to a shared spec is the same operation N times), and **verifiable**
(fmt / validate / tflint / trivy / tftest / terraform-docs per module — the
`terraform-review` skill is a ready verify stage). Design: *fan out per
module (worktree-isolated) → verify each → a final pass for shared/root
files*. Mind two things: parallel writes need worktree isolation, and shared
files (a root `versions.tf`, a modules index) or inter-module dependencies
break pure parallelism — handle those serially and sequence any dependency
chains.

**A raw TODO file — weak fit until curated.** A heterogeneous task list is
*not* a good "point a workflow at it" target: tasks differ in size, type,
and acceptance criteria (not homogeneous); "usually discrete" hides coupling
(items sharing a file or assuming another's change); many sit in a TODO
*because* they need a decision (judgment-heavy); and N parallel changes
become N things to review at once (parallel authoring, serial review). The
right pattern is **scout → curate → fan out**, where **curate is a
deliberate human decision made first** — you (with the agent) go through the
list, pick a *batch* of genuinely independent, well-specified,
similar-enough items, and decide how to separate them. Only *then* fan out
over that curated batch. The workflow runs the batch; it never infers what
is batchable — that is the call you make going in.

**The discriminator:** real independence + homogeneity + a verify gate. A
module tree has all three by construction; a raw TODO has none reliably — so
it earns a workflow only after the curation step supplies them.

**A ready-made version:** the bundled **`/batch`** skill *is* this pattern —
it researches the codebase, decomposes the change into 5–30 units, and
spawns one worktree-isolated subagent per unit that implements, tests, and
opens its own PR. Reach for it when the batch is a genuine fit; you still
hand-curate what goes in, exactly as above.

## Watching unattended work

Once work runs without you, these show what is happening:

- **`/tasks`** — everything in the background right now (subagents,
  workflows, background shell commands); attach or stop any of them.
- **`/workflows`** — running/finished workflows, drill into phases and
  agents, live token cost; pause/resume a run.
- **`claude agents`** — your detached `/background` sessions and which ones
  need input (see [agent-view][docs-agentview]).
- **`/usage`** — session cost and plan limits, broken down by skill /
  subagent / plugin / MCP.

## Driving it from scripts (headless)

Everything above can be invoked non-interactively for CI or scripts with
`claude -p "<prompt>"` (print mode), using `--resume` / `--continue` to
carry a session across invocations and `--permission-mode` to control what
runs without a prompt. This is the surface that turns a loop or workflow
into a scheduled or CI-triggered job. See [headless][docs-headless].

## Adjacent: event-driven automation (a different family)

Loops and workflows are about **repetition and fan-out**. A separate family
**reacts to events** instead — it fires when something happens, not on a
timer:

- **Hooks** — shell / HTTP / MCP / LLM actions on lifecycle events
  (`PreToolUse`, `PostToolUse`, `SessionStart`, task created/completed, …)
  for validation, gating, and coordination. See [hooks][docs-hooks].
- **Channels** *(research preview)* — external systems (Telegram, Discord,
  webhooks) **push** messages into a running session for Claude to react to.
  See [channels][docs-channels].
- **GitHub Actions** and **routine triggers** (GitHub / API) fire Claude
  work from repo events or an HTTP call — the event-driven counterparts to
  `/schedule`'s timer. See [github-actions][docs-gha].

Each of these deserves its own reference (tracked in the backlog); this doc
stays on loops and workflows.

## Sources

Distilled from the [Getting started with loops][blog] blog post and the
official Claude Code documentation: [scheduled-tasks][docs-loop] (`/loop`),
[routines][docs-schedule] (`/schedule`), [auto-mode][docs-auto],
[permission-modes][docs-perm], [sub-agents][docs-subagents],
[workflows][docs-workflows-tool], [agent-teams][docs-teams],
[agent-view][docs-agentview], [headless][docs-headless], [hooks][docs-hooks],
[channels][docs-channels], and [github-actions][docs-gha].

[blog]: https://claude.com/blog/getting-started-with-loops
[docs-loop]: https://code.claude.com/docs/en/scheduled-tasks
[docs-schedule]: https://code.claude.com/docs/en/routines
[docs-auto]: https://code.claude.com/docs/en/auto-mode-config
[docs-perm]: https://code.claude.com/docs/en/permission-modes
[docs-subagents]: https://code.claude.com/docs/en/sub-agents
[docs-workflows-tool]: https://code.claude.com/docs/en/workflows
[docs-teams]: https://code.claude.com/docs/en/agent-teams
[docs-agentview]: https://code.claude.com/docs/en/agent-view
[docs-headless]: https://code.claude.com/docs/en/headless
[docs-hooks]: https://code.claude.com/docs/en/hooks
[docs-channels]: https://code.claude.com/docs/en/channels
[docs-gha]: https://code.claude.com/docs/en/github-actions
