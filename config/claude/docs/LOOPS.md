# Claude Code Loops

A reference for Claude Code's loop primitives — what a loop is, the four
kinds, how `/loop` and `/schedule` actually behave, and how "auto mode"
fits in. Distilled from the [Getting started with loops][blog] blog post
and the official [scheduled-tasks][docs-loop], [routines][docs-schedule],
and [auto-mode][docs-auto] docs.

## What a loop is

A **loop** is an agent repeating cycles of work until a stop condition is
met. The concept is about *how a task is triggered and when it stops*, not
a distinct feature. The skill is in **scoping the exit condition** and
**right-sizing the cadence and cost**.

## The primitives at a glance

Four building blocks, distinguished by **whether each iteration restarts a
fresh agent** and **what paces the repetition**. Everything below is a
combination of these.

| Primitive | Fresh agent per iteration? | Paced by | Runs until | Reach for it when |
|-----------|----------------------------|----------|------------|-------------------|
| **Background job** | no — single-shot | n/a (runs once) | it completes (harness pings you) | you want one thing done off to the side while you keep working |
| **`/loop`** | yes — like a new session each tick | an **interval** (fixed `5m`, or self-paced) | you stop it / 7-day expiry | attended, recurring work where each pass should reassess |
| **`/goal`** | yes — each turn | a **condition** (back-to-back, no sleep) | goal met **or** max turns | driving to a verifiable outcome, with a try-cap |
| **Workflow** | spawns many **targeted** agents | a **script**, codified up front | the script completes | one run needs breadth beyond a single agent's context |

The axis in one line: a **background job** is single-shot; **`/loop`** is
time-paced ("wake every N and reassess"); **`/goal`** is condition-paced
("sprint until done or capped"); a **workflow** is a single scripted run
that fans out. A background job can be dumb (a shell `watch`) or smart (a
backgrounded subagent) — what defines it is *single-shot + notify-on-done*,
not determinism. Each can embed the others (a `/loop` tick can run a
workflow; a workflow stage can block on a background job) — but, as the
sections below show, it does not always make sense to.

The blog's four *kinds* of loop are framings of these: **turn-based** (no
loop primitive at all — one prompt), **goal-based** (`/goal`),
**time-based** (`/loop`, `/schedule`), and **proactive** (`/schedule` +
workflow + `/goal` + auto mode).

## The four kinds of loop

| Kind | Trigger | Stops when | Use for |
|------|---------|------------|---------|
| **Turn-based** | you prompt | Claude decides it's done | one-off tasks |
| **Goal-based** (`/goal`) | prompt + success criteria | goal met *or* max turns | tasks with a verifiable exit |
| **Time-based** (`/loop`, `/schedule`) | an interval / event | work done or you cancel | recurring work, monitoring |
| **Proactive** | event/schedule, no human present | each run's goal met | triage, upgrades, migrations |

Examples from the blog:

- Goal-based: `/goal get the homepage Lighthouse score to 90 or above,
  stop after 5 tries`
- Time-based: `/loop 5m check my PR, address review comments, and fix
  failing CI`
- Proactive: `/schedule every hour: check #project-feedback for bug
  reports`

## `/loop` — local, session-scoped repetition

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

## `/schedule` — cloud, persistent routines

Creates a **routine**: a saved config (prompt + repos + connectors) that
runs on Anthropic-managed cloud infrastructure, persisting independently
of any local session or machine state. Three trigger types:

- **Scheduled** — recurring (hourly to weekly, or custom cron at a ≥ 1-hour
  interval) or one-off at a specific timestamp.
- **API** — an HTTP endpoint callable from CI, alerting, or other systems.
- **GitHub** — reacts to repo events (PR opened/closed/synchronized,
  releases).

**Scope:** Anthropic cloud — works whether your machine is on or off.

## Auto mode — a permission gate, not a loop

**Auto mode is a permission classifier, not repetition.** It evaluates
each tool call against a rule set before it runs:

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

## How they differ

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

## Loops vs. `while` / background jobs

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
reason about.

The rule of thumb that falls out:

- **Wait** for a fixed condition → block or background a command (no brain
  needed while waiting).
- **React/adapt** on each check → `/loop` (brain needed each time).
- **Left the room, or it recurs** → `/loop` or `/schedule`.

## Can a loop run a workflow?

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

## Skills vs. workflows (why `ship-pr` is a skill)

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

## Best practices

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

## Choosing a loop type

- **Turn-based** when exploring and deciding.
- **Goal-based** when the outcome is clearly defined.
- **Time-based** when work follows a schedule or external trigger.
- **Proactive** when work is recurring and well-structured.

Iterate after watching where a loop stalls or over-reaches; don't build
overly complex automation from the start.

[blog]: https://claude.com/blog/getting-started-with-loops
[docs-loop]: https://code.claude.com/docs/en/scheduled-tasks
[docs-schedule]: https://code.claude.com/docs/en/routines
[docs-auto]: https://code.claude.com/docs/en/auto-mode-config
