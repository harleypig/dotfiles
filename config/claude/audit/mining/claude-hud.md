# Mining matrix — jarrodwatts/claude-hud

Mined 2026-06-19 for **statusline / HUD ideas** (triggered by the Claude
statusline display fix). Audit-only (not context-loaded).

## Metadata

- **Repo:** <https://github.com/jarrodwatts/claude-hud>
- **License:** MIT · **Language:** TypeScript · **Type:** Claude Code *plugin*
  (not a shell script) — commands `/claude-hud:setup`, `/claude-hud:configure`.
- **Recency:** actively maintained (pushed 2026-06-19) — well inside the >1yr
  staleness gate. ~25k stars.

## What it is

A native statusline renderer (TS, stdin → line). It **enriches** the documented
statusline JSON from three extra sources: the **transcript JSONL**
(`transcript_path`, streamed for tool/agent/todo/skill/MCP activity, per-session
token totals, session start, compaction count, advisor model), **git** (shell
out for branch/dirty/ahead-behind/file-stats), and an optional snapshot /
env-gated `--extra-cmd`. Multi-line "expanded" layout by default + a "compact"
single-line mode; ~40 segment toggles, presets, `elementOrder`, i18n, 12
themeable colors, configurable bar glyphs.

Contrast with ours: `config/claude/bin/statusline.sh` is a **stateless** single
` | `-joined bash/jq line (git-status, model, ctx %, cost, version) that reads
**only** the documented stdin JSON — no transcript parsing, no per-session
cache.

## Disposition

ADOPT = cheap clear win now · CANDIDATE = worth it later (note cost) · SKIP =
covered/not a fit.

| Segment / technique | Source | Disp. | Reason |
|---|---|---|---|
| Model badge | stdin | SKIP | we show model name |
| Provider label (Bedrock/Vertex) | stdin | SKIP | single-provider Max user |
| Project path (1–3 levels) | cwd | SKIP | user is good with the `git-status` output; git branch conveys location |
| Git branch + dirty | git | SKIP | our `git-status` covers it |
| Git ahead/behind `↑N ↓N` | `git rev-list --count` | **SKIP** | already implemented in our `git-status` helper — the user deliberately does not surface it |
| Git file stats | porcelain | SKIP | `git-status` covers dirty |
| Context progress **bar** glyph | stdin % | **SKIP-until** | user is fine with the plain `X%` for now — revisit if a richer context gauge is wanted (on the census watch list) |
| **Rate-limit / usage bar (5h + weekly)** | stdin `rate_limits` | **ADOPTED** | done 2026-06-19 — `5h:`/`7d:` `used_percentage` ride inside the context segment (no `\|`), colored by the shared pct ramp; hidden when `rate_limits` is absent (non-subscriber) |
| Tools / Skills / MCP / Agents lines | transcript | SKIP/CANDIDATE | transcript-stream heavy; agents-line is the only tempting one |
| Todos progress `(2/5)` | transcript | CANDIDATE | nice, transcript-dependent |
| Session duration / last-reply | transcript | SKIP | user not interested |
| **Output speed (tok/s)** | render-to-render `output_tokens` delta, cached on `sha256(transcript_path)` | SKIP | user not interested; also needs a per-session cache file + delta state |
| Session token totals (in/out/cache) | transcript | SKIP | user not interested |
| Compaction count / advisor / cache-TTL / mem | transcript / OS | SKIP | niche / not session state |
| **Reasoning-effort `[high]`** | stdin `.effort.level` | **ADOPTED** | done 2026-06-19 — `.effort.level` (low/medium/high/xhigh/max) confirmed; rendered as a `[level]` tag attached to the model (no `\|` between), colored by level via the context calm/warn/alarm scheme; shown only when present |
| Threshold color escalation | numeric → color | SKIP | we already do cyan/yellow/red-alarm |
| Cost / version | stdin | SKIP | already shown |
| `--extra-cmd` arbitrary shell | spawn | SKIP | security surface, unwanted |

## Top ideas — outcome

- **Reasoning-effort indicator** — **DONE** 2026-06-19 (`.effort.level`
  confirmed; rendered `[level]`).
- **Rate-limit / usage segment** — **DONE** 2026-06-19 (`5h:`/`7d:`
  `used_percentage` inside the context segment, colored by the pct ramp).
- ~~Git ahead/behind~~ — **SKIP**: already in `git-status`, user doesn't
  surface it.
- **User-trimmed (2026-06-19):** project path, session duration, output speed,
  session token totals → **SKIP** (not wanted). Context progress-bar glyph →
  **SKIP-until** (fine with the plain `X%` for now; watch list).

The only remaining transcript-driven CANDIDATEs are the tools/agents lines and
todos `(2/5)` — heavier than a stateless bash/jq line. Reused impl: **none**
(ideas only; it's a TS plugin, wrong form for our bash statusline).

While verifying the effort field, the docs also showed **`.vim.mode`
(NORMAL/INSERT) is a real field** (present when Claude Code vim mode is on) —
so the `mode` field removed in the statusline fix was *documented*, not
bogus. It was still broken as written (the build emitted only the empty label,
never the value, and the absent value shifted the parse). Whether to restore it
(now the parse is empty-safe) is a **user decision** — see the BACKLOG entry.
