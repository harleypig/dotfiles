# Claude Code Permission Modes & Auto Mode

Every tool call Claude Code makes — editing a file, running a shell command,
fetching a URL — passes through a **permission** decision: allow it, ask you,
or deny it. Two things shape that decision: the **permission mode** (the broad
posture of the session, from "ask me about everything" to "run unattended")
and the **permission rules** (`allow` / `ask` / `deny` patterns in
`settings.json`). **Auto mode** is the most permissive mode, backed by a
**classifier** that reviews each action and blocks the destructive or
escalating ones so unattended work stays safe. This doc explains the modes,
the rule system, how auto mode's classifier decides, how hooks fit in, and the
exact order in which all of these resolve a single tool call.

## ELI5

*Set the posture of the session:*

- **default (Manual)** — Claude asks before the first use of each tool.
- **`acceptEdits`** — Claude edits files (and runs safe filesystem commands)
  without asking; other actions still prompt.
- **plan mode** — Claude may read and explore but **not** change anything; it
  proposes a plan instead.
- **auto mode** — Claude runs without routine prompts; a separate classifier
  blocks anything destructive or out-of-scope.
- **`bypassPermissions`** — Claude skips permission prompts entirely (except
  explicit `ask` rules). Use with care.
- **`dontAsk`** — the inverse: deny anything not explicitly pre-approved.

*Decide per tool, in `settings.json`:*

- **`allow` rule** — let this tool/command run without a prompt.
- **`ask` rule** — always prompt for this one.
- **`deny` rule** — never allow this one (the strongest; nothing overrides it).
- **matcher** — the pattern a rule matches, e.g. `Bash(npm run test:*)`,
  `Read(.env)`, `WebFetch(domain:example.com)`.

*Switch it:*

- **`Shift+Tab`** — cycle default → `acceptEdits` → plan during a session.
- **`--permission-mode <mode>`** — start in a mode.
- **`defaultMode` (settings)** — the mode a session starts in.

### Best practices

- **Reach for the least-powerful mode that unblocks you.** Stay in default;
  step up to `acceptEdits` for a big edit session, auto for unattended work —
  not `bypassPermissions` unless you truly mean "no guardrails."
- **Use `deny` rules for hard limits, not conversation.** Telling Claude
  "don't push" holds only until the context compacts; a `deny` rule is
  permanent and cannot be overridden by a mode, an `allow` rule, or a hook.
- **Keep `allow` rules narrow.** `Bash(npm test)` is safe to carry into auto
  mode; a blanket `Bash(*)` is dropped there (it grants arbitrary execution).
- **Don't grant a repo auto mode.** `defaultMode: auto` is ignored from a
  project's `.claude/settings.json` — set it in your user settings.
- **Never commit `bypassPermissions` as a project default.** It disables the
  guardrails for anyone who opens the repo.

## Overview

The decision has two layers. The **mode** is the session-wide default — what
happens to a tool call that no rule mentions. The **rules** are per-tool
overrides that fire regardless of mode (with one exception: auto mode's
classifier can override a *broad* allow rule). A tool call is resolved by
checking rules first (deny, then ask, then allow), and falling back to the
mode only when no rule matches.

The single distinction to remember: **a `deny` rule is an absolute floor —
nothing above it (a mode, an `allow` rule, or a hook) can lift it — while a
mode is only the fallback for everything the rules didn't speak to.**

### At a glance

| Mode | Reads | File edits | Other tools | Fallback when no rule matches |
|------|-------|-----------|-------------|-------------------------------|
| **default** (`manual`) | auto | prompt | prompt | prompt on first use of each tool |
| **`acceptEdits`** | auto | auto | prompt | auto-approve edits + safe Bash; else prompt |
| **plan** | auto | never | never | read/explore only; propose, don't act |
| **auto** | auto | auto (cwd) | classifier | route the action through the classifier |
| **`dontAsk`** | auto | deny | deny | deny unless an `allow` rule pre-approved it |
| **`bypassPermissions`** | auto | auto | auto | allow everything except explicit `ask` rules |

In table order: **default** prompts the first time Claude reaches for each
tool; **`acceptEdits`** takes file edits and common filesystem commands off
your plate but still asks for the rest; **plan** is read-only by design —
Claude explores and proposes but changes nothing; **auto** removes the prompts
and leans on the classifier to stop the dangerous ones; **`dontAsk`** is the
locked-down inverse, running only what you allowlisted; **`bypassPermissions`**
drops the gate entirely. Writes to **protected paths** (`.git`, `.claude`,
shell rc files, and ~30 others) are the exception every mode honors — never
auto-approved (routed to the classifier in auto mode, denied in `dontAsk`).

## The permission modes

The mode sets the session's default posture. Three modes are in the
`Shift+Tab` cycle (default, `acceptEdits`, plan); auto and `bypassPermissions`
join the cycle only once enabled; `dontAsk` is set via config, not the cycle.

### default (Manual)

The safe baseline: Claude reads freely but prompts before the first use of any
tool that changes something, and before each command it hasn't been allowed.
An `allow` rule is how you retire the prompts you're tired of.

### `acceptEdits`

Auto-approves file edits and a set of common filesystem Bash commands (so an
edit-heavy session stops interrupting you), while still prompting for
everything else — network calls, arbitrary shell, and so on. Protected-path
writes still prompt.

### plan mode

Read-and-explore only: Claude investigates and returns a proposed plan but
makes **no** edits and runs **no** mutating tools. The mode for "tell me what
you'd do" before you let it act. (This is the mode the **plan-review**
workflow leans on.)

### auto mode

The unattended mode — no routine prompts, with a classifier as the safety net.
Covered in depth in [Auto mode and the classifier](#auto-mode-and-the-classifier)
below.

### `bypassPermissions` and `dontAsk`

Two opposite extremes. **`bypassPermissions`** skips permission checks entirely
(only explicit `ask` rules still prompt) — maximum trust, use only in a
throwaway sandbox. **`dontAsk`** is the inverse: it denies anything not covered
by an `allow` rule, so nothing runs unless you pre-approved it — maximum
restriction, useful for a tightly-scoped agent.

## Permission rules

Rules live under `permissions` in `settings.json` and decide individual tool
calls regardless of mode:

```json
{
  "permissions": {
    "allow": ["Bash(npm run test:*)", "Read(~/.zshrc)"],
    "ask":   ["Bash(git push:*)"],
    "deny":  ["Bash(curl:*)", "Read(.env)", "Bash(rm -rf:*)"]
  }
}
```

### Matcher syntax

A matcher is `ToolName` (every use of the tool) or `ToolName(specifier)` (a
subset). The specifier's shape depends on the tool:

- **`Bash(cmd ...)`** — a command prefix. The space before `*` matters:
  `Bash(ls *)` matches `ls -la` but **not** `lsof`; `Bash(ls*)` matches both.
  Compound commands (`&&`, `||`, `;`, `|`) must match **each** subcommand
  independently; leading `timeout` / `nice` / `nohup` wrappers are ignored.
- **`Read(...)` / `Edit(...)`** — a gitignore-style path pattern (`*`, `**`,
  `~`, `/`).
- **`WebFetch(domain:example.com)`** — a host.
- **`mcp__<server>__<tool>`** — a specific MCP tool.

Read-only Bash commands (`ls`, `cat`, `grep`, `git status`, …) never prompt,
in any mode.

### How rules resolve — deny, then ask, then allow

Within a scope, rules are checked in a fixed order and the **first match
wins**: **deny → ask → allow**. Specificity does not reorder them — a broad
`deny` beats a narrow `allow`:

- A `deny` of `Bash(aws:*)` blocks even a call that also matches an
  `allow` of `Bash(aws s3 ls)` — **a deny rule can't carry allowlist
  exceptions.**
- An `ask` rule prompts even when a more specific `allow` also matches.

Across the settings **scopes**, deny wins everywhere: if any scope denies a
tool, no other scope can allow it. Scope precedence (highest first): managed
settings → command-line flags → local project (`.claude/settings.local.json`)
→ shared project (`.claude/settings.json`) → user (`~/.claude/settings.json`).

### Protected paths

Writes to `.git`, `.claude`, `.vscode`, `.idea`, shell rc files (`.bashrc`,
`.zshrc`), `.npmrc`, `.pre-commit-config.yaml`, and ~30 other system/config
files are **never auto-approved** — they prompt in default / `acceptEdits` /
plan, route to the classifier in auto, and are denied in `dontAsk`. This is
why the agent-config's own edit-time hook can safely assume such files can't
be silently changed.

## Auto mode and the classifier

Auto mode lets Claude execute without routine prompts, but a **separate
classifier model** reviews each action first and blocks "anything that
escalates beyond your request, targets unrecognized infrastructure, or appears
driven by hostile content Claude read." It is a **gate, not a task** — the
thing that makes a `/loop` or a `/schedule` routine run unattended instead of
stopping to ask on every call.

### Availability

Auto mode has real prerequisites: a recent model (on the Anthropic API, a
current Opus/Sonnet; on Bedrock/Vertex/Foundry a smaller supported set, plus
`CLAUDE_CODE_ENABLE_AUTO_MODE=1`), and — on Team/Enterprise — an Owner must
enable it. Crucially, **a repo cannot grant itself auto mode**: `defaultMode:
auto` in a project's `.claude/settings.json` is ignored (current versions);
it must come from your user settings.

### How the classifier decides

Each action runs through a fixed order, first match wins:

1. Actions matching your `allow` / `deny` rules resolve immediately — **except
   writes to protected paths, which go to the classifier even with an `allow`
   match.**
2. Read-only actions and file edits inside your working directory are
   auto-approved (again, except protected-path writes).
3. Everything else goes to the **classifier**. If it blocks, Claude gets the
   reason and tries another approach.

**Blocked by default** (a sample — not the full list): `curl … | bash`
download-and-run, pushing secrets to external endpoints, mass cloud-storage
deletion, IAM / permission changes, force-push, `git reset --hard` /
`git clean` and other uncommitted-work destroyers, `terraform destroy`,
merging a PR without human approval, and printing live credentials to the
transcript. **Allowed by default:** local file ops in the working directory,
installing from a lockfile, read-only HTTP, and pushing to the branch you
started on or one Claude created this session.

**Narrowing it to your world.** Repeated false blocks usually mean the
classifier lacks context about your infrastructure; declare trusted repos /
buckets / services (and sensitive targets) via `autoMode.environment` in
managed or user settings. The full default ruleset is printable with
`claude auto-mode defaults`.

### Two behaviors worth knowing

- **Broad allow rules are dropped in auto mode.** On entering auto, blanket
  `Bash(*)` / `PowerShell(*)`, wildcarded interpreters (`Bash(python*)`),
  package-manager run commands, and `Agent` allow rules are suspended (they'd
  grant arbitrary execution); narrow rules like `Bash(npm test)` carry over.
  They're restored when you leave auto mode.
- **Stated boundaries act as blocks.** If you say "don't push" or "wait until
  I review," the classifier treats that as a block signal — but only until the
  context is compacted or you lift it. For a *durable* limit, use a `deny`
  rule.
- **Fallback:** 3 consecutive (or 20 total) classifier denies pause auto mode
  and resume prompting; approving one resumes it.

## Bringing it together — how one tool call resolves

Hooks add one more voice. A `PreToolUse` hook can return a `permissionDecision`
of `allow` / `deny` / `ask` (or defer to the normal rules), and it can read the
current `permission_mode` to adjust what it does. But a hook **does not** beat
the rule system: `deny` and `ask` rules are evaluated regardless of what a hook
returns, preserving deny-first. The one way a hook takes precedence is a hard
block — **exit code 2 stops the call before the rules are even checked.**

So the full resolution order for a single tool call, highest authority first:

1. **A `PreToolUse` hook that exits 2** — hard block, before anything else.
2. **`deny` rules** (managed → CLI → local → project → user). Any match blocks.
3. **`ask` rules** (same scope order). Any match prompts.
4. **`allow` rules** (same scope order). Any match allows — *except* in auto
   mode, where a broad allow is dropped and the action still hits the
   classifier.
5. **A hook's `permissionDecision`** (`allow` / `deny` / `ask`), if no exit-2
   and no rule matched.
6. **The permission mode's default** — prompt (default), auto-approve edits
   (`acceptEdits`), refuse edits (plan), the classifier (auto), deny
   (`dontAsk`), or allow (`bypassPermissions`).

Read it top-down: the first layer that speaks decides. A `deny` rule you set
is a floor nothing below it can raise; the mode only gets a say about calls
every rule stayed silent on.

## See also — adjacent, out of scope

- **Loops & workflows** — auto mode is what lets those run unattended; the
  when-to-iterate-vs-orchestrate model lives there, not here. See
  [Loops & Workflows][loops-workflows].
- **Hooks** — the full event model (beyond the `PreToolUse` permission
  interaction above) — matchers, exit codes, the lifecycle events — is its own
  topic. See the [hooks reference][hooks] (a dedicated understanding-doc is
  queued).

## Resources

Distilled from the official Claude Code documentation:

- [Permission modes][permission-modes] — the modes, `Shift+Tab` / startup /
  `defaultMode` entry, protected paths, and auto mode + the classifier
- [Permissions][permissions] — the `allow` / `ask` / `deny` rule system,
  matcher syntax, and deny-first precedence across scopes
- [Hooks][hooks] — `PreToolUse` `permissionDecision`, reading
  `permission_mode`, and how a hook composes with the rules
- [Settings][settings] — the `settings.json` structure and scope precedence

[permission-modes]: https://code.claude.com/docs/en/permission-modes.md
[permissions]: https://code.claude.com/docs/en/permissions.md
[hooks]: https://code.claude.com/docs/en/hooks.md
[settings]: https://code.claude.com/docs/en/settings.md
[loops-workflows]: LOOPS-WORKFLOWS.md
