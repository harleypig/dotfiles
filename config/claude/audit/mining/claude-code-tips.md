# Mining matrix — ykdojo/claude-code-tips

Mined 2026-06-20 as the standalone mining-queue item (a **tips collection**,
distinct from the big plugin/skill-collection repos still queued). Audit-only
(not context-loaded).

## Metadata

- **Repo:** <https://github.com/ykdojo/claude-code-tips>
- **License:** **non-OSS / proprietary** — a custom contributor grant ("you
  grant YK Sugi a perpetual, irrevocable, worldwide, royalty-free license …"),
  copyright YK Sugi. **Not** MIT/Apache/GPL, so **implementation reuse is off
  the table** — we mine *ideas/techniques* only (facts and techniques aren't
  copyrightable; we write our own).
- **Stars / recency:** ~8.9k★, actively maintained (commits through
  2026-06-19) — well inside the staleness gate.
- **Shape:** hybrid — a 43-item prose README **plus** real artifacts: a `dx`
  plugin/marketplace, six packaged skills (`clone`, `gha`, `half-clone`,
  `handoff`, `reddit-fetch`, `review-claudemd`), helper scripts
  (`context-bar.sh` statusline, conversation clone/half-clone, `setup.sh`),
  and a `content/` library of articles/slides. Author is a Claude-Code
  YouTuber; the tips skew toward **personal interactive workflow** (voice,
  terminal tabs, Notion, Mac clipboard) rather than agent **configuration**.

## Disposition

ADOPT = cheap clear win now · CANDIDATE = worth it later (user decides) ·
SKIP = covered/redundant/not a fit · SKIP-until `<trigger>` = flips to
CANDIDATE when the trigger fires (Watch list).

| # | Tip | Disp. | Reason |
|---|-----|-------|--------|
| 0 | Custom status line (`context-bar.sh`, 10 themes) | SKIP | we have a richer `config/claude/bin/statusline.sh` (ctx %, rate-limits, effort, vim-mode) |
| 1 | Essential slash commands (`/usage`, `/chrome`, `/mcp`, `/stats`, `/clear`) | SKIP | built-in knowledge |
| 2 | Voice input (superwhisper/MacWhisper/EarPods) | SKIP | personal interactive workflow; not config |
| 3 | Break large problems into smaller ones | SKIP | covered by Pre-Implementation / planning discipline (`CLAUDE.md`) |
| 4 | Git/gh: allow pull not push; draft PRs; **disable attribution** | SKIP | gh/git rules cover PR flow; the disable-attribution tip is **counter to our policy** (we keep `Co-Authored-By`) |
| 5 | "Context is like milk" — fresh & condensed; new convo per topic | SKIP | covered by `compact-snapshot` + audit-cadence |
| 6 | Get output out of the terminal (`/copy`, `pbcopy`, `open`) | SKIP | trivial / Mac-specific |
| 7 | Terminal aliases (`c='claude'`, `c -c`, `c -r`) | SKIP | personal shell config |
| 8 | Proactive `/compact`; `HANDOFF.md`; `/handoff`; `/plan` | SKIP | covered by `compact-snapshot`; handoff held as a future *workflow* category (census Category status) |
| 9 | Write-test cycle: tmux interactive, Playwright MCP | SKIP | e2e on the Watch list (Playwright → browser-UI trigger) |
| 10 | Cmd+A/Ctrl+A to copy blocked content into Claude | SKIP | personal interactive workflow |
| 11 | Invest in your workflow; concise CLAUDE.md | SKIP | meta; this whole config *is* that |
| 12 | Search conversation history (`grep`/`jq` over `~/.claude/projects/*.jsonl`) | SKIP | useful technique but covered for our needs by the file-based **memory** system; one-shot grep, not a procedure |
| 13 | Multitasking with terminal tabs ("cascade") | SKIP | personal interactive workflow |
| 14 | Git worktrees for parallel branches | SKIP | our **git-worktree-workflow** skill is far more developed |
| 15 | Manual exponential backoff for long jobs (1→2→4 min poll) | SKIP | `ship.sh ci-watch` already polls; `ScheduleWakeup` guidance owns pacing |
| 16 | Claude as a writing assistant | SKIP | personal workflow |
| 17 | "Markdown is the s\*\*t" (vs Docs/Notion) | SKIP | personal workflow |
| 18 | Use Notion to preserve links when pasting | SKIP | personal workflow |
| 19 | Containers for risky tasks; `--dangerously-skip-permissions`; SafeClaw | SKIP | **counter to our security posture** — we don't skip permissions |
| 20 | "Get better by using it" | SKIP | motivational |
| 21 | Fork/clone conversations (`/fork`, `--fork-session`, auto-half-clone hook at 85%) | SKIP | `/fork` is built-in; the 85%-context auto-snapshot overlaps `compact-snapshot` / PreCompact (cf. the ruflo Watch entry) |
| 22 | `realpath` for absolute paths | SKIP | trivial |
| 23 | CLAUDE.md vs Skills vs Commands vs Plugins | SKIP | `EXTENDING.md` covers this far deeper |
| 24 | Interactive PR reviews via `gh` | SKIP | covered by `/code-review` + `ship-pr` |
| 25 | Claude as a research tool (reddit-fetch, paper-search, MCP) | SKIP | domain-niche; MCP is second-class for us |
| 26 | Verify output — "double check every single claim" | SKIP | covered by our delegated-research **over-claim guard** (demand exact quotes+URLs) |
| 27 | DevOps: CI root-cause; `/dx:gha` (flakiness, breaking-commit bisect) | SKIP | covered by `github-actions.md` + `ci-watch` + `debug-assistant`; bisect-automation noted as a possible future, not trigger-gated |
| 28 | Review CLAUDE.md periodically; `/review-claudemd` skill | SKIP | **claude-audit** reviews the whole config (broader than just CLAUDE.md) |
| 29 | Claude as the universal interface (ffmpeg/whisper/data) | SKIP | motivational / ad-hoc |
| 30 | Choose the right level of abstraction ("spectrum of agentic coding") | SKIP | covered by abstraction discipline (`code-style.md`) |
| **31** | **cc-safe — audit *approved* commands for risky patterns** (`sudo`, `rm -rf`, `chmod 777`, `curl \| sh`, `git reset --hard`) | **CANDIDATE** | **real gap** — nothing audits our `settings.json` `permissions.allow` list for dangerous auto-approved entries; generic + security-positive |
| 32 | Write lots of tests; TDD | SKIP | covered by `testing.md` |
| 33 | Be braver; iterative problem solving | SKIP | motivational |
| 34 | Background bash + subagents (`Ctrl+B`, BashOutput, model/count) | SKIP | built-in; we already use background tasks |
| 35 | "The era of personalized software" | SKIP | motivational |
| **36** | **Input-box navigation keybindings** (`Ctrl+A/E`, `Alt+←/→`, `Ctrl+W/U/K`, `Ctrl+G` external editor, `\`+Enter, paste-image) | **CANDIDATE** | **direct concrete input** for the open backlog item *Keybinding cheat-sheet statusline line* — a secondary source to cross-check against the official docs |
| 37 | Plan, but also prototype quickly (`/plan`, Shift+Tab) | SKIP | covered by planning discipline |
| 38 | Simplify overcomplicated code | SKIP | covered by `/simplify` |
| 39 | Automation of automation | SKIP | meta |
| 40 | Share your knowledge | SKIP | N/A |
| 41 | Keep learning (`/release-notes`, r/ClaudeAI) | SKIP | trivial |
| 42 | Install the `dx` plugin | SKIP | foreign plugin — second-class + always-on for us; no good global fit |
| 43 | Quick `setup.sh` curl-bash installer | SKIP | N/A (and we don't curl-bash) |

## Outcome — two CANDIDATEs, the rest covered

41 of 43 tips are **SKIP** — either already covered by our (more developed)
tooling, personal interactive workflow rather than agent config, motivational,
or counter to our posture (disable-attribution, skip-permissions). Two are
worth surfacing for the user to decide:

- **Tip 31 — audit the permission allow-list (the cc-safe idea).** The
  strongest find: we have no check that scans `settings.json`
  `permissions.allow` for risky auto-approved patterns (`sudo`, `rm -rf`,
  `chmod 777`, `curl | sh`, `git reset --hard`, broad `Bash`). Generic,
  security-positive, and a natural **fold into `claude-audit`** (which already
  inspects `settings.json` for plugins/hooks) or a small standalone check.
  `cc-safe` itself is a separate external npm tool — the *idea* is what we'd
  adopt; we'd write our own check. Recorded as a backlog CANDIDATE.

- **Tip 36 — input-box keybindings.** Not a new artifact but exact, concrete
  input for the already-open backlog item *Keybinding cheat-sheet statusline
  line*. It is a **secondary** source (a YouTuber's list, Mac-leaning), so it
  must still be cross-checked against the official Claude Code docs per that
  item's over-claim guard — added there as a cross-reference, not trusted on
  its own.

**Reused impl:** none (ideas only; non-OSS license puts implementation reuse
off-limits regardless).
