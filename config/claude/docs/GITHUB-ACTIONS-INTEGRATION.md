# Claude Code in GitHub Actions

You can run **Claude itself inside GitHub Actions** — not your repo's own CI,
but Claude as a bot that reacts to a `@claude` mention in an issue or PR, or
runs a prompt automatically on an event. It's the official
**`claude-code-action`** plus the **Claude GitHub App**: mention `@claude` and
it analyzes the thread, answers, implements a change, and opens a PR; or wire
it to run a prompt on every PR (a code review) or on a schedule. It's the same
Claude agent and the same `CLAUDE.md`/`.claude/` rules as the local CLI, just
**event-driven and running on GitHub's runners** instead of at your keyboard.
This doc covers the two modes, setup, triggers, configuration (`claude_args`,
permissions), and the security model. (Your repo's *own* CI — the workflows
Claude helps you author and watches go green — is a different topic, covered
by the `github-actions` rule.)

## ELI5

*The two ways it runs:*

- **interactive (tag) mode** — someone writes `@claude …` in an issue / PR
  comment; Claude reads the thread and responds (answer, or implement + PR).
- **automation (prompt) mode** — a workflow gives the action a `prompt` and a
  non-mention trigger (PR opened, a label, a schedule); Claude runs it
  immediately, no mention needed.
- **mode is auto-detected** — give a `prompt` → automation; omit it → tag.

*Set it up:*

- **`/install-github-app`** — the interactive installer: installs the GitHub
  App, adds the workflow, and stores the API key secret (repo admin only).
- **the secret** — `ANTHROPIC_API_KEY` *or* a long-lived
  `CLAUDE_CODE_OAUTH_TOKEN`, stored as a GitHub Actions **secret** (never in
  the YAML).

*Tune it:*

- **`claude_args`** — pass any Claude CLI flag (`--model`, `--max-turns`,
  `--allowedTools`, `--permission-mode`).
- **`permissions:`** — the workflow's GitHub token scopes (contents /
  pull-requests / issues), least-privilege.

### Best practices

- **Least privilege, twice.** Scope the workflow's `permissions:` to only
  what the task needs (a review job may not need `contents: write`), and
  restrict Claude's tools with `--allowedTools` in `claude_args`.
- **Cap the run.** Set `--max-turns` and a job `timeout-minutes:` so a
  runaway can't burn tokens or minutes; consider `--max-budget-usd`.
- **Gate who can trigger it.** A bare `@claude` mention runs for *any*
  commenter — add an `if:` permission check or a maintainer-only label
  trigger for anything that writes.
- **Review before merge.** Treat a Claude PR like any PR — it goes through
  the same required checks and human review; don't auto-merge it.
- **Use a long-lived token for CI.** `CLAUDE_CODE_OAUTH_TOKEN`
  (`claude setup-token`, ~1yr) suits non-interactive runs; see the
  claude-code-auth rule.

## Overview

The action wraps the same headless Claude agent (see the headless topic) in a
GitHub-event harness. The one distinction that organizes everything:
**interactive vs automation mode**, and the action **auto-detects** which from
your config — if you pass a `prompt`, it runs that immediately (automation);
if you don't, it waits for a `@claude` mention and responds to the thread
(interactive). Everything else — triggers, `claude_args`, permissions — is
shared plumbing.

### At a glance

| Mode | Trigger | What Claude does |
|------|---------|------------------|
| **Interactive (tag)** | `@claude …` in an issue / PR / review comment | reads the thread; answers, or implements the ask and opens a PR |
| **Automation (prompt)** | a non-mention event (PR opened/synced, a label, a schedule) **+** a `prompt` input | runs the prompt right away — e.g. a code review on every PR |

In table order: **interactive** is the human-in-the-loop bot — you mention it
and it works the conversation; **automation** is the unattended job — an event
fires and a fixed `prompt` (often a skill invocation) runs with no mention.
Same action, chosen by whether a `prompt` is present.

## Setup

The quick path is **`/install-github-app`** from the local CLI: it installs
the Claude GitHub App on the repo, walks you through adding the workflow file,
and helps store the API-key secret (you must be a repo admin). Manually, the
three steps are: install the app at `github.com/apps/claude` (granting
Contents / Issues / Pull requests read-write), add the secret under **Settings
→ Secrets and variables → Actions**, and copy a workflow into
`.github/workflows/` (e.g. `claude.yml`). A minimal tag-mode workflow:

```yaml
name: Claude Code
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
jobs:
  claude:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

The secret can be an `ANTHROPIC_API_KEY` (Console) or a long-lived
`CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token` — the latter is what this
user's setup prefers for non-interactive auth (see the claude-code-auth rule).

## Triggers and modes

**Interactive (tag).** The default: subscribe to `issue_comment`,
`pull_request_review_comment` (and `issues`) `created` events, and Claude
responds when a comment contains the trigger phrase (`@claude`, or a custom
`trigger_phrase`). No `prompt` input.

**Automation (prompt).** Give the action a `prompt` and a non-mention trigger,
and it runs immediately — no mention required. Common shapes:

```yaml
# Review every PR
on:
  pull_request:
    types: [opened, synchronize]
# ...
    with:
      anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
      prompt: "/code-review:code-review ..."
```

or a `schedule:` cron for a daily report, or `issues: [labeled]` so only a
maintainer-applied label kicks it off. The `prompt` accepts a **skill
invocation** as well as plain text — a repo skill (after `actions/checkout`,
pass `/skill-name`) or a plugin skill (`plugins:` + `plugin_marketplaces:`
inputs, pass `/plugin:skill`).

## Configuration

The v1 action is deliberately thin — most tuning goes through **`claude_args`**,
which forwards any Claude CLI flag:

- **`--model <name>`** — pick the model.
- **`--max-turns <N>`** — cap agentic iterations (runaway guard).
- **`--allowedTools` / `--disallowedTools`** — tool allow/deny lists, the CI
  equivalent of permission rules (see the permission-modes doc).
- **`--permission-mode <mode>`** — e.g. `plan` to have Claude propose without
  editing; the same modes as the local CLI.
- **`--max-budget-usd <n>`** — stop after a dollar cap.

```yaml
with:
  anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
  claude_args: "--max-turns 10 --model claude-sonnet-5 --permission-mode plan"
```

Other inputs: `trigger_phrase` (default `@claude`), `github_token`,
`plugins` / `plugin_marketplaces`, and `use_bedrock` / `use_vertex` for a
cloud-provider backend. The workflow's own `permissions:` block scopes the
GitHub token Claude acts with — grant only `contents` / `pull-requests` /
`issues` (and `id-token: write` only for Bedrock/Vertex OIDC) as the task
needs. Claude reads the repo's `CLAUDE.md` / `.claude/` rules in CI exactly as
it does locally.

> **Note — v0 → v1.** The v1 action dropped the `mode:` input (now
> auto-detected), renamed `direct_prompt` → `prompt`, and moved `max_turns` /
> `model` / `custom_instructions` into `claude_args`. Pin `@v1`, and migrate
> any beta workflow.

## Security

The action runs on **your** GitHub-hosted runners with the repo's secrets and
`GITHUB_TOKEN`, so the guardrails are the usual CI ones, applied deliberately:

- **Secrets, never literals** — the API key / OAuth token lives in a GitHub
  Actions secret, referenced as `${{ secrets.… }}`; never commit it.
- **Scope the token** — the `permissions:` block is least-privilege; a
  read-only review job shouldn't have `contents: write`.
- **Restrict the tools** — `--allowedTools` keeps Claude to what the job
  needs, not arbitrary shell.
- **Gate the trigger** — a bare `@claude` runs for any commenter; for
  write-capable workflows, add an `if:` actor/permission check or a
  maintainer-only label trigger.
- **Human review stays the gate** — a Claude PR merges through the repo's
  normal required checks and review, not on its own.

Cost is per-token (the Claude API) **plus** GitHub Actions minutes; keep both
down with targeted prompts, `--max-turns`, `timeout-minutes:`, and concurrency
limits.

## Hosted Code Review (Team/Enterprise)

Distinct from everything above, Anthropic also runs a hosted
**[Code Review][code-review-product]** product — a managed multi-agent
service that reviews a PR automatically once an admin enables it and installs
its GitHub App. It is **not** the `claude-code-action` this doc covers, and
not a slash command: it is a separate, server-side offering in **research
preview for Team and Enterprise** plans.

On each PR it:

- **Fans out parallel agents** — dispatches a team of agents that hunt for
  bugs concurrently, and **scales with the PR**: a large or complex change
  draws more agents and a deeper read, a trivial one a lightweight pass.
- **Verifies before reporting** — a verification pass filters out false
  positives (Anthropic reports under 1% of findings marked incorrect by
  engineers), then **ranks the surviving bugs by severity**.
- **Posts one overview plus inline** — results land as a single high-signal
  overview comment plus in-line annotations on the specific lines.
- **Surfaces, never approves** — it flags issues for a human; it **won't
  approve a PR**, which stays a human call.

Cost is **per-token, roughly $15–25 per PR**, scaling with size and
complexity; admins set monthly org caps, toggle it per repository, and see
analytics.

Don't confuse it with three adjacent things:

- The local **`/code-review` and `/security-review` slash commands** run *in
  your session* against the working diff, invoked by the developer — not a
  hosted service reacting to a PR.
- **Automation-mode `/code-review` on every PR** (above) is *this* action
  running a slash-command prompt on a GitHub event — still a workflow you
  author, not the managed product.
- This repo's **QA "Code review" gate** (`qa.md` dimension 14) is the human
  peer-review requirement — a gate, not a tool.

## See also — adjacent, out of scope

- **Your repo's own CI** — the workflows Claude helps you write and watches to
  green (a different thing from Claude-as-a-bot). See
  [github-actions][gha-rule].
- **Headless / programmatic** — the action is a CI wrapper around headless
  Claude (`claude -p`); the general script/CI surface is its own topic. See
  the headless doc (queued).
- **Permission modes & auto mode** — `--permission-mode` / `--allowedTools`
  in `claude_args` are the CI face of the local permission system. See
  [Permission Modes & Auto Mode][perm-doc].
- **Auth for CI** — the long-lived `CLAUDE_CODE_OAUTH_TOKEN` this setup uses
  for non-interactive runs. See [claude-code-auth][auth-rule].

## Resources

Distilled from the official Claude Code documentation:

- [Claude Code GitHub Actions][gha] — setup, `@claude` triggers, the v1
  inputs (`prompt` / `claude_args`), permissions, and security guidance
- [claude-code-action repository][action-repo] — the action source, example
  workflows, and input reference
- [CLI reference][cli-ref] — the flags `claude_args` forwards
  (`--max-turns`, `--allowedTools`, `--permission-mode`, `--max-budget-usd`)

[gha]: https://code.claude.com/docs/en/github-actions
[action-repo]: https://github.com/anthropics/claude-code-action
[cli-ref]: https://code.claude.com/docs/en/cli-reference
[code-review-product]: https://claude.com/blog/code-review
[perm-doc]: PERMISSION-MODES.md
[gha-rule]: ../rules/github-actions.md
[auth-rule]: ../rules/claude-code-auth.md
