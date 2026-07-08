# Claude Code Headless & Programmatic

Most of the time you drive Claude Code interactively in a terminal. But you
can also run it **non-interactively** — from a shell script, a pipe, a CI job,
or embedded in your own program. The command-line door is **`claude -p`**
("print" mode): give it a prompt, it runs to completion, prints the result,
and exits — so a script can call Claude the way it calls any other CLI. Ask
for **`--output-format json`** and you get the result plus metadata (session
id, cost, turns) a script can parse; **`--resume`** chains turns across
invocations. For a program that *embeds* Claude rather than shelling out, the
**Agent SDK** (TypeScript / Python) exposes the same agent as a `query()`
call. This doc covers print mode, output formats, session continuity, the
scripting flags that matter, and when to reach for the SDK instead — the
surface for driving Claude from code. (The GitHub Actions integration is one
packaged consumer of this; loops/workflows are the *interactive* automation
family.)

## ELI5

*Run it from a script:*

- **`claude -p "…"`** — run once, print the answer, exit; pipe input in
  (`cat file | claude -p "summarize"`).
- **`--output-format json`** — get a parseable result object (text + session
  id + cost + turns) instead of plain text; `stream-json` streams events.

*Chain and control:*

- **`-c` / `--resume <id>`** — continue the last session, or a specific one,
  across separate `claude -p` calls.
- **`--allowedTools` / `--permission-mode` / `--max-turns` /
  `--max-budget-usd`** — pre-authorize tools and cap the run (there's no human
  to prompt in headless).

*Embed it in a program:*

- **Agent SDK** — `query(prompt, options)` in TypeScript or Python; the same
  agent, as a library, with custom tools / hooks / subagents.

### Best practices

- **Pre-authorize, don't hope.** Headless has no one to answer a permission
  prompt — a tool call that would prompt is effectively blocked unless
  `--allowedTools` / `--permission-mode` covers it. Grant the minimum; reserve
  `--dangerously-skip-permissions` for a trusted sandbox.
- **Always cap.** `--max-turns` and `--max-budget-usd` (both exit non-zero on
  overflow) keep an unattended run from spiraling.
- **Parse JSON, not text.** For anything a script consumes, use
  `--output-format json` and read fields — text output is for humans.
- **Capture the session id to chain.** Read `session_id` from the JSON result
  and pass it to `--resume` for the next turn, rather than one giant prompt.
- **SDK for an app, `-p` for a script.** Shell out with `claude -p` for
  one-offs and pipelines; reach for the Agent SDK when Claude lives inside a
  long-running program with its own tools and control flow.

## Overview

Two programmatic surfaces, one agent underneath. **`claude -p`** is the CLI
face — you compose it like any Unix tool (stdin in, stdout out, an exit code),
which makes it the natural fit for shell scripts, pipelines, and CI. The
**Agent SDK** is the library face — you `import` it and call `query()`, keeping
Claude *inside* your process with programmatic access to its options, tools,
hooks, and streamed messages.

The distinction to remember: **`claude -p` composes with the shell; the SDK
composes with your code.** Pick by where the orchestration lives — a bash
script (CLI) or a Python/TypeScript program (SDK).

### At a glance

| Surface | Reach for it when |
|---------|-------------------|
| **`claude -p "…"`** | a shell script / pipeline / one-off needs an answer |
| **`--output-format json`** | the caller must parse the result (session id, cost, turns) |
| **`-c` / `--resume <id>`** | chaining turns across separate invocations |
| **Agent SDK (`query()`)** | embedding Claude in a TS/Python app with custom tools/hooks |

In table order: **`claude -p`** is the scripting entry point (stdin/stdout/exit
code); **`--output-format json`** turns its output into structured data;
**`--resume`** stitches invocations into a conversation; the **Agent SDK** is
for when the program, not the shell, is in charge.

## `claude -p` — print mode

`claude -p "prompt"` (or `--print`) runs Claude non-interactively: it executes
the turn, prints the result, and exits — no TUI. It reads a piped stdin, so it
slots into a pipeline:

```bash
cat error.log | claude -p "what's the root cause here?"
git diff | claude -p "write a conventional-commit message for this diff"
```

Stdin has a size cap (~10MB), and `--bare` skips context auto-discovery
(`CLAUDE.md`, etc.) for a lean CI/script run. The exit code is the script's
signal: `0` on success, non-zero on error or a hit limit (see *Scripting
controls*).

## Output formats

`--output-format` controls what lands on stdout:

- **`text`** (default) — just the final answer, for a human or a simple pipe.
- **`json`** — a single result object: the `result` text plus metadata —
  `session_id`, `total_cost_usd`, `num_turns`, duration. Parse it with `jq`.
- **`stream-json`** — a JSONL stream of events (init, messages, tool calls,
  result) as they happen, for live processing.

```bash
claude -p "list the repo's test files" --output-format json | jq -r '.result'
```

`--input-format` accepts `text` or `stream-json` (for feeding a message
stream). For a schema-constrained result, `--json-schema` returns a validated
`structured_output` field.

## Session continuity

Each headless call is its own session unless you chain it:

- **`-c` / `--continue`** — resume the **most recent** session in this
  project/worktree.
- **`--resume <session-id | name>` / `-r`** — resume a **specific** one.

The scripting pattern is: run with `--output-format json`, capture the
`session_id`, and pass it to the next call's `--resume` — building a
multi-turn conversation across separate invocations:

```bash
sid=$(claude -p "start reviewing src/" --output-format json | jq -r '.session_id')
claude -p --resume "$sid" "now check the tests"
```

`--fork-session` branches from an existing session without modifying it;
`--no-session-persistence` (print mode) runs without saving at all.

## Scripting controls

Because there's **no human to answer a permission prompt**, headless runs must
pre-authorize what they need, and should cap themselves:

- **`--allowedTools` / `--disallowedTools`** — the allow/deny lists (prefix
  matching, `Bash(git diff *)`); a tool that isn't covered and would prompt is
  effectively blocked. See the permission-modes doc.
- **`--permission-mode <mode>`** — e.g. `plan` (propose, don't act) or `auto`;
  `--dangerously-skip-permissions` skips checks entirely (sandbox only).
- **`--max-turns <N>`** and **`--max-budget-usd <n>`** — hard caps; the run
  exits non-zero when it hits one.
- **`--model <name>`** (aliases `sonnet` / `opus` / `haiku` / `fable`),
  **`--effort <level>`**, **`--append-system-prompt` / `--system-prompt`**,
  **`--add-dir`**, **`--mcp-config`** — model, reasoning effort, extra
  instructions, extra context roots, and MCP servers.

Exit codes are the contract: `0` = success, non-zero = an error or a reached
limit — so a script can branch on `$?`. For non-interactive auth this user's
setup uses the long-lived `CLAUDE_CODE_OAUTH_TOKEN` (see the claude-code-auth
rule).

## The Agent SDK

When Claude lives **inside** a program rather than being shelled out to, use
the **Agent SDK** — TypeScript (`@anthropic-ai/claude-agent-sdk`) or Python
(`claude-agent-sdk`, 3.10+). The entry point is `query(prompt, options)`,
which returns an async stream of messages (system/init, assistant, tool calls,
result). Options mirror the CLI: `allowed_tools`, `permission_mode`,
`max_turns`, `model`, plus programmatic `hooks`, `agents` (subagents), and
`mcp_servers`. Session continuity works the same way — read the `session_id`
off the init message and pass it back as `resume` on the next `query()`.

Choose by what you're building: **`claude -p`** for scripts and pipelines
(the shell orchestrates); the **Agent SDK** for an application that embeds the
agent with its own tools, permission callbacks, and control flow. (Both run
the agent in *your* environment — distinct from a hosted/managed agent API.)

## See also — adjacent, out of scope

- **GitHub Actions integration** — a packaged consumer of headless Claude
  (the action wraps `claude -p` behind GitHub events). See
  [Claude Code in GitHub Actions][gha-doc].
- **Permission modes & auto mode** — the rule/mode system the scripting flags
  (`--allowedTools`, `--permission-mode`) drive; in headless there's no prompt
  to fall back on. See [Permission Modes & Auto Mode][perm-doc].
- **Loops & workflows** — the *interactive* automation family (repetition and
  orchestration inside a session); headless is the *external* driver. See
  [Loops & Workflows][loops].

## Resources

Distilled from the official Claude Code documentation:

- [Run Claude Code programmatically][headless] — `claude -p`, piping, output
  formats, and the scripting patterns
- [CLI reference][cli-ref] — the full flag set (`--output-format`,
  `--max-turns`, `--allowedTools`, `--permission-mode`, `--max-budget-usd`, …)
- [Manage sessions][sessions] — `--continue` / `--resume`, session scoping,
  fork and no-persistence
- [Agent SDK][agent-sdk] — the TypeScript / Python library, `query()`, and its
  options

[headless]: https://code.claude.com/docs/en/headless
[cli-ref]: https://code.claude.com/docs/en/cli-reference
[sessions]: https://code.claude.com/docs/en/sessions
[agent-sdk]: https://code.claude.com/docs/en/agent-sdk
[perm-doc]: PERMISSION-MODES.md
[gha-doc]: GITHUB-ACTIONS-INTEGRATION.md
[loops]: LOOPS-WORKFLOWS.md
