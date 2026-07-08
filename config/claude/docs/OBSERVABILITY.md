# Claude Code Observability

When Claude is doing work you aren't watching keystroke-by-keystroke — a
background shell, a multi-agent workflow, several dispatched sessions, or just
a long turn — you need to *see* what's happening: what's running, what it's
spending, what's stuck waiting for you. **Observability** is the set of Claude
Code surfaces for that: `/tasks` (background shells and subagents),
`/workflows` (orchestrated multi-agent runs), `claude agents` (a fleet view of
background sessions), `/usage` (tokens, cost, rate limits), `/context` (what
fills the context window), and the always-on **statusline**. This doc covers
what each shows, how they differ, and which to reach for — the monitoring
half of running unattended work (the *how to run it* half is the loops &
workflows doc).

## ELI5

*Watch running work:*

- **`/tasks`** — the background shells and subagents running in *this* session;
  drill in, stop, pause, restart.
- **`/workflows`** — the live progress of an orchestrated multi-agent run:
  phases, how many agents, tokens spent, elapsed time.
- **`claude agents`** (or **`/agents`**) — a fleet screen of all your
  background *sessions*, grouped by Needs-input / Working / Completed.

*Understand cost and context:*

- **`/usage`** — tokens and estimated cost, plus (on a plan) rate-limit
  consumption; `d` / `w` toggle 24h / 7 days.
- **`/context`** — what's filling the context window right now, component by
  component, so you know what to trim.

*See it continuously / audit it:*

- **statusline** — context %, rate-limit, and effort shown all the time,
  without running a command.
- **`Ctrl+O`** — the transcript viewer: every tool call, its arguments and
  result.
- **`/status`** — which auth method is active and the session's validity.

### Best practices

- **Match the surface to the unit of work.** A background shell → `/tasks`; a
  Workflow → `/workflows`; several whole sessions → `claude agents`. Using the
  wrong one shows you nothing.
- **Glance at the statusline, drill with a command.** The statusline is the
  ambient signal (context filling, rate-limit climbing); `/usage` and
  `/context` are the detail views when it flags something.
- **Watch cost on big fan-outs.** A workflow warns past ~25 agents or ~1.5M
  projected tokens — take that as the cue to open `/workflows` and confirm
  it's doing what you meant before it spends more.
- **Step in only when a session needs you.** The fleet view's *Needs input*
  group is the point of unattended work — let *Working* run, answer the ones
  that block.

## Overview

The surfaces split on **what unit of work they watch** and **whether they're
pulled up on demand or always on**. `/tasks`, `/workflows`, and
`claude agents` each watch a different granularity of *running* work — a
shell/subagent inside a session, an orchestrated fan-out, and a whole
background session, respectively. `/usage` and `/context` answer *resource*
questions — what you're spending and what's loaded. The statusline is the only
**continuous** one; everything else you invoke when you want it.

The distinction to remember: **`/tasks` < `/workflows` < `claude agents` is a
ladder of scope** — a background command, a multi-agent run, an entire session
— so reach for the one that matches the thing you launched.

### At a glance

| Surface | Watches | On demand / always-on | Reach for it when |
|---------|---------|-----------------------|-------------------|
| **`/tasks`** | background shells + subagents in this session | on demand | a background job is running; inspect or stop it |
| **`/workflows`** | orchestrated multi-agent runs (phases, agents, tokens) | on demand | a Workflow is running; watch progress and spend |
| **`claude agents`** | all background *sessions* (fleet) | on demand | you dispatched several sessions; triage them |
| **`/usage`** | tokens, estimated cost, plan rate-limits | on demand | "how much have I used / am I near a limit?" |
| **`/context`** | what's filling the context window | on demand | context is full; find what to trim |
| **statusline** | context %, rate-limit, effort | **always on** | an at-a-glance read without a command |

In table order: **`/tasks`** watches the shells and subagents inside the
current session; **`/workflows`** watches an orchestrated fan-out as phases of
agents; **`claude agents`** zooms out to every background session at once;
**`/usage`** answers cost/limit questions; **`/context`** shows what's loaded;
the **statusline** keeps the two ambient signals (context %, rate-limit) in
front of you continuously.

## Watching running work

### `/tasks` — background shells and subagents

`/tasks` lists the background Bash commands and subagents running in the
current session, with a detail view per task (its prompt, tool calls, result).
Each backgrounded shell gets a unique task ID and streams output to a file
Claude can read back. From the panel: arrow keys select, `Enter` / `→` drills
in, `x` stops, `p` pauses/resumes, `r` restarts. (`Ctrl+T` toggles Claude's
*to-do* list — a different thing; `/tasks` is the running-work view.) Disable
the feature entirely with `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`.

### `/workflows` — orchestrated multi-agent runs

When a Workflow is running (see the loops & workflows doc), `/workflows` lists
running and completed runs; select one for a progress view of its **phases**,
each showing the agent count, cumulative tokens, and elapsed time. Drill into
a phase, then an agent, to read its prompt, recent tool calls, and result; `f`
filters agents by status, `x` stops an agent (or the whole run), `s` saves the
run's script as a command. A one-line summary also rides in the task panel
below the input box. A run that schedules **more than ~25 agents** or projects
**more than ~1.5M tokens** flags a *Large workflow* warning — the cue to check
it's on track before it spends more.

### `claude agents` — the fleet view

`claude agents` (CLI) or `/agents` opens one screen for **all background
sessions** spawned from this terminal, grouped **Needs input / Working /
Completed**. Each row shows the session name, working directory, model, a
summary of what it's doing or waiting on, and — if a PR is attached — its CI
status. Navigate with arrows; `Enter` attaches to a session's full
conversation; on a *Needs input* row you can peek at the prompt and reply
without fully attaching; `n` dispatches a new session. This is the surface for
*unattended* work — let the *Working* group run, and step in only where a
session blocks. (Note the name overlap: the `/agents` **command** manages
subagent *definitions* in `.claude/agents/`; the fleet view watches *running*
sessions.)

## Cost, limits, and context

### `/usage` — tokens, cost, and rate limits

`/usage` reports the current session's token usage and a **locally-estimated**
dollar cost (an estimate, not your bill), and — on a subscription plan — plan
usage bars and rate-limit consumption; press `d` / `w` to switch the window
between the last 24 hours and 7 days. On a plan it also **attributes** recent
usage to skills, subagents, plugins, and individual MCP servers, each as a
percentage — useful for spotting what's eating your limit. For authoritative
billing, the Console is the source of truth, not this estimate.

### `/context` — what's filling the window

`/context` breaks down what's currently loaded in the context window — system
prompt, auto-memory, `CLAUDE.md`, MCP tool schemas, loaded files, conversation
history — with each component's token size, separating automatic from
user-added content. Reach for it when context is filling and you need to know
*what* to trim (a chatty MCP server's schemas, a large loaded file) rather
than guessing.

## Always-on and audit surfaces

- **The statusline** is the only continuous observability surface — this
  config's (`config/claude/bin/statusline.sh`) renders the context-% (color-
  ramped), a rate-limit segment (5h / 7d usage), the reasoning-effort level,
  and the vim mode, so the two signals `/usage` and `/context` report on demand
  are always in view. Configure a context-% segment even in a stock setup.
- **`Ctrl+O`** toggles the transcript viewer — every tool call with its
  arguments, result, and (expanded) MCP calls — for auditing what Claude
  actually did behind the conversational view.
- **`/status`** shows the active authentication method and session validity
  (see the claude-code-auth rule for this config's method precedence).
- **OpenTelemetry** — for org-level monitoring, `CLAUDE_CODE_ENABLE_TELEMETRY=1`
  plus `OTEL_*` exporters stream metrics and events (sessions, tokens, cost,
  PRs, commits, tool calls) to a backend like Prometheus or Datadog. Overkill
  for a solo setup; the on-demand commands above cover it.

## Bringing it together

The reach-for-it flow: the **statusline** is your ambient read — when its
context-% climbs, `/context` tells you what to trim; when its rate-limit
segment climbs, `/usage` breaks down what's spending. For *running* work, pick
the surface at your unit's scope — `/tasks` for a background command inside the
session, `/workflows` for a fan-out you orchestrated, `claude agents` for the
whole fleet of sessions you dispatched — and remember all three share the same
controls (arrows to select, `Enter` to drill in, `x`/`p`/`r` to stop / pause /
restart). Unattended work pays off precisely when you can leave *Working*
alone and only answer *Needs input*.

## See also — adjacent, out of scope

- **Loops & workflows** — *running* unattended work (loop types, orchestrating
  a workflow); this doc is the *watching* half. Its "Watching unattended work"
  section is the short version of the above. See [Loops & Workflows][loops].
- **Permission modes & auto mode** — what lets unattended work proceed without
  prompts (so there's something to observe). See [Permission Modes & Auto
  Mode][perm-doc].

## Resources

Distilled from the official Claude Code documentation:

- [Interactive mode][interactive-mode] — `/tasks`, `Ctrl+T` / `Ctrl+O`, and
  background-task behavior
- [Workflows][workflows-doc] — `/workflows`, the progress view, and the
  large-run warning
- [Agent view][agent-view] — `claude agents` / `/agents`, session grouping,
  and controls
- [Costs & usage][costs] — `/usage`, cost estimation, and the plan-usage
  breakdown
- [Monitoring usage][monitoring] — OpenTelemetry metrics and events for
  org-level observability

[interactive-mode]: https://code.claude.com/docs/en/interactive-mode
[workflows-doc]: https://code.claude.com/docs/en/workflows
[agent-view]: https://code.claude.com/docs/en/agent-view
[costs]: https://code.claude.com/docs/en/costs
[monitoring]: https://code.claude.com/docs/en/monitoring-usage
[loops]: LOOPS-WORKFLOWS.md
[perm-doc]: PERMISSION-MODES.md
