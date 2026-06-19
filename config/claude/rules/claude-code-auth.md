# Claude Code Auth Rules

**Version:** v1.0.0

How **this user** authenticates Claude Code (the CLI), the precedence between
methods, and the standing rule that keeps the Max subscription working — the
parallel to `gh.md`'s dual-credential scheme, for Claude Code itself.

## The methods (this setup uses three of six)

Claude Code resolves auth in a fixed **precedence order** (highest wins). This
user relies on three of the six methods:

| # | Method | What it is | Lifetime |
|---|--------|------------|----------|
| 3 | **`ANTHROPIC_API_KEY`** | Console pay-per-use key (`X-Api-Key`). Works for terminal CLI; **overrides** the subscription once approved. | API-key validity |
| 5 | **`CLAUDE_CODE_OAUTH_TOKEN`** | Long-lived token from `claude setup-token` (Pro/Max/Team/Enterprise). For CI / non-interactive. | **~1 year** |
| 6 | **Subscription OAuth** (`/login`) | Interactive Max/Pro browser login — the **default**. Auto-refreshes via a stored refresh token. | short access token, auto-refreshed |

Full precedence (highest → lowest), for completeness:

1. Cloud provider — `CLAUDE_CODE_USE_BEDROCK` / `_VERTEX` / `_FOUNDRY`
2. `ANTHROPIC_AUTH_TOKEN` — gateway/proxy bearer token
3. `ANTHROPIC_API_KEY` — Console key (above)
4. `apiKeyHelper` — a settings script returning credentials dynamically
5. `CLAUDE_CODE_OAUTH_TOKEN` — long-lived (above)
6. Subscription OAuth from `/login` — default fallback (above)

## This user's setup

- **`CLAUDE_CODE_OAUTH_TOKEN` is exported** (mapped in `api-keys.cfg` →
  `private_dotfiles/api-key/claude-code`) — the long-lived `claude setup-token`
  for the Max subscription. A fresh shell is authed without a browser login,
  and it outranks the default subscription OAuth (#5 > #6).
- **`ANTHROPIC_API_KEY` is deliberately NOT exported globally.** It sits at
  precedence **#3 — above** both `CLAUDE_CODE_OAUTH_TOKEN` (#5) and the
  subscription login (#6), so a global export hijacks the agent onto the
  pay-per-use Console key and off the Max subscription. Tools that genuinely
  need the key read `private_dotfiles/api-key/anthropic` directly (the `mymcp`
  pattern), never the global env.

## The ~12h re-login gotcha (resolved)

Exporting `ANTHROPIC_API_KEY` globally forced a re-login roughly every ~12h —
removing the global export (PR #110) fixed the root cause. A session still
showing a stale/expired method clears with a full `/login` logout **and** login
(re-mints the subscription OAuth) — the observed fix when
`CLAUDE_CODE_OAUTH_TOKEN` appeared unset mid-session.

> The official docs do **not** document a literal 12h cycle; the subscription
> access token auto-refreshes normally. The breakage was the `ANTHROPIC_API_KEY`
> override interacting badly, not the refresh mechanism itself.

## Checking & switching

- **Which method is active:** `/status`.
- **A set `ANTHROPIC_API_KEY`:** approved once in interactive mode; toggle later
  via "Use custom API key" in `/config`.
- **Fall back to the subscription:** `unset ANTHROPIC_API_KEY` (inline / per
  shell, never global), then `/status` to confirm.
- **Hard guard:** `forceLoginMethod` in managed settings restricts to
  subscription auth and blocks the env-var methods entirely.
- **Re-mint the long-lived token:** `claude setup-token` (prints it; does not
  save — map it into `api-keys.cfg`).

## Sources

- Claude Code authentication — methods, precedence, management (fetched
  2026-06-19): <https://code.claude.com/docs/en/authentication>
- Claude Code setup — login + token generation:
  <https://code.claude.com/docs/en/setup>

## Agent Behavior

- **Never suggest exporting `ANTHROPIC_API_KEY` globally** — it outranks the
  long-lived token and the Max subscription (precedence #3). A tool that needs
  it reads `private_dotfiles/api-key/anthropic` directly (`mymcp`).
- Prefer the long-lived `CLAUDE_CODE_OAUTH_TOKEN` (`claude setup-token`, ~1yr)
  for non-interactive/CI auth; the subscription `/login` is the interactive
  default and auto-refreshes.
- Diagnose an auth problem with `/status` first; clear a stuck API-key override
  with `unset ANTHROPIC_API_KEY`, and a stuck session with a full `/login`
  logout + login.
