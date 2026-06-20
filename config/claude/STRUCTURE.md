# Agent config structure

A navigable reference for the Claude Code agent configuration in this
dotfiles repo. If you're new to this setup, start with *Design* below. If
you know what you're looking for, jump straight to the relevant table.

**This file is hand-maintained.** It describes what exists; it is not
auto-loaded into the agent context.

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

| Rule | What it governs |
|------|-----------------|
| [code-style.md](rules/code-style.md) | Naming, 78-col Markdown / 72-col comment wrap, paragraph spacing, section separators, Rule of Three, efficiency by default |
| [documentation.md](rules/documentation.md) | The documentation bar — when to update docs, what form fits each audience, inline-first philosophy |
| [gh.md](rules/gh.md) | GitHub CLI usage: PR conventions, dual-credential auth fallback, issue triage cadence |
| [git.md](rules/git.md) | Commit messages, branch naming, staging discipline, protected-branch rules, worktrees, versioning & tags |
| [qa.md](rules/qa.md) | The full QA pipeline from format through CI — dimensions, ordering, fix/check discipline |
| [testing.md](rules/testing.md) | The test bar (success + failure paths, regression per bug) and be-idiomatic-per-language stance |
| [troubleshooting.md](rules/troubleshooting.md) | Reproduce first, fix the root cause, land a regression test |

---

## Detection-activated rules

These load automatically when you work with matching files. They extend
the always-on rules with tool- or language-specific policy. Each file's
`paths:` frontmatter names what triggers it.

### Shell

| Rule | Activates on |
|------|-------------|
| [bash.md](rules/bash.md) | `*.sh`, `*.bash`, `bin/**` |
| [shellcheck.md](rules/shellcheck.md) | `*.sh`, `*.bash`, `bin/**` |
| [shfmt.md](rules/shfmt.md) | `*.sh`, `*.bash`, `bin/**` |
| [bats.md](rules/bats.md) | `*.bats`, `tests/**` |
| [powershell.md](rules/powershell.md) | `*.ps1`, `*.psm1`, `*.psd1` |

### Python

| Rule | Activates on |
|------|-------------|
| [python.md](rules/python.md) | `*.py`, `*.pyi` |
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
| [fastapi.md](rules/fastapi.md) | `*.py` with FastAPI imports |
| [sqlalchemy.md](rules/sqlalchemy.md) | `*.py` with SQLAlchemy imports |
| [alembic.md](rules/alembic.md) | `alembic.ini`, `migrations/**` |

### JavaScript / TypeScript / Frontend

| Rule | Activates on |
|------|-------------|
| [typescript.md](rules/typescript.md) | `*.ts`, `*.tsx` |
| [react.md](rules/react.md) | `*.tsx`, `*.jsx` |
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
| [docker.md](rules/docker.md) | `Dockerfile*`, `docker-compose*.yml` |
| [hadolint.md](rules/hadolint.md) | `Dockerfile*` |
| [dive.md](rules/dive.md) | `Dockerfile*` |
| [trivy.md](rules/trivy.md) | `Dockerfile*`, security scan context |
| [nginx.md](rules/nginx.md) | `nginx.conf`, `sites-*/` |

### Security tools

| Rule | Activates on |
|------|-------------|
| [semgrep.md](rules/semgrep.md) | `.semgrep.yml`, `*.py`, `*.js`, `*.ts` |
| [osv-scanner.md](rules/osv-scanner.md) | `go.sum`, `package-lock.json`, `requirements*.txt` |
| [zap.md](rules/zap.md) | Web application / DAST scan context |

### CI / repo tooling

| Rule | Activates on |
|------|-------------|
| [github-actions.md](rules/github-actions.md) | `.github/workflows/*.yml` |
| [dependabot.md](rules/dependabot.md) | `.github/dependabot.yml` |
| [pre-commit.md](rules/pre-commit.md) | `.pre-commit-config.yaml` |
| [mcp.md](rules/mcp.md) | MCP server / tool context |

### Data formats / prose

| Rule | Activates on |
|------|-------------|
| [markdownlint.md](rules/markdownlint.md) | `*.md` |
| [yamllint.md](rules/yamllint.md) | `*.yml`, `*.yaml` |

### Domain-specific

| Rule | Activates on |
|------|-------------|
| [spotify.md](rules/spotify.md) | Spotify Web API / SDK context |
| [perl.md](rules/perl.md) | `*.pl`, `*.pm`, `*.t` |

---

## Skills

Skills are multi-step procedures invoked on demand (by name or trigger
phrase). Each one is backed by a `SKILL.md` that defines the exact steps
— the agent reads it when the skill is invoked. Locally authored skills
live under `skills/<name>/SKILL.md`.

### Workflow & landing

| Skill | What it does |
|-------|-------------|
| [ship-pr](skills/ship-pr/SKILL.md) | Full landing pipeline: QA → commit → push → open PR → watch CI → (approval) merge → tag → cleanup |
| [git-worktree-workflow](skills/git-worktree-workflow/SKILL.md) | Worktree-based development: create issue branches, sync with upstream, prep PR, cleanup |
| [release-tag](skills/release-tag/SKILL.md) | Cut an annotated `vX.Y.Z` tag at the merge commit, push, and watch the release workflow |

### Quality assurance

| Skill | What it does |
|-------|-------------|
| [qa-check](skills/qa-check/SKILL.md) | Run the full QA pipeline (format → lint → type-check → security → tests → build → docs → CI) |
| [security-scan](skills/security-scan/SKILL.md) | SAST + dependency/supply-chain scanning; wires Semgrep, OSV, Dependabot |
| [containerize](skills/containerize/SKILL.md) | Author, harden, scan, and size-check Docker images and compose files |
| [deps-update](skills/deps-update/SKILL.md) | Deliberate dependency-update sweep: inventory → triage → changelog → batch → compat-gate |
| [debug-assistant](skills/debug-assistant/SKILL.md) | Structured debugging: reproduce → capture evidence → bisect → fix root cause → regression test |
| [claude-audit](skills/claude-audit/SKILL.md) | Audit the global Claude Code config (rules, skills, hooks, plugins, MCP) for context economy and fit |

### Codebase review (whole-repo, not diff-level)

| Skill | What it does |
|-------|-------------|
| [arch-review](skills/arch-review/SKILL.md) | Structure, layering, coupling, circular deps, and tech-debt hotspots across the whole codebase |
| [test-review](skills/test-review/SKILL.md) | Test-suite quality: coverage, structure, brittleness, missing edge cases (not running the tests) |
| [perf-review](skills/perf-review/SKILL.md) | Runtime performance: hotspots, N+1, allocation, sync-in-async, missing caching — measure first |
| [a11y-review](skills/a11y-review/SKILL.md) | WCAG accessibility: semantic markup, keyboard nav, ARIA, contrast, screen-reader labelling |
| [modernize](skills/modernize/SKILL.md) | Phased Strangler-Fig migration roadmap from legacy to target — plans, does not execute |

### Documentation & decisions

| Skill | What it does |
|-------|-------------|
| [write-documentation](skills/write-documentation/SKILL.md) | Author or refresh a doc: pick the right form, derive from code, lint, wire into index + changelog |
| [adr](skills/adr/SKILL.md) | Record an Architecture Decision Record — what, why, alternatives rejected, consequences |
| [plan-review](skills/plan-review/SKILL.md) | Poke holes in a plan *before* building: risky assumptions, missing edge cases, simpler alternatives |

### Python depth

| Skill | What it does |
|-------|-------------|
| [pytest-patterns](skills/pytest-patterns/SKILL.md) | Concrete pytest recipes: fixtures, mocking discipline, parametrize, async, coverage |
| [typing-patterns](skills/typing-patterns/SKILL.md) | Python typing depth: TypedDict, Protocol, generics, overload, narrowing, Annotated |
| [fastapi-patterns](skills/fastapi-patterns/SKILL.md) | FastAPI + Pydantic v2 recipes: DTOs, validators, Depends, response models, error mapping |
| [sqlalchemy-patterns](skills/sqlalchemy-patterns/SKILL.md) | SQLAlchemy 2.0 + Alembic recipes: mixins, N+1, eager loading, tricky migrations |

### Domain depth

| Skill | What it does |
|-------|-------------|
| [spotify-patterns](skills/spotify-patterns/SKILL.md) | Spotify Web API recipes: token refresh, track relinking, pagination, rate limits, playlist cover art |
| [spotify-audit](skills/spotify-audit/SKILL.md) | Audit a Spotify integration for API best practices, deprecated endpoints, auth correctness |
| [frontend-design](skills/frontend-design/SKILL.md) | Create distinctive, production-grade frontend UI — avoids generic AI aesthetics |

### Repo setup

| Skill | What it does |
|-------|-------------|
| [bats-setup](skills/bats-setup/SKILL.md) | Scaffold bats-core testing: layout, helper libraries, meta-test generator, starter test, CI |

---

## Hooks

Hooks run automatically on specific events — they enforce rules
deterministically, without relying on the model remembering to apply them.

| Hook | Event | What it enforces |
|------|-------|-----------------|
| [merge-finalization.py](hooks/merge-finalization.py) | `PreToolUse` on `gh pr merge` / `ship.sh merge` | Blocks a merge while completed `- [x]` items remain in planning docs (opt-in per repo via `merge-finalization: enforce` in `WORKFLOW.md`) |
| [rule-coverage.py](hooks/rule-coverage.py) | `PostToolUse` on `Edit`/`Write` | Nags when a new dependency or language has no matching `rules/<name>.md` |

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
