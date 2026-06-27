# TODO

## 🐫 Perl Setup

Everything for standing up Perl in this repo, end to end: the toolchain
install, QA tooling (perlcritic, coverage, POD, deeper analysis, SAST), the
pre-commit/CI gate integration, setup docs, and the agent rules/skills that
capture it. Build it out across **both the test suite and the CLI scripts**
(where CLIs exist — e.g. `bin/parse_params`, `bin/perltidyrc-clean`), as
strict as practical, in stages. Capture the resulting toolchain in **agent
rules/skills** (see *Rules & skills* below), not only human setup docs.

### Toolchain install (perlbrew)

- [ ] **perlbrew**: install a pinned Perl + cpanm, then the toolchain the repo
  needs (notably **Perl::Tidy**, plus the perlcritic policy dists chosen
  below). A controlled Perl::Tidy identical across machines **and CI** removes
  the version drift behind the non-gating `perl` job; pinning fixes the
  wording drift, though the `perltidyrc-clean` tests should still be hardened
  to be version-robust. Follow the one documented, idempotent, XDG-aware
  install + shell-init pattern from *Tool/Version Manager Setup*.

### perlcritic

`perlcritic` is currently unusable: this machine has many **non-core,
third-party policy bundles** installed that bury real findings in noise. On
`bin/parse_params`, `--severity 4` shows only
`ValuesAndExpressions::ProhibitAccessOfPrivateData` (28× — false positive on
plain `$hashref->{key}`); `--severity 3` adds `CodeLayout::TabIndentSpaceAlign`
(217×, demands tabs — **rejected, this repo is spaces-only**),
`ProhibitHashBarewords`, `Reneeb::*`, `logicLAB::*`, `Bangs::*`, UTF-8 and
`RequireExtendedFormatting` opinions, etc. The current
`config/perl/perlcriticrc` is worse than nothing — it references uninstalled
bundles (OTRS, TryTiny).

- [ ] Rebuild `config/perl/perlcriticrc` as a curated profile; drop the
  uninstalled-bundle references.
- [ ] **Review each installed external policy individually** — they are *not*
  all bad; adopt the useful ones and exclude only what genuinely doesn't fit
  (e.g. TabIndentSpaceAlign, ProhibitAccessOfPrivateData). Don't dismiss the
  third-party bundles wholesale.
- [ ] **Ratchet severity toward the strictest (1), in stages** — clean the
  findings at each level before tightening; start from the `--severity 4`
  baseline (`perl.md`) and work down.
- [ ] **Test::Perl::Critic** — run perlcritic from the test suite (a
  `tests/perl/*-critic.t` over `bin/` + `lib/`) so the curated profile is
  *enforced*, not merely available.
- [ ] **Docker angle** (ties into "run more linters via Docker"): a pinned
  `perlcritic` image (`FROM perl` + `cpanm Perl::Critic` plus only the chosen
  policy dists) gives a **controlled** policy set — no stray third-party
  bundles — removing most noise by construction. No official image exists, so
  it'd be a small custom pinned `docker_wrapper` entry.

### Coverage and POD

- [ ] **Devel::Cover** — measure coverage for the perl test suite (and the
  CLIs it exercises); add a report and a coverage target to aim for.
- [ ] **Pod::Coverage** / **Test::Pod::Coverage** — ensure every public sub
  and CLI option is documented in POD; gate it in the suite. Pair with
  **Test::Pod** for POD syntax.

### Additional analysis

- [ ] **B::Lint** — a second, lighter layer of basic checks (accepting some
  overlap with perlcritic); decide where it adds signal perlcritic doesn't.
- [ ] **B::Deparse** — use as an *aid* when making scripts idiomatic (compare
  deparsed output to spot non-idiomatic constructs / hidden behavior); a
  technique, not a gate.
- [ ] **Perl::Analyzer** — investigate (call-graph / structure analysis);
  evaluate whether it's worth adding for the larger perl.

### Security scanning

- [ ] Look into perl SAST: **Checkmarx was evaluated and declined** (commercial,
  no free tier — see "Evaluate trufflehog & Checkmarx"), so pursue
  **open-source** options only (e.g. `perlcritic` security policies, or other
  OSS perl analyzers), and fold any perl SAST into the `security-scan` skill /
  `qa.md` security dimension rather than a one-off.

### Pre-commit & CI integration

Gating Perl in the commit/CI pipeline. Both depend on a clean, enforced
perlcritic profile (above) and a pinned toolchain (*Toolchain install*) — that
keystone is what unblocks them.

- [ ] **Pre-commit hook** (Pre-commit rollout → Phase 3) — DEFERRED; the
  `perlcritic` and `perltidy` hooks are staged commented in both configs
  (`.pre-commit-config.yaml` / `-fix.yaml`). Blocked on: the existing
  `perlcritic --severity 4` debt; `config/perl/perlcriticrc` referencing
  uninstalled policy bundles (OTRS, TryTiny); perltidy version drift; and the
  perl tools not being installed in the CI pre-commit job. Enable after
  perlbrew pinning + perlcriticrc rebuild + debt cleanup.
- [ ] **CI linting job** (CI/CD rollout → Phase 3) — wire perl linting
  (perlcritic/perltidy) into `tests.yml`, gating once the pre-commit hooks are
  enabled and the perl tools are installed in the CI job. Today the `perl`
  prove job is **non-gating** (perltidy version drift); pinning via perlbrew
  is what lets it gate.

### Setup / documentation

- [ ] Document installation + setup for **all of the above** (Perl::Critic +
  the chosen policy dists, Test::Perl::Critic, Devel::Cover, Pod::Coverage /
  Test::Pod::Coverage / Test::Pod, B::Lint, Perl::Analyzer, any perl SAST)
  alongside the existing setup docs (WORKFLOW.md *Tool Setup Procedures* /
  Prerequisites). Use the repo's standard install path — perlbrew + cpanm (see
  *Tool/Version Manager Setup*) or pinned docker wrappers — so a fresh machine
  reproduces the whole perl QA toolchain from one documented place.

### Rules & skills (agent config)

*Claude-config note (TODO-routing):* these deliverables are `config/claude`
work (rules / a skill), kept here because they're coupled to the perl-tooling
stages above (each rule lands as its tool does). Author them as part of that
work, or move this subsection to `audit/BACKLOG.md` when the tooling lands —
don't leave it stranded in the dotfiles `TODO.md`.

These stages adopt several tools the **agent** must know how to drive — capture
each as agent config, not only human setup docs, per `CLAUDE.md` *Missing or
Conflicting Tool Rules* and *When to Propose a Skill*. Today only a thin
`rules/perl.md` exists (a one-line `perltidy` + `perlcritic --severity 4`
mention) and there is **no** perl-QA skill (cf. `bats-setup`,
`pytest-patterns`).

- [ ] **Per-tool rules.** As each tool lands, create or extend its
  `rules/<tool>.md`, **grounded in current official docs with a Sources cite**
  (`EXTENDING.md` *Grounding & sourcing*) — never memory. Likely a dedicated
  **`rules/perlcritic.md`** (the curated profile, policy-selection judgement,
  staged severity ratchet, and docker-pinned-policy-set angle are far more than
  `perl.md`'s one-liner), plus shorter rules or `perl.md` sections for
  `perltidy`, `Devel::Cover`, and `Test::Pod::Coverage`. Wire each into the
  tool-detection table and the `qa.md` / repo QA-doc dimension mapping.
- [ ] **A perl-QA skill?** Decide whether the multi-step procedures here
  (scaffold the toolchain → curate the perlcritic profile → ratchet severity in
  stages → wire Test::Perl::Critic + coverage + POD gates) warrant a skill — a
  perl analog of **`bats-setup`** (scaffolding) and/or **`pytest-patterns`**
  (depth recipes). Weigh against `qa-check` (which *runs* QA) and the existing
  skills; fold into one rather than duplicate if it already fits (Rule of
  Three).

## 🐚 Bash Setup

Bash language tooling, testing, and QA. `shellcheck` / `shfmt` are largely
done.

### Phase 2: Test Infrastructure

- [ ] Review and enhance existing BATS tests
- [ ] Ensure meta-tests are up to date (`tests/scaffold/build-meta-tests`)
- [ ] Create test fixtures in `tests/fixtures/` if needed

### Phase 3: Core Test Coverage

- [ ] Add tests for critical bin/ scripts
- [ ] Add tests for lib/ libraries
  - [ ] **Consider converting `bin/cleanpath` to perl** (same kind of text
        munging). Constraint: core perl modules only — no CPAN (keeps it
        runnable anywhere; avoids the Perl::Tidy/XML::LibXML install gap).
  - (`is`, `Arrays`, `strings` archived to `archive/lib/`; `git-prompt`
    factored into `bin/git-status` — not tested.)
- [ ] Add tests for config/shell-startup/ modules
  - The rest are guarded tool-setup (`command -v`/interactive) already
    exercised in aggregate by the docker integration tests
    (`test_integration_startup` + `test_integration_context`); add a focused
    unit test only when a module grows real conditional logic.

### Phase 4: Extended Coverage

- [ ] Completion tests for config/completions/
- [ ] Integration tests for tool configurations
- [ ] Performance tests for PATH building

### Test Infrastructure

- [ ] tests/scaffold/build-meta-tests:5,6,71 - Add tests for sh compilation,
  improve shebang check, handle symbolic links (XXX)

### Comprehensive BATS Test Coverage Audit

`bin/` audited (2026-06-07). The 9 `docker_wrapper` tool symlinks (dive,
hadolint, ollama, openwebui, prettier, shellcheck, shfmt, trivy, yamllint) are
tested once at the dispatcher (`test_docker_wrapper`). Real scripts classified:

**Tested:** cleanpath, check-dotfiles, docker_wrapper, envsubstitute,
git-status, hr, mymcp, parse_params, perltidyrc-clean, yesno, **duration**
(`test_duration.bats`), **dir-readable** (`test_dir-readable.bats`).

**Unit-testable (pure logic) — to do:**

- [ ] (reclassified to integration) `showvars` — needs `shfmt` (docker
  wrapper) + `jq`; covered under the integration group, not pure-unit.
- [ ] (marginal) `loadavg` (output depends on real load), `dateh` (date-format
  table — mostly display).

**Integration (external tools / state) — to do:**

- [ ] (low value) `motd` (large system-summary display), `tmux_mode_indicator`
  (tmux display; also has the `set -ex` leftover to clean — see tmux section)
  (`set -ex` cleanup → see *Repository extraction* › tmux item),
  `loadavg` / `dateh` (load-dependent / display), `showvars` (needs the shfmt
  docker wrapper + jq). These are display/integration-heavy; deferred.

**Net:** every bin/ script with real logic or external interaction is now
tested (duration, dir-readable, where, creds-helper, git-branch-clean,
git-all, proj, ansi + the earlier set); the bin/ coverage pass is
substantively complete. The above are the remaining display/heavy stragglers.

**Trivial / skip (documented):** `anykey` (interactive single-key read),
`lwhich` / `vimwhich` (thin `which`/vim wrappers), `run-help` (9-line readline
shim), `show-unicode` (static table), `bash-colors` (color-var defs),
`tmux_edit_buffer` (5-line tmux glue).

- [ ] Also evaluate beyond `bin/`: remaining `config/shell-startup/` modules
  (mostly covered by the integration tests) and any scripts elsewhere.
- [ ] Regenerate the meta suite after adding scripts; keep Phase 3 in sync.

### Bash Completion

- [ ] Enable bash completion for available but unconfigured tools
- [ ] Document completion setup in dedicated section or inline
- [ ] Create completion tests

## 🪟 PowerShell Setup

### PowerShell ↔ Bash Feature Parity

The PowerShell startup (`ps-startup.ps1` + `powershell/startup/*`) lags the
bash side (`shell-startup` + `config/shell-startup/*` + `lib/*` + `bin/*`).
Bring it to parity **where it makes sense for PowerShell** — port the
cross-shell concepts, skip the bash-only or Windows-irrelevant bits. Now that
`tests/shell/test_integration_powershell.bats` exists, each ported feature
should get an assertion there (or a Pester test under `tests/powershell/`).

- [ ] Audit bash `config/shell-startup/*` against `powershell/startup/*` and
  decide, per feature, port / adapt / skip. Candidates that map cleanly:
  - [ ] **History** — `010-general.ps1` already flags this (PSReadLine: history
    file location/size, dedupe, search); mirror the bash `HIST*` intent.
  - [ ] **Completions** — bash completions → PSReadLine / argument completers.
  - [ ] **Prompt** — a pwsh `prompt` function mirroring the bash prompt (git
    status, last exit code, cwd) — reuse the `bin/git-status` concept.
  - [ ] **Aliases/functions** — port still-relevant bash aliases/functions not
    already in `010-general.ps1`; grep colors → PSReadLine colors.
  - [ ] **PATH dedup** — a `cleanpath` equivalent for `$env:PATH` so
    ps-startup's PATH prepend can't accumulate duplicates. (Also fixes the
    Windows-style `\`/`;` PATH line in `ps-startup.ps1` when run under Linux
    `pwsh`.)
  - [ ] **Interactive vs always split** — the bash side guards interactive-only
    setup with `[[ $- == *i* ]]`; decide the pwsh analog (a non-interactive
    `pwsh -File`/`-Command` still loads the profile — keep env setup cheap and
    side-effect-free, gate interactive-only bits on
    `[Environment]::UserInteractive`/`$Host` if needed).
  - [ ] **debug helper** — a `$env:DEBUG`-gated trace mirroring `lib/debug`.
- [ ] `powershell/bin/*` vs `bin/*` — note which bash utilities have a
  Windows-relevant analog worth providing (and which stay bash-only).
- [ ] Fold the XXX items below into this audit as they're addressed.

### PowerShell Improvements

- [ ] ps-startup.ps1:49 - Move Python path to dedicated setup file (XXX)
- [ ] 010-general.ps1:27,42,54,59 - Port remaining bash features marked with XXX

### PowerShell: Linux Dev/Test Environment

Linux `pwsh` + Docker is proven viable — the integration test runs the
profile cleanly in the stock `mcr.microsoft.com/powershell` image. Remaining
research:

- [ ] Compatibility between `pwsh` (Core) and Windows PowerShell 5.1:
  - Known gaps: COM objects, Windows-only modules (`ActiveDirectory`, etc.),
    `$PSVersionTable.PSEdition` differences, some .NET APIs
  - Determine if `ps-startup.ps1` and `config/powershell/` scripts use any
    Windows-only features that would break under `pwsh` on Linux
  - Check if Pester runs identically on both
- [ ] Whether a Windows container is needed to test true Windows PowerShell
  5.1 behavior, and whether that's practical (requires a Windows host for
  Windows containers).

## 🟢 Node Setup

- [ ] nvm: install + lazy-load; pin a default Node, following the
  cross-language pattern in *Tool/Version Manager Setup*.

## 🔧 Tool/Version Manager Setup

Install and configure per-language version/tool managers consistently: one
documented, idempotent, XDG-aware install + shell-init pattern per manager,
lazy-loaded in `config/shell-startup/<lang>` to keep shell startup fast. Each
language's specific manager lives in its `## <Language> Setup` (perlbrew →
*Perl Setup*; nvm → *Node Setup*); this section owns the **cross-language
pattern** they share.

- [ ] Evaluate/standardize the rest (Python, Ruby; rustup already in use)
  under one consistent pattern, documented in each
  `config/shell-startup/<lang>` module.

## 🐚 Shell-startup Setup

### Shell-startup colors & helpers to get working (from audit)

Long-standing "I've been trying to get this working for years" items, parked
from the audit. Each is its own task:

- [ ] **`less` colors** — get the `LESS_TERMCAP_*` coloring reliable; while
  here, revisit the commented `LESSKEY` (`less`:7) and `LESS_TERMCAP_mh` dim
  (`less`:79–80), and the per-login `less --incsearch -V | grep` capability
  probe (`less`:26) — cache the result instead of running it every login.
- [ ] **`grep` colors** — get `GREP_COLORS` (and the commented `GREP_COLOR`,
  `010-general`:21) producing the intended highlight.
- [ ] **`run-help`** — get the Alt+h "help for word under cursor" binding
  working (commented in `010-general`:184; needs the inputrc macro).

### Shell-startup follow-ups (from audit)

- [ ] **gcloud completion cost** — `010-general`'s gcloud block runs
  `gcloud info --format=…` every login to locate `completion.bash.inc`. Cache
  the resolved `sdk_root` path so the subprocess doesn't run on every shell.
- [ ] **non-interactive startup** — `shell-startup` runs to completion
  regardless of interactivity; `zzz-check-dotfiles` / `zzz-check-dotvim` run
  their checks even in a non-interactive shell. Verify nothing prints to
  stdout on a non-interactive source (would corrupt `scp`/`rsync` if `BASH_ENV`
  ever points here); guard with `[[ $- == *i* ]]` if so.
- [ ] **Document the module-placement convention** in `.claude/` (retrospective
  from the audit): a tool with only 1–2 settings goes in `010-general` or
  `app_env_vars`; more than that earns its own module; tool-only on-demand
  commands belong in a `bin/` wrapper, not shell-startup (the env-vs-bin
  split). It drove several audit decisions but is written down nowhere.

### Move env-polluting shell-startup setup into bin wrappers

Some `config/shell-startup/` modules export tool-specific environment into
*every* interactive shell for a tool that's rarely run — the setup belongs in
an on-demand `bin/` wrapper (set the env, then `exec <tool> "$@"`) so it stops
polluting the global environment. This is the "should this even live in the
shell?" lens on the *config/shell-startup Audit* section above.

- [ ] **aider** — move `config/shell-startup/aider` into a `bin/aider`
  wrapper. It currently parses `$DOTFILES/aider.env` and exports `AIDER_*`
  (plus `AIDER_EDITOR`, `AIDER_COMMIT_PROMPT`) into every shell, though only
  aider needs them. A wrapper that builds that env and `exec`s the real
  `aider` scopes it to invocation; remove the shell-startup module once moved
  (its new `shellcheck-sourced` / `shfmt-sourced` pre-commit coverage follows
  it to `bin/`, where the executable shebang makes it tagged automatically).
- [ ] **Audit every `config/shell-startup/` module** for the same opportunity
  and **report on each one** — including the ones that should *stay*. For each,
  classify:
  - **move** — purely tool-only env/config, safe to lazy-load via a wrapper;
  - **keep** — a genuine interactive-shell feature (e.g. `git`'s aliases and
    functions, prompt/`less`/completion wiring) that *must* live in the
    environment;
  - **partial** — split the tool-only env into a wrapper but keep the
    shell-facing bits in the module.

  Partial moves are expected and fine. The deliverable is the per-module
  report (move / keep / partial, with the reason); acting on it is follow-up.

### Surfaced from comment cleanup

- [ ] `config/shell-startup/tmux` - when multiple tmux sessions exist, have
  `ta` list them and let the user choose, instead of always attaching the
  `$USER` session. (Marker at the `ta` definition.)
  - From the shell-startup audit: trim env pollution — `export -f ta`
    (and `set_title`/`unset_title`) pushes interactive helpers into every
    child process, and `circled_digits` is set at module scope but never
    unset. Scope or unset them while reworking `ta`.

## 🖥️ Statusline Setup

Goal: avoid repeating the same information across the four statusline surfaces
(bash prompt, tmux status bar, vim statusline, Claude statusline). Each surface
should own a distinct slice of context.

Proposed ownership split (to be refined during implementation):

- **bash prompt** — exit code, venv/conda name, git branch+dirty state (when
  not in tmux or vim)
- **tmux status bar** — host, session name (multi-session only), clock, weather
- **vim statusline** — filename, filetype, linting errors, vim mode; git branch
  only when not in tmux
- **Claude statusline** — model name, context window %, session cost, worktree
  name; suppress anything already shown by tmux (e.g. git branch) when $TMUX
  is set

Context detection: use `$TMUX`, `$VIM`/`$VIMRUNTIME`, and
`$CLAUDE_SESSION_ID` (if available) to suppress duplicate info at each layer.

### Task 1: Claude Statusline Script

*Scope note (TODO-routing):* `config/claude/bin/statusline.sh` is
Claude-agent config, but this stays here because it's one surface of a four-way
coordination (bash / tmux / vim / Claude) — kept whole, not split to
`audit/BACKLOG.md`. **The urgent display bug** in that script (malformed
layout, context-% prominence) is tracked separately in `audit/BACKLOG.md` →
*Claude statusline fix*; this Task 1 is the longer-horizon coordination work.

Docs: <https://code.claude.com/docs/en/statusline>

Built: `config/claude/bin/statusline.sh` (`model | ctx N% | $cost`; context %
colored by threshold; graceful jq-missing exit), wired in `settings.json`,
worktree marker via `bin/git-status`. Remaining:

- [ ] Observe in a live session and tune (model name length, field order, colors)
- [ ] Consider suppressing model name when $TMUX is set (if tmux bar shows it)

### Task 2: Unified Statusline Strategy (do after Task 1)

Once the Claude statusline exists, audit all four surfaces together:

- [ ] Inventory what each surface currently shows:
  - bash prompt (`config/bash_prompt`, `bin/git-status`)
  - tmux (`config/tmux/tmux.conf` status-left/right)
  - vim (vimrc / airline / lightline config in `../dotvim`)
  - claude (`config/claude/bin/statusline.sh` — built in Task 1)
- [ ] Identify duplicates and decide canonical owner for each piece of info
- [ ] Implement suppression logic using context env vars (`$TMUX`, `$VIM`, etc.)
  - This subsumes the existing "if in tmux, disable git-status in bash prompt"
    and "consider adding git-status to vim status line (except when in tmux)"
    items from the old Prompt Enhancements list
- [ ] Update `bin/git-status` to respect context flags
- [ ] Document the ownership split in a comment block or inline README

## 🐳 Docker tooling Setup

### Research: run more linters/formatters via Docker

Today only some tools have a `bin/` docker wrapper (shellcheck, shfmt,
yamllint, prettier, hadolint, trivy, dive, markdownlint — via
`bin/docker_wrapper`). Others (yapf, isort, flake8, perltidy, perlcritic) are
"command not found" unless installed on the host, so a fresh machine is
inconsistent and pre-commit's isolated envs are the only thing that runs them.

- [ ] **Per-tool wrappers**: identify which remaining tools have a trustworthy
  official/pinned image and add them to the `docker_wrapper` dispatcher (yapf,
  isort, flake8, perltidy, perlcritic, …) — same pattern as the existing
  wrappers, mounting `$PWD` + the relevant `config/` files. Ties into the
  "bin/markdownlint docker wrapper" and docker_wrapper symlink-automation items.
- [ ] **Evaluate aggregate linter images — Super-Linter vs MegaLinter.** Both
  bundle many linters in one image:
  - `github/super-linter` — simplest; check-only.
  - `oxsecurity/megalinter` — a more configurable fork: select linters via
    `ENABLE_LINTERS`, language-specific "flavors" (smaller images), reporters/
    SARIF, and it can **apply fixes** (`APPLY_FIXES`), unlike super-linter.
  - The shared tension: both are built to scan a **whole repo** (CI), not to
    expose each linter as an individual command, so neither maps cleanly onto
    the per-tool `bin/<tool>` model or pre-commit's per-file hooks. Research
    whether their bundled linters can be invoked individually
    (`docker run … <linter> <args>`) and whether that's worth it vs. pinning
    each tool's own image. Likely roles: a CI "lint everything" aggregate pass
    (MegaLinter's configurability makes it the stronger candidate), or a
    convenience wrapper — **not** a replacement for per-tool wrappers /
    pre-commit hooks.
- [ ] **Decide the boundary**: which tools are best as standalone pinned
  images, which (if any) via an aggregate (Super-Linter/MegaLinter), and how
  this interacts with pre-commit (which already runs tools in isolated envs —
  a host wrapper is mainly for ad-hoc CLI use outside a commit).

## 🚀 CI/CD Setup

**Dependency:** Each CI/CD phase requires corresponding Pre-commit phase.
Current state: `tests.yml` runs bats (gating), perl (non-gating), and python
(self-activating), plus a `pre-commit` job (`--all-files`). The phased plan
below is the remaining buildout.

**Key Rule:** CI/CD Phase N requires Pre-commit Phase N completed first.
Pre-commit can progress independently. CI/CD cannot lead pre-commit.

### CI reliability

- [ ] **Harden the `pre-commit` job against Docker Hub pull flakiness.** The
  `shellcheck` hook (koalaman/shellcheck image) and any other docker-based
  hooks pull from Docker Hub on every CI run; an anonymous-pull timeout
  failed PR #146's `pre-commit` job (`exit 125`, registry `Client.Timeout`)
  and needed a manual `gh run rerun --failed`. Mitigate so it doesn't recur:
  cache the pre-commit environments (`actions/cache` on `~/.cache/pre-commit`),
  and/or authenticate to Docker Hub (`docker/login-action`) to lift the
  anonymous rate limit, and/or switch the shellcheck hook to an apt-installed
  binary in CI. Pick the lightest reliable option.

### Phase 1: Basic CI (requires Pre-commit Phase 1)

- [ ] Consolidate/confirm the CI workflow:
  - [ ] Report results as job status (confirm coverage matches the plan)
- [ ] Document CI workflow

### Phase 2: Security Checks (requires Pre-commit Phase 2)

- [ ] Add security job to CI workflow:
  - [ ] Run gitleaks
  - [ ] Run detect-private-key
  - [ ] Block merge on security failures
- [ ] Test security checks
- [ ] Document security workflow

### Phase 3: Language Checks (requires Pre-commit Phase 3)

→ Python jobs are done (see CHANGELOG); Perl linting → *Perl Setup* ›
*Pre-commit & CI integration*; Rust is N/A.

- [ ] Matrix testing for multiple bash versions (optional)
- [ ] Test language-specific jobs
- [ ] Document language workflows

### Phase 4: Documentation Validation (requires Pre-commit Phase 4)

→ see *Documentation Setup* for the doc-linting phase context.

- [ ] Add documentation quality job:
  - [ ] Prose linting
  - [ ] Link checking
  - [ ] Documentation build tests
- [ ] Test documentation workflow
- [ ] Document validation process

### Optional: Dependency Updates

- [ ] Create `.github/workflows/update-deps.yml`:
  - [ ] Check for git-completion.bash updates
  - [ ] Check for git-prompt.sh updates
  - [ ] Create PR if updates available
  - [ ] Weekly schedule
- [ ] Test update workflow
- [ ] Document update process

## 📝 Documentation Setup

### Prose linting: adopt Vale for Phase 4

**Research complete (2026-06-26) — decision: adopt Vale.** proselint is
maintained again but **superseded** by Vale here: Vale is a single Go binary
(no Python dep — fits the docker-wrapper/pinned-binary pattern), markup-aware
(Markdown scoping), config-driven, and can even **run proselint's own ruleset**
as a package — so the two overlap and running both is redundant. **Grammarly is
ruled out** (no CLI/headless/CI interface; current offering is an enterprise
B2B REST API). The stale global `dot-general/.proselintrc` is retired in this
change (mirrors the markdownlintrc retirement, PR #149). Full research record
in [`CHANGELOG.md`](CHANGELOG.md).

Implementation follow-up (do when Pre-commit **Phase 4** lands):

- [ ] **Wire Vale into Phase 4.** Add Vale as the prose linter — a pinned
  `docker_wrapper` entry and/or the official pre-commit hook + GitHub Action;
  a repo-local `.vale.ini` selecting curated styles (start minimal — e.g.
  `proselint` and/or `write-good`, scoped to skip code blocks/links so
  technical docs stay quiet); run `vale sync` in setup/CI. Ground a new
  **`config/claude/rules/vale.md`** in Vale's current docs at that point
  (build-on-first-use) and wire it into the tool-detection table + the `qa.md`
  Documentation dimension. *(The `config/claude` parts route to
  `audit/BACKLOG.md` per the TODO convention when authored.)*

### Phase 4: Documentation Linting (pre-commit)

- [ ] Add documentation quality hooks:
  - [ ] Vale (prose linting) — see *Prose linting: adopt Vale*
  - [ ] Additional markdown checks
  - [ ] Link validation
- [ ] Test on repository documentation
- [ ] Update documentation

## ✨ Features & fixes

### parse_params consumer ergonomics

Surfaced while converting `bin/git-branch-clean` to parse_params (PR #150) —
two small polish items for consumers:

- [ ] **Error prefix should honour `--prog`.** Input/constraint errors print
  `parse_params: ...` even when the caller passed `--prog git-branch-clean`,
  leaking the tool name into the consumer's output (`--prog` only changes the
  generated *usage* header). Use the `--prog` name (falling back to
  `parse_params`) as the `bail_input`/`def_err` prefix too.
- [ ] **Document the `SC2154` pattern.** Vars set via `eval
  "$(parse_params …)"` are invisible to shellcheck, so every consumer needs a
  file-scope `# shellcheck disable=SC2154` (see `bin/hr`, `bin/findword`,
  `bin/git-branch-clean`). Add a one-line note to `bash.md` *Argument Parsing*
  so the next converter doesn't rediscover it.

### bin/cleanpath: extend to other path vars

`bin/cleanpath` is fixed, tested (`tests/shell/test_cleanpath.bats`), and
integrated into `shell-startup` (guarded so a failure can't blank PATH).

- [ ] (Optional) Extend to other path vars (`LD_LIBRARY_PATH`, `MANPATH`) if
  duplicates show up there too.

### Shell Helpers

- [ ] Evaluate creating a reusable `select`/menu helper (sibling to
  `yesno`) for enumerated-option prompts
  - Survey existing callers in `bin/` and `config/shell-startup/` that
    roll their own selection logic or use bare `select`
  - Decide: dedicated `bin/` script (like `yesno`, `anykey`) vs. shell
    function in `config/shell-startup/`
  - Required behavior: numbered options, re-prompt on invalid input,
    optional default, quiet mode, return selected value on stdout

### Surfaced from comment cleanup

- [ ] `config/claude/bin/statusline.sh` + `bin/ansi` - check whether tput /
  terminals support OSC 8 hyperlink escapes; if so, extend `bin/ansi` to
  emit them for clickable links repo-wide. (Markers in both files.)

### Tool Configurations

- [ ] Look into lesshst/lesskey configuration
- [ ] Look into taskwarrior scripts from /usr/share/doc/task/scripts/
- [ ] Look into colorized columns tool:
  <https://github.com/LukeSavefrogs/column_ansi.git>

## 🧰 Repository extraction (carve subtrees into their own repos)

Both items below are the same question — extract a subtree into a standalone
repo and decide how dotfiles consumes it (submodule vs sibling clone vs
symlink). Reconcile their consumption decisions together.

### Extract `config/claude/` into its own generic repo

The agent config under `config/claude/` (rules, skills, `CLAUDE.md`,
`EXTENDING.md`, hooks, …) is language- and repo-agnostic and is consumed by
every project, not just dotfiles. Move it to a standalone repo so it can be
shared/versioned independently and carries **no dotfiles-specific references**
(generic — no mention of "dotfiles").

- [ ] **Check first whether such a repo already exists** before creating one —
  scan sibling clones under `$PROJECTS_DIR` and `gh repo list` (candidates to
  rule out: `newdotfiles`, `gollum-config`). As of 2026-06-17 no dedicated
  agent-config repo was found.
- [ ] Carve `config/claude/` out into the standalone repo; scrub
  dotfiles-specific wording so the content reads generically.
- [ ] Decide how dotfiles (and other repos) consume it — submodule, sibling
  clone, or symlink into `$CLAUDE_CONFIG_DIR` — and update the deploy/symlink
  steps and any hardcoded paths.
- [ ] Reconcile with the "Break tmux config into its own repo" item (same
  extraction question: submodule vs sibling).

*Scope note (TODO-routing):* the subject is `config/claude`, but the work is
repo packaging / deployment — a dotfiles concern, not agent behavior — so it
stays here, not in `audit/BACKLOG.md`.

### Break tmux config into its own repo

Move the tmux configuration (or at least enough of it to support the
`tmux-plugins` repos via **git submodules**) into its own dedicated repo.
The submodule setup is what was causing trouble inside this dotfiles repo —
isolating tmux + its plugin submodules avoids tangling submodules into the
main dotfiles checkout.

- [ ] Carve out the tmux config (`config/tmux/`, `bin/tmux_*`, related
  completions) into a standalone repo.
- [ ] Wire `tmux-plugins/*` (e.g. tpm) as submodules in that repo.
- [ ] Decide how dotfiles references it (submodule of dotfiles, sibling
  clone, or independent) and update the deploy/symlink steps accordingly.
- [ ] Clean up `bin/tmux_mode_indicator`'s `set -ex` — the `-x` prints an
  execution trace to stderr on every tmux status render (almost certainly a
  debugging leftover). Can be fixed independently of the extraction.

## 🏠 $HOME dotfile audit

Reduce $HOME clutter by moving dotfiles to XDG directories where supported
and removing unused ones.

Reference: <https://wiki.archlinux.org/title/XDG_Base_Directory>
(comprehensive list of which apps support XDG and how to configure them)

### Migration steps

- [ ] Inventory all dotfiles/dotdirs in $HOME (`ls -la ~ | grep '^\.'`)
- [ ] For each, check the Arch wiki XDG page:
  - If XDG is supported: move file/dir to appropriate XDG location and
    configure the app (env var, config option, symlink, etc.)
  - If XDG is not supported: determine if the app is still in use; remove
    the dotfile if not
- [ ] Update `config/shell-startup/` modules to set any required env vars
  for apps migrated to XDG paths
- [ ] Update dotlinks if any of these were previously managed there
- [ ] After migration, verify apps still work correctly

### Known offenders to investigate (as of 2026-05-20)

| Path | Tool | Notes |
| --- | --- | --- |
| `~/.aider` | aider AI | check if `--config-dir` or `AIDER_CONFIG` supports XDG |
| `~/.cpan` | CPAN | `CPAN::Config` supports custom dirs |
| `~/.cpanm` | cpanm | `PERL_CPANM_HOME` env var |
| `~/.docker` | Docker | `DOCKER_CONFIG` — already set in `010-general` but dir still in `$HOME` |
| `~/.gradle` | Gradle | `GRADLE_USER_HOME` env var |
| `~/.gradle-mcp` | gradle-mcp | likely follows `GRADLE_USER_HOME` or its own config |
| `~/.grok` | grok (xAI CLI) | check XDG / config-dir support (installer block already relocated to `config/shell-startup/grok`) |
| `~/.java` | Java/JVM | `java.util.prefs.userRoot` system property |
| `~/.jbang` | jbang | `JBANG_DIR` env var |
| `~/.kivy` | Kivy | `KIVY_HOME` env var |
| `~/.lesshst` | less | `LESSHISTFILE` env var — set to `$XDG_CACHE_HOME/less/history` |
| `~/.m2` | Maven | `settings.xml` `<localRepository>` or `MAVEN_OPTS` |
| `~/.npm` | npm | `NPM_CONFIG_CACHE` or `.npmrc` `cache=` |
| `~/.redhat` | Red Hat tools | investigate; may not be movable |
| `~/.serena` | Serena AI | check if config path is configurable |
| `~/.sqlite_history` | SQLite | `SQLITE_HISTORY` env var |
| `~/.wget-hsts` | wget | already handled via alias in `010-general` |
| `~/.zshrc` | Zsh | not primary shell; remove if unused |

**Note:** Consider symlinking `~/.config -> $DOTFILES/config` to handle apps
that hardcode `$HOME/.config` rather than respecting `$XDG_CONFIG_HOME`. This
would make both paths resolve to the same location without needing per-app
symlinks. Risk: `~/.config` becomes the canonical store for all XDG config,
so anything the OS or other tools write there lands directly in the repo
working tree — evaluate carefully before implementing.

## 🔄 Upstream / update tracking

How the repo stays current with files and tools that originate elsewhere.

### Vendored file / skill update checker

Some files are **vendored** (copied in from an upstream repo) rather than
authored here — e.g. `config/claude/skills/frontend-design/` from
`anthropics/skills`. Each vendored item carries a `SOURCE.md` recording its
upstream repo, path, and pinned commit SHA (frontend-design has the first
one). We need a way to check whether any vendored item is behind upstream so
we can stay current.

- [ ] Build a checker that finds every `SOURCE.md`, reads `Upstream repo` /
  `Path` / `Vendored SHA`, queries
  `gh api "repos/<repo>/commits?path=<path>&per_page=1"` for the latest SHA,
  and reports which vendored items are BEHIND (optionally show the diff).
- [ ] Decide placement (**leaning toward both**):
  - Option A: `bin/check-vendored` — general, repo-wide; scans for any
    `SOURCE.md` so it works for non-Claude vendored files too.
  - Option B: `config/claude/bin/check-vendored-skills` — Claude-scoped;
    limits to `config/claude/skills/*/SOURCE.md`.
  - Likely both: a general `bin/` core that does the work, plus a thin
    `config/claude/bin/` entry that scopes it to skills.
- [ ] Generalize the `SOURCE.md` provenance convention (repo / path / SHA /
  local-edits) and document it (WORKFLOW.md or a rules file).
- [ ] Consider folding the git-completion `check4update` item below into
  this same mechanism (give those files a `SOURCE.md` too).
- [ ] Optional: wire it to a periodic nudge (Claude `/schedule` or a CI
  `update-deps.yml` job — see CI/CD "Dependency Updates").

### Git-completion dependency checker

- [ ] Create check4update script for git completion files:
  - git-prompt.sh
  - git-completion.bash
- [ ] Set up automated or manual update process

## 🔍 Research and Exploration

- [ ] Look into serena MCP server: <https://github.com/oraios/serena>
- [ ] Look into pyscn tool: <https://github.com/ludo-technologies/pyscn>
  - [ ] Install via: `pipx install pyscn`
- [ ] Document bash changes resource:
  <https://web.archive.org/web/20230401195427/https://wiki.bash-hackers.org/scripting/bashchanges>

## 📋 Template Creation

**Note:** This is extensive future work and may warrant its own project/branch.

### Pre-commit Templates (Deferred)

- [ ] Research comprehensive pre-commit hook registry
- [ ] Create language-specific hook collections
- [ ] Document hook configurations and best practices

### Configuration Templates (Deferred)

- [ ] Python tooling templates (pyproject.toml, .flake8, etc.)
- [ ] General development templates (.editorconfig, .gitignore, etc.)
- [ ] Documentation and markup templates
- [ ] Infrastructure and DevOps templates
- [ ] Language-specific configurations
- [ ] IDE and editor configurations
- [ ] CI/CD templates

See original TODO.md (archived) for detailed template specifications if needed
in the future.
