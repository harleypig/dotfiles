# Agent config structure

A navigable reference for the Claude Code agent configuration in this
dotfiles repo. If you're new to this setup, start with *Design* below. If
you know what you're looking for, jump straight to the relevant table.

**This file is hand-maintained** — update it whenever a rule, skill, or
hook is added, modified, or removed. It is not auto-loaded into the agent
context; the trigger lives in `CLAUDE.md` *Missing or Conflicting Tool
Rules*.

## Design: generic to specific

The configuration is layered. The most generic rules sit at the top and
load every conversation; more specific rules load only when relevant files
are detected; skills package the multi-step procedures those rules
describe; hooks enforce the critical rules deterministically.

Each layer refers *upward* — a skill names the rule it implements, a
detection-activated rule extends the generic rule it specialises. This
means you can understand any piece by reading what it points to above it,
and you can find the right piece by starting at the generic layer and
drilling down.

```text
Always-on rules          ← invariant policy, every conversation
Detection-activated rules ← same policy, but scoped to a tool/language
Skills                   ← multi-step procedures those rules call for
Hooks                    ← deterministic enforcement of the must-nots
```

A rule describes *what* the policy is and *when* to reach for a skill or
command. A skill describes *how* to execute a multi-step procedure. A hook
*enforces* a rule mechanically, without relying on the model remembering.

---

## Always-on rules

Loaded into every conversation. These are the invariant layer — they
apply regardless of what files are in the repo.

The **Calls / see also** column lists skills the rule explicitly invokes or
names as its forcing function (`skill-name`), rules it cross-references
(`rule.md`), and built-in commands it names as a step (`/cmd`).

| Rule | What it governs | Calls / see also |
|------|-----------------|-----------------|
| [claude-code-auth.md](rules/claude-code-auth.md) | Claude Code auth methods, precedence order, the never-export-`ANTHROPIC_API_KEY` rule, diagnosing auth problems | — |
| [code-style.md](rules/code-style.md) | Naming, 78-col Markdown / 72-col comment wrap, paragraph spacing, section separators, Rule of Three, efficiency by default | — |
| [documentation.md](rules/documentation.md) | The documentation bar — when to update docs, what form fits each audience, inline-first philosophy | `write-documentation` · `adr` |
| [gh.md](rules/gh.md) | GitHub CLI usage: PR conventions, dual-credential auth fallback, issue triage cadence | `git-worktree-workflow` · `ship-pr` · `github-tasks` · `security-scan` · `release-tag` · `github-rulesets.md` |
| [git.md](rules/git.md) | Commit messages, branch naming, staging discipline, protected-branch rules, worktrees, versioning & tags | `git-worktree-workflow` · `release-tag` · `ship-pr` · `branch-protection.py` |
| [qa.md](rules/qa.md) | The full QA pipeline from format through CI — 15 dimensions, ordering, fix/check discipline | `qa-check` · `security-scan` · `containerize` · `deps-update` · `arch-review` · `test-review` · `a11y-review` · `perf-review` · `pytest-patterns` · `typing-patterns` · `write-documentation` · `adr` · `code-style.md` · `testing.md` · `documentation.md` |
| [testing.md](rules/testing.md) | The test bar (success + failure paths, regression per bug) and be-idiomatic-per-language stance | — |
| [troubleshooting.md](rules/troubleshooting.md) | Reproduce first, fix the root cause, land a regression test | `debug-assistant` · `qa-check` |

---

## Detection-activated rules

These load automatically when you work with matching files. They extend
the always-on rules with tool- or language-specific policy. Each file's
`paths:` frontmatter names what triggers it. Where a rule has a companion
skill that provides deeper patterns or procedures, it is noted below the
rule name.

### Shell

| Rule | Activates on |
|------|-------------|
| [bash.md](rules/bash.md) | `*.sh`, `*.bash`, `bin/**` |
| [shellcheck.md](rules/shellcheck.md) | `*.sh`, `*.bash`, `bin/**` |
| [shfmt.md](rules/shfmt.md) | `*.sh`, `*.bash`, `bin/**` |
| [bats.md](rules/bats.md)<br>↗ `bats-setup` | `*.bats`, `tests/**` |
| [powershell.md](rules/powershell.md) | `*.ps1`, `*.psm1`, `*.psd1` |

### Python

| Rule | Activates on |
|------|-------------|
| [python.md](rules/python.md)<br>↗ `pytest-patterns` · `typing-patterns` | `*.py`, `*.pyi` |
| [flake8.md](rules/flake8.md) | `*.py` |
| [ruff.md](rules/ruff.md) | `*.py` |
| [black.md](rules/black.md) | `*.py` |
| [isort.md](rules/isort.md) | `*.py` |
| [yapf.md](rules/yapf.md) | `*.py` |
| [tox.md](rules/tox.md) | `tox.ini`, `pyproject.toml` |
| [poetry.md](rules/poetry.md) | `pyproject.toml`, `poetry.lock` |

### Python frameworks

| Rule | Activates on |
|------|-------------|
| [fastapi.md](rules/fastapi.md)<br>↗ `fastapi-patterns` | `*.py` with FastAPI imports |
| [sqlalchemy.md](rules/sqlalchemy.md)<br>↗ `sqlalchemy-patterns` | `*.py` with SQLAlchemy imports |
| [alembic.md](rules/alembic.md)<br>↗ `sqlalchemy-patterns` | `alembic.ini`, `migrations/**` |

### JavaScript / TypeScript / Frontend

| Rule | Activates on |
|------|-------------|
| [typescript.md](rules/typescript.md) | `*.ts`, `*.tsx` |
| [react.md](rules/react.md)<br>↗ `frontend-design` | `*.tsx`, `*.jsx` |
| [css.md](rules/css.md) | `*.css`, `*.scss`, `*.sass` |
| [html.md](rules/html.md) | `*.html`, `*.htm` |
| [biome.md](rules/biome.md) | `biome.json`, `biome.jsonc` |
| [vite.md](rules/vite.md) | `vite.config.*` |
| [vitest.md](rules/vitest.md) | `vitest.config.*`, `*.test.ts` |
| [mantine.md](rules/mantine.md) | `*.tsx` with Mantine imports |

### Java

| Rule | Activates on |
|------|-------------|
| [java.md](rules/java.md) | `*.java` |

### Docker / Infrastructure

| Rule | Activates on |
|------|-------------|
| [docker.md](rules/docker.md)<br>↗ `containerize` | `Dockerfile*`, `docker-compose*.yml` |
| [hadolint.md](rules/hadolint.md)<br>↗ `containerize` | `Dockerfile*` |
| [dive.md](rules/dive.md)<br>↗ `containerize` | `Dockerfile*` |
| [trivy.md](rules/trivy.md)<br>↗ `containerize` · `security-scan` | `Dockerfile*`, security scan context |
| [nginx.md](rules/nginx.md) | `nginx.conf`, `sites-*/` |

### Security tools

| Rule | Activates on |
|------|-------------|
| [semgrep.md](rules/semgrep.md)<br>↗ `security-scan` | `.semgrep.yml`, `*.py`, `*.js`, `*.ts` |
| [osv-scanner.md](rules/osv-scanner.md)<br>↗ `security-scan` | `go.sum`, `package-lock.json`, `requirements*.txt` |
| [zap.md](rules/zap.md)<br>↗ `security-scan` | Web application / DAST scan context |
| [trufflehog.md](rules/trufflehog.md)<br>↗ `security-scan` | `.github/workflows/**` |

### CI / repo tooling

| Rule | Activates on |
|------|-------------|
| [github-actions.md](rules/github-actions.md) | `.github/workflows/*.yml` |
| [github-rulesets.md](rules/github-rulesets.md) | `**/github-rulesets/**`, `*ruleset*.json` |
| [dependabot.md](rules/dependabot.md)<br>↗ `security-scan` · `github-tasks` | `.github/dependabot.yml` |
| [pre-commit.md](rules/pre-commit.md) | `.pre-commit-config.yaml` |
| [mcp.md](rules/mcp.md) | MCP server / tool context |

### Project setup

| Rule | Activates on |
|------|-------------|
| [new-project.md](rules/new-project.md)<br>↗ `new-project` | `pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`, `Gemfile` |

### Data formats / prose

| Rule | Activates on |
|------|-------------|
| [markdownlint.md](rules/markdownlint.md) | `*.md` |
| [yamllint.md](rules/yamllint.md) | `*.yml`, `*.yaml` |
| [todo.md](rules/todo.md)<br>↗ `todo-organize` · `qa-check` | `TODO.md`, `ROADMAP.md`, `BACKLOG.md` |

### Domain-specific

| Rule | Activates on |
|------|-------------|
| [spotify.md](rules/spotify.md)<br>↗ `spotify-patterns` · `spotify-audit` | Spotify Web API / SDK context |
| [perl.md](rules/perl.md) | `*.pl`, `*.pm`, `*.t` |

---

## Skills

Skills are multi-step procedures invoked on demand (by name or trigger
phrase). Each one is backed by a `SKILL.md` that defines the exact steps.
Locally authored skills live under `skills/<name>/SKILL.md`.

The **Calls / see also** column shows skills the skill explicitly invokes
or composes (`skill-name`), rules it reads for policy (`rule.md`), hooks
it involves (`hook.py`), and built-in commands it names as a step (`/cmd`).

### Workflow & landing

| Skill | What it does | Calls / see also |
|-------|-------------|-----------------|
| [ship-pr](skills/ship-pr/SKILL.md) | Full landing pipeline: QA → commit → push → open PR → watch CI → (approval) merge → tag → cleanup | `qa-check` · `git-worktree-workflow` · `release-tag` · `retrospective` · `merge-finalization.py` · `gh.md` · `git.md` · `github-actions.md` · `pre-commit.md` |
| [git-worktree-workflow](skills/git-worktree-workflow/SKILL.md) | Worktree-based development: create issue branches, sync with upstream, prep PR, cleanup | `git.md` · `gh.md` |
| [release-tag](skills/release-tag/SKILL.md) | Cut an annotated `vX.Y.Z` tag at the merge commit, push, and watch the release workflow | `git.md` · `github-actions.md` |
| [github-tasks](skills/github-tasks/SKILL.md) | Sweep a repo's GitHub state (Dependabot PRs, open issues, failing checks, stale branches, release hygiene), triage into a ranked worklist, and route each item to its skill | `security-scan` · `ship-pr` · `git-worktree-workflow` · `release-tag` · `debug-assistant` · `gh.md` · `git.md` |

### Quality assurance

| Skill | What it does | Calls / see also |
|-------|-------------|-----------------|
| [qa-check](skills/qa-check/SKILL.md) | Run the full QA pipeline (format → lint → type-check → security → tests → build → docs → CI) using the repo's own QA doc for commands | `security-scan` · `containerize` · `arch-review` · `test-review` · `a11y-review` · `perf-review` · `pytest-patterns` · `typing-patterns` · `/code-review` · `/simplify` · `/security-review` · `qa.md` · `code-style.md` · `pre-commit.md` |
| [security-scan](skills/security-scan/SKILL.md) | SAST + dependency/supply-chain scanning; wires Semgrep, OSV-Scanner, Dependabot, Trufflehog | `semgrep.md` · `dependabot.md` · `trivy.md` · `trufflehog.md` |
| [containerize](skills/containerize/SKILL.md) | Author, harden, scan, and size-check Docker images and compose files | `docker.md` · `hadolint.md` · `trivy.md` · `dive.md` |
| [deps-update](skills/deps-update/SKILL.md) | Deliberate dependency-update sweep: inventory → triage → changelog → batch → compat-gate | `security-scan` · `qa-check` · `debug-assistant` |
| [debug-assistant](skills/debug-assistant/SKILL.md) | Structured debugging: reproduce → capture evidence → bisect → fix root cause → regression test | `qa-check` · `testing.md` |
| [claude-audit](skills/claude-audit/SKILL.md) | Audit the global Claude Code config (rules, skills, hooks, plugins, MCP) for context economy and fit | `ship-pr` · `retrospective` · `qa-check` |

### Codebase review (whole-repo, not diff-level)

| Skill | What it does | Calls / see also |
|-------|-------------|-----------------|
| [arch-review](skills/arch-review/SKILL.md) | Structure, layering, coupling, circular deps, and tech-debt hotspots across the whole codebase | — |
| [test-review](skills/test-review/SKILL.md) | Test-suite quality: coverage, structure, brittleness, missing edge cases (not running the tests) | `testing.md` |
| [perf-review](skills/perf-review/SKILL.md) | Runtime performance: hotspots, N+1, allocation, sync-in-async, missing caching — measure first | `arch-review` · `qa.md` |
| [a11y-review](skills/a11y-review/SKILL.md) | WCAG accessibility: semantic markup, keyboard nav, ARIA, contrast, screen-reader labelling | — |
| [modernize](skills/modernize/SKILL.md) | Phased Strangler-Fig migration roadmap from legacy to target — plans, does not execute | `arch-review` |

### Documentation & decisions

| Skill | What it does | Calls / see also |
|-------|-------------|-----------------|
| [write-documentation](skills/write-documentation/SKILL.md) | Author or refresh a doc: pick the right form, derive from code, lint, wire into index + changelog | `adr` · `documentation.md` · `code-style.md` · `markdownlint.md` |
| [adr](skills/adr/SKILL.md) | Record an Architecture Decision Record — what, why, alternatives rejected, consequences | — |
| [plan-review](skills/plan-review/SKILL.md) | Poke holes in a plan *before* building: risky assumptions, missing edge cases, simpler alternatives | `testing.md` |
| [retrospective](skills/retrospective/SKILL.md) | After completing work, reflect on agent-tooling friction and capture each finding as an open TODO — feeds the `claude-audit` backlog | — |

### Python depth

| Skill | What it does | Calls / see also |
|-------|-------------|-----------------|
| [pytest-patterns](skills/pytest-patterns/SKILL.md) | Concrete pytest recipes: fixtures, mocking discipline, parametrize, async, coverage | `python.md` · `testing.md` |
| [typing-patterns](skills/typing-patterns/SKILL.md) | Python typing depth: TypedDict, Protocol, generics, overload, narrowing, Annotated | `python.md` · `code-style.md` |
| [fastapi-patterns](skills/fastapi-patterns/SKILL.md) | FastAPI + Pydantic v2 recipes: DTOs, validators, Depends, response models, error mapping | `fastapi.md` · `sqlalchemy.md` |
| [sqlalchemy-patterns](skills/sqlalchemy-patterns/SKILL.md) | SQLAlchemy 2.0 + Alembic recipes: mixins, N+1, eager loading, tricky migrations | `sqlalchemy.md` · `alembic.md` |

### Domain depth

| Skill | What it does | Calls / see also |
|-------|-------------|-----------------|
| [spotify-patterns](skills/spotify-patterns/SKILL.md) | Spotify Web API recipes: token refresh, track relinking, pagination, rate limits, playlist cover art | `spotify.md` · `spotify-audit` |
| [spotify-audit](skills/spotify-audit/SKILL.md) | Audit a Spotify integration for API best practices, deprecated endpoints, auth correctness | `spotify.md` |
| [frontend-design](skills/frontend-design/SKILL.md) | Create distinctive, production-grade frontend UI — avoids generic AI aesthetics | `react.md` · `typescript.md` · `css.md` · `code-style.md` |

### Repo setup

| Skill | What it does | Calls / see also |
|-------|-------------|-----------------|
| [new-project](skills/new-project/SKILL.md) | Initialize a new repo or convert an existing one to these conventions (git, pre-commit, docs, tests, CI, branch protection) — greenfield or brownfield | `bats-setup` · `ship-pr` · `pre-commit.md` · `testing.md` · `git.md` · `gh.md` |
| [bats-setup](skills/bats-setup/SKILL.md) | Scaffold bats-core testing: layout, helper libraries, meta-test generator, starter test, CI | `bats.md` |

---

## Hooks

Hooks run automatically on specific events — they enforce rules
deterministically, without relying on the model remembering.

| Hook | Event | What it enforces |
|------|-------|-----------------|
| [branch-protection.py](hooks/branch-protection.py) | `PreToolUse` on `Edit` / `Write` / `MultiEdit` | Blocks file edits while a protected branch is checked out; derives the protected branch list from the `no-commit-to-branch` pre-commit args (`git.md`) |
| [merge-finalization.py](hooks/merge-finalization.py) | `PreToolUse` on `gh pr merge` / `ship.sh merge` | Blocks a merge while completed `- [x]` items remain in planning docs (opt-in per repo via `merge-finalization: enforce` in `WORKFLOW.md`) |
| [shell-check.py](hooks/shell-check.py) | `PostToolUse` on `Edit` / `Write` / `MultiEdit` | Runs `shellcheck` on a shell file immediately after it is edited, surfacing findings to the agent in-session |
| [md5-guard.py](hooks/md5-guard.py) | `PostToolUse` on `Edit` / `Write` / `MultiEdit` | Auto-regenerates a git-tracked `<name>.md5` checksum after the agent edits its file, so managed edits stay blessed and only out-of-band changes look like drift (dormant where no such sibling exists; powers the dotfiles `shell-startup-guard` skill) |
| [rule-coverage.py](hooks/rule-coverage.py) | `PostToolUse` on `Edit` / `Write` | Nags when a new dependency or language has no matching `rules/<name>.md` |
| [compact-snapshot.py](hooks/compact-snapshot.py) | `SessionStart` with source `compact` | Re-injects a git/session-state snapshot after a `/compact`, restoring context the compaction would otherwise drop |
| [audit-cadence.py](hooks/audit-cadence.py) | `SessionStart` (startup / resume / clear) | Once-a-day nudge that a `claude-audit` pass is due |

---

## Built-in commands

These come with the Claude Code installation — they are not authored in
this repo. They are invoked as slash commands or by trigger phrase.

| Command | What it does |
|---------|-------------|
| `/code-review` | Review the current diff for correctness bugs, reuse and simplification opportunities |
| `/simplify` | Review the changed code for simplification and cleanup opportunities, then apply fixes |
| `/security-review` | Security review of the pending changes on the current branch |
| `/init` | Initialize a new `CLAUDE.md` file with codebase documentation |
| `/review` | Review a pull request |
| `/run` | Launch and drive the project app to verify a change works |
| `/verify` | Verify that a code change does what it's supposed to by running the app |
| `deep-research` | Fan-out web search → fetch sources → adversarially verify → cited report |
| `skill-creator` | Create, modify, and benchmark skills; run evals; optimize trigger descriptions |
| `update-config` | Configure the Claude Code harness via `settings.json` (hooks, permissions, env vars) |
| `github-tasks` | Sweep a repo's GitHub state: Dependabot PRs, open issues, failing checks, stale branches |
| `new-project` | Initialize or onboard a repo to these dotfiles' conventions |
| `retrospective` | Pre-merge agent-tooling retrospective: friction points → detailed TODOs for the backlog |
| `loop` | Run a prompt or slash command on a recurring interval |
| `schedule` | Create, update, or list scheduled cloud agents running on a cron schedule |
| `fewer-permission-prompts` | Scan transcripts for common read-only calls; add an allowlist to reduce prompts |
| `keybindings-help` | Customize keyboard shortcuts in `~/.claude/keybindings.json` |
| `claude-api` | Reference for the Claude API / Anthropic SDK — models, pricing, params, streaming, tool use |
