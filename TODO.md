# TODO

## 🐫 Perl Setup

The Perl QA toolchain is stood up and gated (perlbrew toolchain; curated
core-severity-4 perlcritic; docker-image perltidy + perlcritic gates;
Test::Pod; non-gating Devel::Cover coverage; setup docs — shipped across
PRs #265–#271, see [CHANGELOG.md](CHANGELOG.md)). Scope decisions on what was
skipped / declined / deferred are recorded in
[ADR-0002](docs/adr/0002-perl-qa-tooling-scope.md). Remaining:

- [ ] **Ratchet the perlcritic severity toward 1, in stages.** The gate is at
  severity 4 (`config/perl/perlcriticrc`); tighten in steps (4 → 3 → 2 → 1),
  cleaning each level's findings before the next. As part of a step, review the
  installed third-party policies for any worth adopting (added to the
  perlcritic docker image + the profile). Bump `severity` in the profile.
- [ ] **Combined tool image (roadmap).** perltidy + perlcritic build from one
  parameterized Dockerfile (`config/docker/perl-tools/`); fold them into a
  single combined image (one build with the full `MODULES` list), and longer
  term investigate one image spanning multiple languages' QA tools. Extend the
  existing layout + `publish-tool-images.yml` — don't restart.

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

## 🔧 Tool/Version Manager Setup

Install and configure per-language version/tool managers consistently: one
documented, idempotent, XDG-aware install + shell-init pattern per manager,
lazy-loaded in `config/shell-startup/<lang>` to keep shell startup fast. Each
language's specific manager lives in its `## <Language> Setup` (perlbrew →
*Perl Setup*; nvm → *Node Setup*); this section owns the **cross-language
pattern** they share.

- [ ] Evaluate/standardize **Ruby** and **rustup** (rustup already in use)
  under the same pattern — a `config/shell-startup/<lang>` module plus a
  `lib/version-managers/<lang>` module. (Node, Python, and Perl are done.)
- [ ] **Pre-installed global manager** (when first needed): handle a machine
  that already has a manager installed system-wide — detect it and decide
  adopt / skip / coexist rather than blindly re-installing.
- [ ] **Mutually-exclusive managers within a language** — the *model* is now
  settled: managers coexist by default (python's pipx/uv/pip), the dispatcher
  allows naming several, and a module enforces any mutual exclusivity in its
  own install logic (not the dispatcher). What remains is the concrete case
  (e.g. nvm vs an alternative Node manager) plus a regression test, once such
  a language actually exists.

## 📦 Machine Provisioning Setup

- [ ] Convert this box's provisioning to **ansible-stuff**
  (`$PROJECTS_DIR/ansible-stuff`): adopt its live-machine playbook (once it
  lands) to upgrade/convert this machine's package set. Package installation
  now lives in ansible-stuff — it superseded the former bespoke `bin/`
  installer plan, and that repo owns the forward roadmap (the
  `manifest.json`-injection seam, `taskwarrior-scalpel` first-party install,
  remaining-language coverage, apt/system packages). This item is the
  dotfiles-side hook into that work. `config/packages/manifest.json` stays
  maintained for now as a candidate source-of-truth an ansible role may
  consume.
- [ ] Vim's needs: install what vim requires that isn't self-provided (coc
  installs most of its own dependencies — scope this to the gaps coc doesn't
  cover, don't duplicate it).

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

- [ ] **non-interactive startup** — `shell-startup` runs to completion
  regardless of interactivity; `zzz-check-dotfiles` / `zzz-check-dotvim` run
  their checks even in a non-interactive shell. Verify nothing prints to
  stdout on a non-interactive source (would corrupt `scp`/`rsync` if `BASH_ENV`
  ever points here); guard with `[[ $- == *i* ]]` if so.

### Move env-polluting shell-startup setup into bin wrappers

Some `config/shell-startup/` modules export tool-specific environment into
*every* interactive shell for a tool that's rarely run — the setup belongs in
an on-demand `bin/` wrapper (set the env, then `exec <tool> "$@"`) so it stops
polluting the global environment. The convention is now written down in
[`.claude/CONVENTIONS.md`](.claude/CONVENTIONS.md) *Shell-startup Module
Placement*; the per-module items below are the actionable findings of the
audit.

- [ ] **aider** — folds into the **AGENTS.md migration** (dotagents
  `audit/BACKLOG.md`), *not* a `bin/aider` wrapper: aider reads AGENTS.md, so
  its `AIDER_*` / `AIDER_EDITOR` / `AIDER_COMMIT_PROMPT` env is made
  client-agnostic there. Remove `config/shell-startup/aider` when that
  migration lands.
- [ ] **ansible** → `bin/ansible` wrapper: it exports only `ANSIBLE_HOME` /
  `ANSIBLE_CONFIG` (+ `mkdir`), nothing shell-facing. Cover the siblings
  (`ansible-playbook` / `-galaxy` / `-vault`) via a shared `bin/_ansible-env`
  the wrappers source.
- [ ] **calibre** → fold its single `CALIBRE_USE_DARK_PALETTE=1` into
  `app_env_vars` (1 setting), or a `bin/calibre` wrapper.
- [ ] **claude** → a `bin/claude` wrapper candidate for
  `CLAUDE_CODE_NO_FLICKER`. First **verify** nothing (hook/tool) reads
  `CLAUDE_CONFIG_DIR` from the ambient env, and coordinate `CLAUDE_CONFIG_DIR`
  with the AGENTS.md migration (client-config).
- [ ] **binenv** (partial) — move `BINENV_CACHEDIR` / `CONFDIR` / `LINKDIR`
  (+ `mkdir`) to a `bin/binenv` wrapper; keep the completion but gate it
  `[[ $- == *i* ]]` and **vendor** it to `config/completions/binenv` (it
  currently forks `binenv` on every shell).

### Shell-startup env-pollution hygiene (from audit)

Keep the module, but fix the pollution it leaves in the interactive shell:

- [ ] **perl** — `unset -f setup_perlbrew setup_dzil setup_prove` at the
  module's end; they linger in the shell namespace after startup.
- [ ] **ssh-config-completion** — make `SSH_KNOWN_HOSTS` / `SSH_CONFIG_HOSTS`
  `local` in the `_ssh` function (they leak to the global shell on each
  completion). *(tmux's `export -f` / `circled_digits` pollution is tracked
  under* Surfaced from comment cleanup *below.)*

### Surfaced from comment cleanup

- [ ] `config/shell-startup/tmux` - when multiple tmux sessions exist, have
  `ta` list them and let the user choose, instead of always attaching the
  `$USER` session. (Marker at the `ta` definition.)
  - From the shell-startup audit: trim env pollution — `export -f ta`
    (and `set_title`/`unset_title`) pushes interactive helpers into every
    child process, and `circled_digits` is set at module scope but never
    unset. Scope or unset them while reworking `ta`.

## 🐳 Docker tooling Setup

### Align `bin/shfmt` with the pre-commit shfmt version

- [ ] The docker `bin/shfmt` wrapper and the pre-commit `shfmt (sourced
  shell)` hook disagree on formatting: `bin/shfmt -d` passed a file whose
  multi-statement one-line function bodies (`f() { a; b; }`) the pre-commit
  hook then reformatted to multi-line, failing the commit. TESTS.md says the
  two are pinned to the same version "so CI results match what runs locally" —
  so this is drift (a version or flag difference). Reconcile them: pin
  `bin/shfmt`'s image to the same shfmt version the pre-commit hook uses (and
  confirm flags match), so a local `bin/shfmt` check predicts the gate.

### Audit other wrappers for the piped-stdin gap (LOW PRIORITY)

- [ ] PR #175 fixed `docker_wrapper`'s `shfmt()` dropping piped stdin (it ran
  `docker run` without `-i`, so `shfmt … < file` saw an empty stream). The
  same latent bug exists in any other wrapper that a caller might pipe into —
  `shellcheck -`, `prettier` via stdin, etc. Nothing in the repo pipes to them
  today, so it's theoretical, but a one-line `[[ -t 0 ]] || args+=(-i)` per
  affected `<tool>()` would make the dispatcher uniformly stdin-safe. Audit
  the wrappers, decide which genuinely accept stdin, and add `-i` to those.

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

- [ ] **Decouple the `markdownlint` pre-commit hook from the host Node
  (retrospective, PR #181).** The `markdownlint-cli@0.48.0` hook uses
  `language: node` against whatever `node` is on `PATH`; it needs Node ≥ 20.
  When the nvm Node was removed during the vmgr migration, pre-commit fell
  back to the system `node v18` and **every commit in the repo was blocked**
  (`EBADENGINE` rebuilding the hook env) until Node 22 was reinstalled. Pin
  the hook's Node so it doesn't depend on the ambient version — set
  `language_version` on the hook (pre-commit installs that Node), or run
  markdownlint via the pinned `bin/markdownlint` docker wrapper instead (ties
  into *Docker tooling Setup*). Lightest reliable option wins.

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

- [ ] **Auto-fix companion for `prose_wrap.py` (78-col reflow).** The
  `prose-wrap` pre-commit check flags >78-col agent-config prose but has no
  `--fix`, so reflowing is manual and **cascades** (moving a word overflows the
  next line) — a recurring agent friction (seen repeatedly, e.g. dotfiles PR
  #255). Investigate a reflow mode (extend `tests/lint/prose_wrap.py`, or a
  markdown-aware wrapper) that rewraps prose paragraphs to 78 cols while
  leaving fenced code, tables, headings, and lists untouched — wired into
  `.pre-commit-config-fix.yaml`. Weigh against the risk of mangling intentional
  line breaks.

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
  the dotagents repo's **`rules/vale.md`** in Vale's current docs at that
  point (build-on-first-use) and wire it into the tool-detection table + the
  `qa.md` Documentation dimension. *(The agent-config parts route to the
  dotagents repo's `audit/BACKLOG.md` per the TODO convention when authored.)*

### Phase 4: Documentation Linting (pre-commit)

- [ ] Add documentation quality hooks:
  - [ ] Vale (prose linting) — see *Prose linting: adopt Vale*
  - [ ] Additional markdown checks
  - [ ] Link validation
- [ ] Test on repository documentation
- [ ] Update documentation

## ✨ Features & fixes

- [ ] **Consider converting `bin/cleanpath` to perl** (same kind of text
  munging). Constraint: core perl modules only — no CPAN (keeps it runnable
  anywhere; avoids the Perl::Tidy/XML::LibXML install gap).

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

- [ ] the dotagents repo's `bin/statusline.sh` + `bin/ansi` - check whether tput /
  terminals support OSC 8 hyperlink escapes; if so, extend `bin/ansi` to
  emit them for clickable links repo-wide. (Markers in both files.)

### Tool Configurations

- [ ] Look into lesshst/lesskey configuration
- [ ] Look into taskwarrior scripts from /usr/share/doc/task/scripts/
- [ ] Look into colorized columns tool:
  <https://github.com/LukeSavefrogs/column_ansi.git>

## 🧰 Repository extraction (carve subtrees into their own repos)

Extract a subtree into a standalone repo and decide how dotfiles consumes it
(submodule vs sibling clone vs symlink). `config/claude` was the first — it
now lives in the **dotagents** repo, consumed as a sibling clone symlinked
into `~/.claude` (see the changelog); its genericize / AGENTS.md follow-up
lives in that repo's own backlog. The tmux extraction below is what remains.

- [ ] **Normalize foreign-repo support in the deploy/link mechanism.** The
  dotlinks / check-dotfiles flow linked `~/.claude` from `$CLAUDE_CONFIG_DIR`;
  that entry was dropped when `config/claude` became the external dotagents
  repo, so sibling foreign repos (dotvim, dotagents, …) are now linked ad hoc
  (manual symlinks). Design first-class, existence-guarded support for
  linking/deploying sibling repos through the dotfiles mechanism (skip when
  the sibling isn't cloned, so a fresh machine degrades cleanly).

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

Reduce $HOME clutter by moving dotfiles to XDG directories where supported and
removing unused ones. The repeatable auditor is [`bin/xdg-audit`](bin/xdg-audit)
(data + model in [`config/xdg-audit/README.md`](config/xdg-audit/README.md)):
plain `xdg-audit` scans `$HOME`; passing an app name shows one app's status;
`--json` emits machine-readable output. Redirects for
Gradle/Kivy/SQLite/Parallel are landed; docker/cpanm/less/npm/wget (and bash
history) are annotated as redirected in `programs-local/`, and the
immovable/unsupported set (Java, nss .pki, cpan, sudo, vscode-server,
redhat) is annotated as ignored.

### Remaining per-app migrations

Each present `$HOME` dotfile gets a `programs-local/<app>.json` entry (redirect
/ ignore / addition) so `xdg-audit` tracks it; the actual per-machine
relocation (moving an install, symlinking) is a separate step.

- [ ] **grok** — convert `~/.grok` to a managed symlink into a repo, like
  `~/.claude` (grok hardcodes `~/.grok` with no relocation env). Tracked via
  overlay; the symlink itself is a per-machine action.
- [ ] Per-machine: clear the leftover strays for the already-redirected tools
  once their new XDG locations are populated.

### xdg-audit follow-ups

- [ ] → **dotagents**: teach the agent config to use `xdg-audit` as part of
  tool setup/configuration — when standing up a tool, check its `$HOME`
  footprint and create the appropriate `programs-local/` overlay entry
  (redirect / ignore / addition) so new tools are XDG-audited by default.
  Cross-repo: migrate to dotagents' `audit/BACKLOG.md` when next working that
  repo.

### `~/.config` symlink — decided in ADR-0003

Adopt in principle (safe: the `config/.gitignore` allowlist keeps stray writes
untracked), but establishing it is a deliberate per-machine migration, not
auto-wired into dotlinks (`~/.config` already exists on every machine, so
`check-dotfiles` would only warn). See
[`docs/adr/0003-home-config-symlink.md`](docs/adr/0003-home-config-symlink.md).

- [ ] Per-machine: migrate an existing `~/.config` into `config/` and replace
  it with the `~/.config -> $DOTFILES/config` symlink, where wanted.

## 🐙 GitHub repository audit

- [ ] Go through all my GitHub repositories and decide each one's
  disposition — **delete**, **make a public archive**, **bring up to date**,
  or **leave alone**. One-time triage; record the decision per repo.

## 🔄 Upstream / update tracking

How the repo stays current with files and tools that originate elsewhere.

### Vendored file / skill update checker

Some files are **vendored** (copied in from an upstream repo) rather than
authored here — e.g. the dotagents repo's `skills/frontend-design/` from
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
  - Option B: the dotagents repo's `bin/check-vendored-skills` — Claude-scoped;
    limits to the dotagents repo's `skills/*/SOURCE.md`.
  - Likely both: a general `bin/` core that does the work, plus a thin
    dotagents repo `bin/` entry that scopes it to skills.
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

- [ ] Look into pyscn tool: <https://github.com/ludo-technologies/pyscn>
  - [ ] Install via: `pipx install pyscn`
- [ ] Document bash changes resource:
  <https://web.archive.org/web/20230401195427/https://wiki.bash-hackers.org/scripting/bashchanges>
- [ ] Consider adopting the old **`gitperms`** repo to record and restore
  full file permissions in a repository. Git stores only the executable bit
  (`100644` vs `100755`), not group/other read-write — so tightening files to
  owner-only (`700`/`600`, e.g. across a `bin/`) can't be committed (surfaced
  while committing harleydev `bin/` permission changes). A `gitperms`-style
  manifest + restore hook can carry the bits git drops. **If adopted, the
  global `~/.claude` config must be updated to manage it** — a rule (and
  likely a hook) teaching the agent to record/restore and verify permission
  state, the way it manages other repo tooling.

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
- [ ] GitHub issue templates — wire the new-project setup/conversion to
  scaffold `.github/ISSUE_TEMPLATE/` (bug, test, documentation, enhancement),
  matching the harleydev naming.

See original TODO.md (archived) for detailed template specifications if needed
in the future.
