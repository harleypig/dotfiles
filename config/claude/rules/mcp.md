# MCP (Model Context Protocol) Rules

**Version:** v1.0.0

How this user's environments use MCP servers, and the standing rule that
MCP is a **second-class** capability the agent must never depend on.

## How MCP servers are configured (Claude Code)

- **Plugins provide most MCP servers.** Enabled plugins (`enabledPlugins`
  in `~/.claude/settings.json`) each may bundle a `.mcp.json` under
  `~/.claude/plugins/`. There is **no hand-maintained global `mcp.json`** —
  if you can't find one, that is why. Auditing plugins audits the MCP
  surface (see `TODO.md`).
- **Hand-registered servers** use
  `claude mcp add <name> [--scope ...] -- <cmd>`, stored by scope:
  - **local** (default) — `~/.claude.json`, keyed to one project, **not
    committed**. This is the idiomatic **per-repo opt-in**.
  - **project** — committed `.mcp.json` at the repo root; travels with the
    repo to anyone who clones it.
  - **user** — `~/.claude.json` top level; active for **all** projects.
- **Precedence** (highest first): local > project > user > plugin >
  connectors. The winning scope's entry is used whole — fields are not
  merged across scopes.
- A Cursor `mcp.json` uses the same `{"mcpServers": {...}}` shape, so an
  entry ports directly — but choose a scope deliberately; do not leave a
  copy at user scope (that makes it always-on everywhere).

## MCP is second-class — the CLI is the engine

- **Never depend on an MCP server in a rule or skill.** No server is
  guaranteed present (other hosts, no docker, no token, mid-session
  disconnects). A documented workflow must work with the MCP server
  **absent**.
- For GitHub specifically the **`gh` CLI is canonical** (see `gh.md`,
  `git.md`, `github-actions.md`, and the `ship-pr` /
  `git-worktree-workflow` skills). MCP github tools are an **opportunistic
  read convenience** used only when a server happens to be connected —
  never the primary path, and never a fallback chain that ends at
  unrestricted `gh` (that buys the cost of both lanes and the safety of
  neither).
- If a **hard capability boundary** is the goal (an unattended or
  less-trusted agent that must not write), do the opposite of fallback:
  run a **read-only, tool-restricted MCP server as the only access and
  remove the CLI + token** from that agent's environment.

## Per-repo opt-in pattern

`bin/mymcp` is the centralized "define once" wrapper for this user's local
MCP servers — the real logic (docker invocation, token file, flags) lives
there. A repo opts in by registering a thin local-scope switch pointing at
it:

```bash
claude mcp add github -- mymcp github   # --scope local default; not committed
```

Per-server tokens are read directly from `private_dotfiles/api-key/` by the
wrapper, **not** from `GH_TOKEN` / `GITHUB_TOKEN` (see `gh.md` and the
`api-key/README.md`).

## Agent Behavior

- Treat MCP as optional: prefer the CLI (`gh`, etc.) for any documented
  workflow; use MCP tools only as a convenience when one is present.
- Never write a rule/skill step that fails if an MCP server is missing.
- When adding a personal MCP server, default to **local scope** in the
  specific repo; use project scope only to share it via the repo itself.
- Plugin = MCP surface: when auditing or removing plugins, account for any
  MCP server they bundle (see the plugin audit in `TODO.md`).
