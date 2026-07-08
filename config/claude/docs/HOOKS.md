# Claude Code Hooks

A **hook** is a command Claude Code runs automatically at a defined point in
its lifecycle — before a tool call, after an edit, when a session starts,
before it compacts context. Hooks are how behaviour is enforced
**deterministically**, without relying on the model to remember a rule: a
`PreToolUse` hook can *block* a dangerous command, a `PostToolUse` hook can
format the file just written, a `SessionStart` hook can inject context. This
doc covers when hooks fire (the event families), how one is wired
(`settings.json` + matchers), the **contract** a hook speaks (its stdin, exit
codes, and JSON output), how several hooks on one event combine, and the
safety model — illustrated with this config's own hooks. The permission
interaction (a hook that allows/denies a call) is summarized here and detailed
in the permission-modes doc.

## ELI5

*What a hook is:*

- **hook** — a command that runs itself at a set moment (a tool call, a
  session start), so a rule is *enforced* instead of *remembered*.
- **event** — the moment a hook fires on (`PreToolUse`, `PostToolUse`,
  `SessionStart`, …).
- **matcher** — which occurrences of that event a hook cares about (e.g. only
  the `Bash` tool, only a `compact` session start).

*The two ways a hook talks back:*

- **exit code** — `0` = fine; `2` = block the action and send stderr to Claude
  as feedback; any other non-zero = non-blocking error (logged, action
  proceeds).
- **JSON on stdout** — structured control: a permission decision, injected
  context, a rewritten tool input.

*Where hooks live:*

- **`settings.json` `hooks` key** — event → matcher → handler; merges across
  user / project / local / managed scopes (all matching hooks run).
- **`/hooks`** — a read-only browser of what's configured (edit the JSON to
  change them).

### Best practices

- **Fail open.** A hook bug must never wedge the agent — catch everything and
  exit 0 on error. This config's hooks all do (any exception → allow).
- **Block with exit 2 *or* JSON, never both** — Claude Code ignores the JSON
  when you exit 2.
- **A hook is a backstop, not the enforcement.** A `PreToolUse` `allow` can't
  override a `deny` rule; for a hard limit use a permission `deny` rule (see
  the permission-modes doc). Hooks catch what the model might forget.
- **Keep them fast.** Every matching hook runs before the action proceeds; a
  slow `PostToolUse` hook stalls every edit. Mind the per-type timeout.
- **Never log a secret.** Hooks inherit your shell env (API keys included);
  treat their scripts as security-sensitive.

## Overview

Two questions define a hook: **when** does it fire (the event, narrowed by a
matcher) and **what does it say back** (its exit code / JSON). The event
determines *what a hook can do*: only some events can **block** — `PreToolUse`
is the powerful one (it can stop a tool call before it runs); most others
observe, react, or inject.

The organizing distinction: **`PreToolUse` is a gate** (it decides whether an
action happens), **`PostToolUse` and friends are reactions** (the action
already happened — format, log, verify), and **`SessionStart` / `PreCompact`
are context events** (inject or preserve state around the model's memory). Get
that trichotomy and the rest is detail.

### At a glance — the common events

| Event | Fires | Can block? | Typical use |
|-------|-------|-----------|-------------|
| **`PreToolUse`** | before a tool runs | **yes** | validate / block a command, allow-or-deny |
| **`PostToolUse`** | after a tool succeeds | no (already ran) | format, lint, log, rewrite output |
| **`UserPromptSubmit`** | when you submit a prompt | yes | validate input, inject context |
| **`SessionStart`** | session begins / resumes / after compact | no | inject a state snapshot, load env |
| **`SessionEnd`** | session ends | no | cleanup, logging |
| **`Stop`** | Claude finishes responding | yes (bounded) | verify the task is actually done |
| **`PreCompact` / `PostCompact`** | around context compaction | no | save / re-inject state the summary drops |

In table order: **`PreToolUse`** is the only everyday event that can *stop* an
action; **`PostToolUse`** reacts after a tool succeeded (it can't undo it);
**`UserPromptSubmit`** sees your prompt before Claude does; **`SessionStart`**
fires on startup/resume/clear/compact and can add to context; **`SessionEnd`**
is for teardown; **`Stop`** can send Claude back to work if a task isn't
finished (with a block cap so it can't loop forever); **`PreCompact` /
`PostCompact`** bracket compaction so state can survive it. Beyond these,
Claude Code has a larger set (~two dozen) covering subagents, tasks, MCP
elicitation, worktrees, file/cwd/config changes, and permission dialogs —
reach for the [hooks reference][hooks-ref] when you need one; this doc focuses
on the everyday ones (and the ones this config uses).

## The event families

- **Tool events** — `PreToolUse` (before; blockable) and `PostToolUse` (after
  success; can rewrite output but not undo). The workhorses.
- **Turn events** — `UserPromptSubmit` (before Claude reads your prompt;
  blockable, can inject context) and `Stop` (after Claude answers; can block
  the stop to demand more work, up to a cap).
- **Session events** — `SessionStart` (matcher: `startup` / `resume` /
  `clear` / `compact`) and `SessionEnd`. Startup/compact stdout is added to
  context.
- **Compaction events** — `PreCompact` / `PostCompact` (matcher: `manual` /
  `auto`) — save state before the summary and re-inject after.
- **Permission events** — `PermissionRequest` (a dialog is about to show;
  auto-approve or set a mode) and `PermissionDenied` (auto mode's classifier
  blocked something; can request a retry). See the permission-modes doc.
- **The long tail** — subagent, task, MCP-elicitation, worktree, and
  file/cwd/config-change events exist too; consult the reference when a niche
  one is needed rather than memorizing them.

## Configuring a hook

Hooks are declared under a top-level `hooks` key, nested **event → matcher
group → handler**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          { "type": "command", "command": "python3 ~/.claude/hooks/guard.py" }
        ]
      }
    ]
  }
}
```

- **matcher** — narrows *within* an event. For tool events it matches the
  tool name (`Bash`, `Edit|Write|MultiEdit`, a `mcp__server__.*` regex; `|`
  and `,` are interchangeable list separators, empty/`*` = all). For other
  events it matches that event's own axis — `SessionStart` matches the
  *source* (`compact`, `startup|resume|clear`), `PreCompact` the *trigger*
  (`manual` / `auto`), and so on.
- **`if`** — an optional finer filter using permission-rule syntax
  (`"if": "Bash(git *)"`), so a hook fires only for matching *arguments*, not
  just the tool name. Best-effort — for hard enforcement use a permission
  rule.
- **type** — usually `command` (shell command, JSON on stdin). Other types
  exist (`http`, `prompt`, `mcp_tool`, `agent`) for POSTing to an endpoint or
  a model-evaluated check.
- **timeout** — seconds; command hooks default generous (minutes), but some
  events cap lower (`UserPromptSubmit` ~30s).
- **scope** — hook configs live in user (`~/.claude/settings.json`), project
  (`.claude/settings.json`), local (`.claude/settings.local.json`), managed,
  or plugin/skill sources. They **combine** — every matching hook from every
  scope runs; there is no override. (`disableAllHooks: true` turns them off.)

`/hooks` shows a read-only view of everything configured; you edit the JSON
(or ask Claude to) to change it.

## The hook contract — stdin, exit codes, JSON

**Input (stdin).** Every hook receives a JSON object with common fields —
`session_id`, `transcript_path`, `cwd`, `hook_event_name`, and
`permission_mode` — plus event-specific ones: `tool_name` + `tool_input` for
`PreToolUse`, `tool_response` for `PostToolUse`, `prompt` for
`UserPromptSubmit`, `source` for `SessionStart`. A command hook reads it from
stdin (this config's Python hooks do `json.load(sys.stdin)`).

**Output — two mechanisms, don't mix them:**

- **Exit code.** `0` = no objection (for `UserPromptSubmit` / `SessionStart`,
  stdout is added to Claude's context). `2` = **block** — the action is
  stopped and stderr is fed back to Claude as the reason (on the events that
  can't block, exit 2 just shows stderr to the user and continues). Any other
  non-zero = non-blocking error: the action proceeds, the transcript notes a
  hook error.
- **JSON on stdout (with exit 0).** Structured control via a
  `hookSpecificOutput` object plus top-level fields like `additionalContext`,
  `continue`, and `suppressOutput`. For `PreToolUse` the decision field is
  `permissionDecision` (`allow` / `deny` / `ask` / `defer`) with a
  `permissionDecisionReason`; `additionalContext` injects text for
  `UserPromptSubmit` / `SessionStart`.

A key rule (detailed in the permission-modes doc): a hook's `allow` **does not
override** a permission `deny` rule, and a hook that exits 2 blocks *before*
the permission rules are evaluated.

## How several hooks on one event combine

When multiple hooks match an event they **all run** (in parallel, identical
commands de-duplicated) — one returning `deny` does not stop its siblings.
Results are then merged: for a `PreToolUse` permission decision the **most
restrictive** wins (`deny` > `defer` > `ask` > `allow`), and every hook's
`additionalContext` is kept and passed to Claude together. So a hook is a
*voice*, not a veto over other hooks — the strictest voice decides.

## Bringing it together — this config's hooks

Every hook here is **fail-open** (any error → allow) and maps cleanly onto the
gate / react / inject trichotomy:

| Hook | Event (matcher) | Role |
|------|-----------------|------|
| `branch-protection.py` | `PreToolUse` (`Edit\|Write\|MultiEdit`) | **gate** — block edits while a protected branch is checked out |
| `merge-finalization.py` | `PreToolUse` (`Bash`) | **gate** — block a merge with unpruned `- [x]` items |
| `secret-echo-guard.py` | `PreToolUse` (`Bash`) | **gate** — block echoing a secret's value to the terminal |
| `terraform-import-safety.py` | `PreToolUse` (`Bash`) | **remind** — verify an import target isn't already in state |
| `rule-coverage.py` | `PostToolUse` (`Edit\|Write`) | **react** — nag when a new tool/lang has no `rules/` file |
| `shell-check.py` | `PostToolUse` (`Edit\|Write\|MultiEdit`) | **react** — run `shellcheck` on a shell file just edited |
| `iac-fmt.py` | `PostToolUse` (`Edit\|Write\|MultiEdit`) | **react** — `terraform`/`packer fmt` an edited IaC file |
| `md5-guard.py` | `PostToolUse` (`Edit\|Write\|MultiEdit`) | **react** — regenerate a tracked `.md5` after its file changes |
| `compact-snapshot.py` | `SessionStart` (`compact`) | **inject** — re-add a git/session snapshot after `/compact` |
| `audit-cadence.py` | `SessionStart` (`startup\|resume\|clear`) | **inject** — a once-a-day `claude-audit` nudge |

Read the pattern: the **gates** are all `PreToolUse` (only that event can stop
an action) and split into hard blocks (branch-protection, merge-finalization,
secret-echo-guard) and reminders (terraform-import-safety, which can't get the
state creds to hard-block); the **reactions** are `PostToolUse` on edits
(format / lint / regenerate, after the fact); the **injectors** are
`SessionStart` (adding context the model would otherwise lack). None of them
*enforces* on its own — each is a deterministic backstop for a rule the model
is also told to follow.

## See also — adjacent, out of scope

- **Permission modes & auto mode** — the rule system a `PreToolUse` hook
  composes with (deny-first, and the auto-mode classifier); the full
  resolution order lives there, not here. See [Permission Modes & Auto
  Mode][perm-doc].
- **Loops & workflows** — hooks are the *reactive* automation family; loops
  and workflows are the *proactive* one. See [Loops & Workflows][loops].

## Resources

Distilled from the official Claude Code documentation:

- [Hooks guide][hooks-guide] — the events, `settings.json` structure,
  matchers, the `if` filter, hook types, and worked examples
- [Hooks reference][hooks-ref] — the complete event set, stdin schema per
  event, exit-code behavior, and the `hookSpecificOutput` fields
- [Settings][settings] — where hook configs live and how scopes combine

[hooks-guide]: https://code.claude.com/docs/en/hooks-guide
[hooks-ref]: https://code.claude.com/docs/en/hooks
[settings]: https://code.claude.com/docs/en/settings
[perm-doc]: PERMISSION-MODES.md
[loops]: LOOPS-WORKFLOWS.md
