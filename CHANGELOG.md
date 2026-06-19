# Changelog

All notable completed work in this repository. The format follows
[Keep a Changelog]; this repo is not release-versioned (it is a dotfiles
checkout), so entries are grouped by completion date rather than by a
semantic version. Open work lives in [TODO.md](TODO.md); this file is its
finalized counterpart — items land here when the PR that completes them
goes green (see the merge-time finalization in
[ship-pr](config/claude/skills/ship-pr/SKILL.md) Step 4.5).

[Keep a Changelog]: https://keepachangelog.com/en/1.1.0/

## 2026-06-19

### Added

- **`tests/shell/test_ship.bats`** — behavioural tests for the ship-pr
  `ship.sh` helper via a faithful `gh`/`git` stub (canned JSON applied through
  real `jq`, as `gh --jq` does): `ci-watch` selecting the run for the branch
  tip SHA (regression for the #114 latest-run bug) and `merge-methods` ruleset
  parse with repo-settings fallback. (PR #116)
- **`config/pypoetry/poetry.lock`** — committed the Poetry tool-env lockfile
  (49 packages; `cryptography` 49.0.0 ≥ 48.0.1), so transitive deps are pinned
  and Dependabot's pip ecosystem can open security PRs for them. (PR #116)
- **PR-time verified secret scanning** — `.github/workflows/secret-scan.yml`
  runs **trufflehog** on `pull_request`, scanning the PR diff with the
  digest-pinned image run directly (per the security-scan skill, not a
  marketplace action), gating via `--fail`. Complements the commit-time
  `gitleaks` guard; **non-required** for now. Adds `rules/trufflehog.md` and
  updates the security-scan skill + `.claude/QA.md`. (Checkmarx was also
  evaluated and **declined** — commercial, no free tier; `semgrep` covers
  SAST.) (PR #116)

### Changed

- **Dropped the redundant direct `cryptography` pin** (`config/pypoetry`) and
  re-locked — `cryptography` is transitive again via `secretstorage`, no
  version churn, and the lock now correctly scopes the
  cryptography/cffi/pycparser chain to `sys_platform == "linux"` instead of
  forcing it on every platform. (PR #116)

## 2026-06-18

### Added

- **`config/claude/hooks/branch-protection.py`** — a `PreToolUse` hook on
  `Edit`/`Write`/`MultiEdit` that blocks an agent edit while a protected
  branch is checked out, enforcing git.md's "Never Work Directly on a
  Protected Branch" at edit time (the earliest of three layers, below the
  commit-time `no-commit-to-branch` hook and the push-time server ruleset).
  It reads the protected set from the repo's `no-commit-to-branch` args, so
  it activates only where that hook is configured (silent in repos without
  it, e.g. cloned upstreams/forks); plan-mode edits are whitelisted and any
  error fails safe. Wired into `settings.json`, covered by
  `tests/python/test_branch_protection.py` (the first python test, which
  self-activates the python CI job). (PR #108)
- **`config/claude/skills/retrospective/`** — a pre-merge skill (wired as
  ship-pr Step 4.6) that reflects on friction with the agent's own tooling
  (rules / skills / hooks / patterns / commands / MCP) and captures each
  finding as a detailed TODO, routed global vs repo-local. Idea borrowed from
  the dropped claude-md-management plugin. (PR #109)
- **Grounding & sourcing authoring rule** — `EXTENDING.md` now requires a new
  or edited rule/skill to be grounded in official docs / man pages (not
  memory) and to cite the source; `rule-TEMPLATE.md` gains a **Sources** slot
  and `CLAUDE.md` a pointer. (PR #109)
- **`claude-audit` cross-impact + grounding lenses** — when changing / moving
  / deleting an artifact, grep for referrers and fix/flag the ripple; and flag
  rules/skills that assert a tool's behaviour with no cited source. (PR #109)
- **Mark-as-you-go tracking rule** (`git.md` v1.7.0) — mark a `TODO`/`ROADMAP`
  item `[x]` in the commit that completes it, so merge-time finalization is a
  mechanical prune. Placed in always-on `git.md` so it is in context at every
  commit (a skill at PR-end cannot be). (PR #109)
- **`config/claude/skills/github-tasks/`** — a repo-agnostic GitHub
  housekeeping skill: one sweep that gathers a repo's open GitHub state (open
  Dependabot PRs, untriaged issues, failing required checks, stale/gone
  branches, release/tag hygiene, unresolved review threads), triages it, and
  presents a single ranked worklist — asking before acting on anything
  ambiguous. It orchestrates rather than duplicates: gather/triage/label is
  the only default-scope action; the heavy lifting routes to existing skills
  (security-scan, qa-check, ship-pr, git-worktree-workflow, release-tag,
  debug-assistant). Wired as the forcing function for `gh.md`'s "start of
  git/gh work, and daily" cadence (`gh.md` v1.3.0). (PR #111)

### Changed

- **Documented the edit-time protection layer** — `config/claude/rules/git.md`
  now describes **three** protection layers (v1.6.0) and `.claude/WORKFLOW.md`
  notes the hook for `master` (v1.2.0). (PR #108)
- **context7 MCP: marketplace plugin → `mymcp`** — `bin/mymcp` gained a
  `context7` case that reads the API key from the private store and passes
  `CONTEXT7_API_KEY`; the global export was removed from `api-keys.cfg`.
  Registered globally at user scope (`claude mcp add context7 --scope user --
  mymcp context7`); verified via the MCP `initialize` handshake (Context7
  v3.2.1). (PR #109)
- **Kept `skill-creator` and put it to work** — the one non-redundant
  marketplace plugin; wired into `claude-audit` (the skills dimension) and
  `EXTENDING.md` (use it when authoring a skill). (PR #109)
- **Refined the `ship-pr` approval model + finalization** (skill v1.9.1) —
  invoking the skill now consents through *opening the PR* (qa-check → commit
  → push → open PR → watch CI); merge and close still require a separate
  explicit instruction (`gh.md` updated to match). Step 4.5/4.6 reframed as a
  single doc-only finalization phase committed once. Also recorded
  skill-creator dogfooding findings — its automated trigger eval returns 0% on
  CC 2.1.x (upstream #2003 + a command-vs-`Skill` detection gap), so triggering
  is judged manually meanwhile (caveat in `claude-audit`, decisions-log entry
  in `SETUP-AUDIT.md`, follow-ups in `TODO.md`). (PR #112)
- **Worktree creation is explicit-request-only** (`git.md` v1.8.0) — never an
  automatic prelude to editing and never on a background-job/system-prompt
  nudge; the **git-worktree-workflow** skill is the only path, never the
  built-in `EnterWorktree` tool (hardcoded `worktree-*` names, no config knob);
  and a session launched already inside a worktree never creates another. Added
  to *Worktrees* plus an Agent Rules NEVER line. Resolves the PR #111
  retrospective follow-up (forbid, not reconcile; homed in `git.md`, not
  `CLAUDE.md`). (PR #113)
- **`test-review` absorbs the test-audit role** (skill v1.1.0) — reconciled the
  planned `/test-audit` skill against `test-review` and decided **not** to
  build it (it would duplicate `test-review`, already qa.md's Tests-dimension
  tool that `qa-check` composes). Extended `test-review` instead with an
  untested-unit **coverage census** and a **staleness/drift** lens, and named
  it in the repo QA doc's dim-6 row. (PR #115)
- **Meta-test generator covers skill helper scripts** — `build-meta-tests`
  default roots `bin lib` → `bin lib config/claude/skills`, so scripts like
  `ship-pr`'s `ship.sh` get the static checks (shebang, `bash -n`, shellcheck,
  shfmt) the suite never ran on them; no debt imported. `TESTS.md` scope
  updated. (PR #115)

### Removed

- **Four redundant marketplace plugins** — `claude-code-setup`,
  `claude-md-management`, `hookify` (+ ICEBOX: revisit a declarative guard
  engine only on Rule-of-Three), and `ralph-loop` (+ ICEBOX: extend `/loop`,
  don't rebuild). `enabledPlugins` 6 → 1; per-plugin rationale in
  `SETUP-AUDIT.md`. (PR #109)

### Fixed

- **Stopped exporting `ANTHROPIC_API_KEY` globally** (`api-keys.cfg`). Per
  Claude Code's auth precedence it overrode the Max subscription *and* the
  long-lived `CLAUDE_CODE_OAUTH_TOKEN`, forcing a re-login every ~12h (the
  OAuth access-token lifetime, which Claude Code doesn't auto-refresh). Tools
  that need the key now read it from `private_dotfiles/api-key/anthropic`
  directly (the `mymcp` pattern). (PR #110)
- **`ship.sh ci-watch` pins to the branch tip SHA** (`ship-pr` v1.9.2) — it
  watched the *latest run for the branch*, so a re-watch right after a push
  could latch onto the previous commit's already-green run before the new run
  registered (masking an in-progress run). Now resolves the run by the branch
  tip SHA — polls until that run appears (~60s), then falls back to the latest
  run only on timeout. (PR #114)

## 2026-06-17

### Security

- **Resolved Dependabot alert #6** (HIGH — vulnerable OpenSSL in
  `cryptography` wheels, `< 48.0.1`). `cryptography` is a transitive dep of
  the Poetry tool-env with no committed lockfile, so it was promoted to a
  direct constraint `cryptography = ">=48.0.1"` in
  `config/pypoetry/pyproject.toml`. (PR #103)

### Added

- **`.github/dependabot.yml`** — weekly version-update PRs for the pip
  (Poetry) and github-actions ecosystems; no auto-merge (PRs land via the
  normal protected-master flow). (PR #103)
- **`.claude/QA.md`** — repo QA doc mapping every dimension in the global
  `rules/qa.md` pipeline to this repo with an explicit status and the
  concrete commands; pointer added from `.claude/CONVENTIONS.md`. (PR #103)

### Changed

- **Conformed `.github/dependabot.yml` to its rule** — added `docker`
  entries for the repo's own Dockerfiles (`/tests/docker`, `/config/nvm`)
  and grouped minor/patch updates per ecosystem for pip + github-actions
  (majors stay individual). Updated `config/claude/rules/dependabot.md` to
  v1.1.0 with a doc-consultation authoring instruction (check the rule
  exists, consult official docs, verify ecosystem constraints — not memory).
  (PR #106)
- **Bumped GitHub Actions off Node.js 20** — `actions/checkout@v4` → `@v5`
  (×4) and `actions/setup-python@v5` → `@v6` (×2) in
  `.github/workflows/tests.yml`, clearing the Node 20 deprecation warnings
  ahead of GitHub's forced Node 24 cutover (`opencode.yml` was already on
  `checkout@v5`). (PR #101)

## 2026-06-12

### Added

- **`spotify-patterns` skill** — the recipe companion to `rules/spotify.md`
  + `spotify-audit`, mirroring `fastapi-patterns` / `sqlalchemy-patterns`.
  Recipes: proactive token refresh + `linked_from`-for-Library-ops
  relinking (written first-hand from the pigify fixes); pagination +
  set-based dedup; 429 / `Retry-After` + exponential-backoff rate-limit
  wrapper; playlist-creation strategies (by-artist / theme / song-list —
  recommendation-seeded dropped, deprecated endpoint); cover-art generation
  (SVG→PNG, a11y contrast, `ugc-image-upload`). Wired into `rules/spotify.md`
  and recorded in `SETUP-AUDIT.md` + the census.

## 2026-06-07

### Added

- **arg-loop → parse_params audit.** `bin/parse_params` replaces hand-written
  option loops (see `bash.md` *Argument Parsing*); no urgent conversions
  found (it is a perl subprocess per call — a win for option-heavy scripts,
  marginal for tiny helpers where `getopts` suffices). Converted `bin/hr` as
  the worked example (`#@` slurp positional) with `tests/shell/test_hr.bats`.
- **Test coverage** (bats unless noted):
  - Helper functions in `tests/helpers/common.bash` (`load_bats_libs`,
    `dotfiles_root`, `make_stub`, docker harness).
  - shell-startup integration — `test_integration_startup.bats` +
    `test_integration_context.bats` (full context matrix, docker harness).
  - `check-dotfiles` integration — `test_integration_check_dotfiles.bats`
    (docker harness, so its `ln -fs` into `$HOME` can't touch the host).
  - Unit: `cleanpath`, `yesno`, `git-status` (skips prompt assertion if
    system `git-prompt.sh` is absent), `debug`, `docker_helpers` (20 cases),
    `000-loadtokens` (conditional token loading, comment/missing-file skips,
    temp-var cleanup).
  - **`parse_params`** — rewritten in core-only perl as `bin/parse_params`
    (the old bash `lib/parse_params` was broken — sourced a long-gone
    `utility` lib + missing helpers — and is archived to `archive/lib/`).
    Emits `eval`-able shell assignments
    (`_pp=$(parse_params "$DEF" "$@") || show_usage; eval "$_pp"`) to replace
    hand-written `while` arg loops. Fixed the original's design flaws (no
    code-gen/eval, no shell-killing `die`, safe quoting, clear exit codes
    0/1/2); added signed integers, negatable booleans, repeatable `type@` →
    shell arrays, fixed + `#@` slurp positionals, `--prog`, `--auto`,
    POD-driven `--help`/`--usage`. Tests:
    `tests/perl/parse_params-{options,types,boolean,errors,modes}.t` (85).
  - **`where`** — `test_where.bats`; surfaced + fixed two bugs (a missing
    command hit the "Unexpected type" branch since modern `type -t` prints
    nothing for unknowns; it exited 1 even on success).
  - **`git-branch-clean`** — `test_git-branch-clean.bats` (guards +
    gone-upstream dry-run/force/never-pushed, against a throwaway repo).
  - **`git-all`** — `test_git-all.bats`; exposed that git-all was completely
    broken under `set -euo pipefail` (three cascading bugs, all masked by the
    first) — all fixed: `read -d '' < <(find)` abort (→ `mapfile -t`), the
    `grep && printf` abort on a clean repo (→ `if`), and empty-array
    expansion under `set -u` (→ `declare -a fail=()`).
  - **`proj`** — `test_proj.bats` (no-arg/existing path, -h, unknown option,
    too-many-args, unset PROJECTS_DIR, select-menu create/cancel via stdin).
  - **`ansi`** — `test_ansi.bats` (usage, TERM=dumb no-color fallback,
    escape-sequence emission, `-sb` PS1 delimiters, hex color).

### Changed

- **Moved gmailctl scripts to private_dotfiles.** `gmailfilter_toyaml` and
  `filter_gmail` (sensitive Gmail config; `filter_gmail` has a hardcoded
  personal path) moved to `private_dotfiles/bin/`. Removed their entries from
  `docs/bin.md` (also dropped the stale `poetry2setup` entry). Retired the
  public meta-suite `perl -c` debt for `gmailfilter_toyaml` (needed
  `XML::LibXML`) — it has left the public repo.
- **pre-commit Phase 1 follow-up** — pointed all 17 tool rules
  (bash/shellcheck/shfmt/yamllint/markdownlint/yapf/isort/flake8/black/ruff/
  biome/perl/powershell/docker/hadolint/vitest/TEMPLATE) at a canonical
  *Prefer pre-commit Over Direct Tool Invocation* section in `pre-commit.md`;
  direct invocation is now the documented fallback.
- **pre-commit Phase 3 (Python)** — wired the repo's actual toolchain
  (`yapf` + `isort` + `flake8`, **not** black/mypy): `isort --check` +
  `yapf -d` + `flake8` in the check config, `isort` + `yapf -i` in the fix
  config. Added `config/flake8` (reconciles flake8 with yapf's 2-space style)
  and `config/claude/rules/flake8.md`. All Python is gated (no excludes);
  `rule-coverage.py` reformatted to pass (added `E265,E266` to honor the
  `#####`/`#----` separators); `bin/poetry2setup` archived. Rust marked N/A.

### Fixed

- **`bin/creds-helper` PAT fallback bug** — when the credential was absent
  from `~/.netrc`, it checked the PAT path but read a different unset
  `$PAT_FILE` (`< ""` → error). Now reads the file it checked (single
  `pat_file` variable) and exits 0 when it has no credential (a helper
  shouldn't fail just because it has no answer). Regression test:
  `tests/shell/test_creds-helper.bats`.
- **perl CI promoted to a required check** — made the perl test assertions
  version-robust (assert *that a problem was reported* — non-zero code /
  non-blank message — not the exact Perl::Tidy wording or exit code; key
  parse_params `-h` on POD body, not pod2usage header formatting). Dropped
  `continue-on-error` from the perl job so it gates the run, and added `perl`
  to the master ruleset's required status checks (now `bats` + `perl` +
  `pre-commit`).
- **`available-subnets` removed** — obsolete old GCP-subnet tooling, archived
  to `archive/bin/`.

## Login shell startup performance (RESOLVED)

A login shell had regressed to 3–5s (peaks ~7s, vs an original <2s baseline).
Now a stable **~1.05–1.15s**. Profiling caveat preserved for future work:
both `bash -lixc` (xtrace) and `DEBUG=1` *inflate* any module that runs many
lines or calls `debug()` internally — measure a suspect module directly
(non-DEBUG) before optimizing.

### Changed

- **cleanpath** — parallelized per-entry `readlink` with `xargs -P`
  (sequential fallback; GNU `parallel` benchmarked slower for many tiny
  jobs). ~145ms, the largest single login cost; only a rewrite would help
  further.
- **`command -v` probe tail** — added `havecmd` (a `command -v` wrapper that
  drops `/mnt/c` for one lookup, then restores PATH) and converted every
  boolean-guard probe in `config/shell-startup/*`. The biggest real win.
- **bash_prompt** — moved all color computation to load time (the prompt was
  calling `ansi`, a subprocess, on every render for constant colors), so
  rendering spawns no `ansi` (~16ms/render); cached `_HAS_PSTREE` /
  `_HAS_PACMAN_STATUS` at load.
- **debug wiring** — `shell-startup` and `check-dotfiles` sourced the
  nonexistent `bin/debug` (the lib moved to `lib/debug`), so `DEBUG=1` did
  nothing; pointed both at `lib/debug`, guarded on `DEBUG`.

Accepted costs (left alone): `git-status` ~99ms/render (necessary work for
the git-aware prompt; only async/caching would cut it); grok / nvm were not
real costs (xtrace artifacts).

## CI/CD

### Added

- **`tests.yml`** runs on push to `master` and on pull requests, executing
  BATS tests and running shellcheck/yamllint/markdownlint via the
  `pre-commit` job.

## Planning-doc history (TODO.md)

Revision history of the planning document itself, moved here from
[`TODO.md`](TODO.md):

- **v1.2.0** (2026-06-17): Merge-finalization opt-in. Pruned all completed
  `- [x]` items (whole DONE sections: spotify-patterns, gmailctl move,
  creds-helper fix, perl CI, login-shell perf; plus done sub-items across
  Testing, pre-commit Phase 1/3, and CI/CD Phase 1), migrating the
  done-work record to this changelog. Also removed the two duplicate "Bump
  GitHub Actions off Node.js 20" sections (completed in PR #101 — verified
  against `tests.yml`). This repo now opts in to the merge-time finalization
  hook (see `.claude/WORKFLOW.md`), so the planning docs track only open work.
- **v1.1.0** (2026-06-07): Cleanup pass — removed completed sections (git
  file-mode normalization, Dependabot alerts, stale-branch cleanup, the
  container-harness build, shell context detection, and assorted done
  sub-items), fixed stale/contradictory statuses, deduplicated entries
  (grok block, bash_prompt venv, parse_params), dropped stale items for
  archived libs, and refreshed Progress Tracking + Next Actions.
- **v1.0.0** (2026-01-18): Initial consolidated TODO based on modernization
  plan. Documented completed tasks, organized remaining work by phase and
  priority.
