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
| Project path (1–3 levels) | cwd | CANDIDATE | cheap nicety; git branch usually conveys location |
| Git branch + dirty | git | SKIP | our `git-status` covers it |
| **Git ahead/behind `↑N ↓N`** | `git rev-list --count` | **CANDIDATE** | cheap, flags unpushed/unpulled — but belongs in the **shared `git-status`** helper (touches the bash prompt too) |
| Git file stats | porcelain | SKIP | `git-status` covers dirty |
| Context progress **bar** glyph | stdin % | CANDIDATE | nicer than our colored %, but costs width + render logic |
| **Rate-limit / usage bar (5h + weekly)** | stdin `rate_limits` | **CANDIDATE (verify)** | highest practical value for a Max user, pure-JSON — **but must confirm `rate_limits` is in our stdin** (absent for API-key/Bedrock/Vertex) |
| Tools / Skills / MCP / Agents lines | transcript | SKIP/CANDIDATE | transcript-stream heavy; agents-line is the only tempting one |
| Todos progress `(2/5)` | transcript | CANDIDATE | nice, transcript-dependent |
| Session duration / last-reply | transcript | CANDIDATE | start time needs transcript |
| **Output speed (tok/s)** | render-to-render `output_tokens` delta, cached on `sha256(transcript_path)` | CANDIDATE | clever, but needs a per-session **cache file + delta state** — heavy for a stateless line |
| Session token totals (in/out/cache) | transcript | CANDIDATE | transcript sum |
| Compaction count / advisor / cache-TTL / mem | transcript / OS | SKIP | niche / not session state |
| **Reasoning-effort `[high]`** | stdin effort | **CANDIDATE (verify)** | tiny, zero I/O — **if** our stdin exposes an effort field |
| Threshold color escalation | numeric → color | SKIP | we already do cyan/yellow/red-alarm |
| Cost / version | stdin | SKIP | already shown |
| `--extra-cmd` arbitrary shell | spawn | SKIP | security surface, unwanted |

## Top ideas (all gated — none clean-adopt-now)

1. **Rate-limit / usage segment** — best value, pure-JSON, same threshold-color
   trick. **Gate:** verify `rate_limits` exists in our statusline stdin.
2. **Git ahead/behind `↑N ↓N`** — cheap. **Gate:** belongs in the shared
   `git-status` helper (affects the bash prompt), and check it doesn't already
   emit it.
3. **Reasoning-effort indicator** — tiny. **Gate:** verify an effort field is
   in stdin.

Everything transcript-driven (tools/agents/todos/tokens/duration/speed) is
**heavier than a stateless bash/jq line** and stays CANDIDATE. Reused impl:
**none** (ideas only; it's a TS plugin, wrong form for our bash statusline).
