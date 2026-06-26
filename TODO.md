# TODO - Dotfiles Repository Modernization

**Last Updated:** 2026-06-07
**Plan Version:** Based on Dotfiles Repository Modernization Plan

This TODO file tracks the modernization effort for the dotfiles repository,
organized by work area with phase markers. See `WORKFLOW.md` for development
guidelines and `TESTS.md` for testing strategy.

**Scope:** this file is for **dotfiles** work. Tasks about the **Claude agent
config** (`config/claude/` — rules, skills, hooks, agent-config docs) live in
[`config/claude/audit/BACKLOG.md`](config/claude/audit/BACKLOG.md) instead. See
*Audit the Claude Code Setup* below (and `WORKFLOW.md` → *TODO routing*) for the
full convention.

## 📝 Documentation (HIGH PRIORITY)

### Code Comment Cleanup

- [ ] Address XXX/TODO/FIXME comments (convert to documentation or fix)
  - Active bash/shell markers done: reclassified to `ICEBOX:`/`NOTE:` per
    `code-style.md`, dead-code marker resolved, git-alias bugs fixed
    (`bd`/`bdf`, `unstage`/`uncommit`). The `tmux` and `statusline.sh`
    markers became tracked TODOs (see "Surfaced from comment cleanup").
  - Remaining: PowerShell parity markers, tracked under "PowerShell ↔ Bash
    Feature Parity" below.

## 🛡️ Protect the master Branch — follow-up

`master` is protected (ruleset 17364459: PR-only, squash-only, required
`bats` + `pre-commit`, no bypass; local `no-commit-to-branch` guard).

- [x] Confirm Dependabot interplay with the ruleset — done via the first
  Dependabot PR (#143, actions/checkout 6→7): all required checks (`bats`,
  `perl`, `pre-commit`) passed and the PR is `MERGEABLE`/`CLEAN` under
  squash-only, so the ruleset does not block Dependabot. The "auto-merge"
  clause is N/A by design — `.github/dependabot.yml` deliberately opts out
  of auto-merge; Dependabot PRs land through the normal manual ship-pr
  flow, which this confirms is unobstructed.

## 🧭 Explore other GitHub rulesets (LOW PRIORITY)

We use a single branch ruleset (protect master). Survey what else rulesets
offer and whether any help this repo:

- [ ] Review the available rule types — **tag** rulesets (protect release
  tags from deletion/force-push), **push** rulesets (block large files or
  secrets at push time), required linear history, required deployments /
  code-scanning results, commit-metadata patterns (e.g. enforce Conventional
  Commits subjects), restricted file-path changes, required workflows.
- [ ] Decide which add value here (likely candidates: a tag ruleset for
  release tags; a commit-message pattern enforcing Conventional Commits) and
  capture their configs in `../private_dotfiles/github-rulesets/`.

## 🔑 Investigate GitHub as a secrets vault (MEDIUM PRIORITY)

Secrets currently live as plaintext files in the sibling `private_dotfiles`
repo, loaded by `config/shell-startup/000-loadtokens`. Because they sit in a
*separate* repo that this one references, it's easy to accidentally pull a
secret value into the dotfiles repo (a hardcoded token while debugging, a
value leaked into a committed config) — which *raises*, not lowers, the value
of secret scanning here.

- [ ] Investigate whether GitHub can serve as a secrets vault to replace (or
  back) the plaintext `private_dotfiles/api-key/*` files — e.g. Actions /
  Codespaces / Dependabot secrets, `gh secret`, or a runtime fetch of an
  encrypted store via the `gh` API. Key constraint to assess: Actions secrets
  are only exposed *inside* Actions runs, not in a local login shell, so weigh
  what is actually reachable from the `shell-startup` path. Goal: shrink the
  accidental-ingestion surface.

## 🧹 shell-startup Follow-ups (LOW PRIORITY)

Deferred from the shell-startup trim (PR #16):

- [ ] **Rename the hook dirs — before the startup tests are finalized.**
  `{,.}shell_startup.d` hold *hooks* while `config/shell-startup` holds
  always-loaded files; rename the hook dirs to `{,.}shell_startup_hooks.d` to
  make that obvious. Do this before the containerized startup tests are done
  so they target the final names. Update `load_files`, the pre-setup hook
  path, `run_hook`'s default `$dfdir`, and the directories themselves.

## 🧰 Extract `config/claude/` into its own generic repo (MEDIUM PRIORITY)

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

## 🔗 docker_wrapper Symlink Automation (MEDIUM PRIORITY)

`bin/docker_wrapper` is a multi-call dispatcher: each tool is a `bin/<tool>`
symlink to it, and the tool list lives in the `known_tool` registrations
inside the script. The symlinks are created by hand today, so a newly added
tool — or a fresh checkout — can silently lack its symlink.

- [ ] Add a check that every registered tool has a matching `bin/<tool>`
  symlink pointing at `docker_wrapper`, and that no stray wrapper symlink
  points at it without a registration. Drive it from the `known_tool` keys
  (grep the `known_tool[...]=1` lines, or source the script in a guarded
  mode).
- [ ] Wire that check in as a meta-test (`tests/scaffold/build-meta-tests` /
  `meta_*.bats`, per `TESTS.md`'s symlink validation) so CI flags a missing
  or stray symlink.
- [ ] Add a create/repair mode (a `--fix` flag or a small maintenance
  command) that creates any missing `bin/<tool>` symlinks and reports stale
  ones, so adding a tool or setting up a fresh clone is one command.
- [ ] Assert the link *target* (`docker_wrapper`), not file contents —
  symlink mode is 120000 and unaffected by `core.filemode=false`.

## 📝 bin/markdownlint docker wrapper (MEDIUM PRIORITY)

markdownlint is the only linter in the toolset without a `bin/` docker
wrapper (shellcheck, shfmt, yamllint, prettier, hadolint, trivy, dive all
have one), so `markdownlint` is "command not found" locally. Add it to the
`docker_wrapper` dispatcher using the official image
`ghcr.io/igorshubovych/markdownlint-cli` (versioned tags, e.g. `:v0.48.0`).

- [ ] Add `IMG_MARKDOWNLINT`, a `markdownlint()` function (mount `$PWD`; the
  repo-local `.markdownlint.json` is auto-discovered from the mounted CWD)
  and `known_tool[markdownlint]=1`, plus the `bin/markdownlint` symlink (the
  symlink-automation `--fix` above can create it once registered).
- [ ] Pin the image tag and refresh it alongside the markdownlint-cli
  pre-commit hook rev so the CLI and the hook stay in lock-step.
- [ ] Note: independent of pre-commit — the remote-pinned markdownlint hook
  uses its own node install, not this wrapper (see Pre-commit Configuration).

## 🐳 Research: run more linters/formatters via Docker (MEDIUM PRIORITY)

Today only some tools have a `bin/` docker wrapper (shellcheck, shfmt,
yamllint, prettier, hadolint, trivy, dive — via `bin/docker_wrapper`). Others
(yapf, isort, flake8, perltidy, perlcritic, markdownlint) are "command not
found" unless installed on the host, so a fresh machine is inconsistent and
pre-commit's isolated envs are the only thing that runs them.

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

## 🪟 Break tmux config into its own repo (MEDIUM PRIORITY)

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

## 🧩 dotvim check + clone/link automation (LOW PRIORITY)

dotfiles has no check or setup automation for the companion **dotvim** repo
(vim configuration). Add a check (à la `check-dotfiles`) that dotvim is
present and linked, and ideally a small script to automate cloning it and
creating the symlinks.

- [ ] Add a presence/link check for dotvim (warn if missing or unlinked).
- [ ] Script the clone + symlink setup (idempotent) so a fresh machine gets
  vim configured in one step.
- [ ] Decide dotvim's expected location (sibling clone under `$PROJECTS_DIR`
  per the repo conventions) and reference it consistently.

## 📐 Retire global ~/.markdownlintrc — per-repo configs (MEDIUM PRIORITY)

This repo now uses a repo-local `.markdownlint.json` (authoritative, auto-
discovered by the markdownlint hooks). Each repo should own its markdown
config rather than depend on the global `dot-general/.markdownlintrc`
(symlinked to `~/.markdownlintrc`).

- [ ] Add a repo-local markdownlint config to each other repo that needs one
  (start from this repo's `.markdownlint.json`).
- [ ] Remove `dot-general/.markdownlintrc` and its dotlinks entry once no repo
  relies on the global fallback.
- [ ] Update `config/claude/rules/markdownlint.md` to drop the global once
  it's gone. *(Claude-config step — fine as part of this task; if deferred,
  track it in `audit/BACKLOG.md`. TODO-routing.)*

## 🧹 Meta-suite Gating Debt (MEDIUM PRIORITY)

The shellcheck/shfmt debt across `bin/` and `lib/` is cleared (the pre-commit
check config passes `--all-files`), and the `gmailfilter_toyaml` `perl -c`
(XML::LibXML) debt is gone now that it moved to private_dotfiles. What remains
is gating the generated meta suite. Run `tests/scaffold/build-meta-tests &&
bats tests/shell/*.meta.bats` to see status.

- [ ] Confirm the meta suite is clean across `bin/` + `lib/`, then add it to
  CI and run it in pre-commit. (CI today gates only the hand-written
  `tests/shell/test_*`.)

## 🔁 Audit shell scripts for arg-loop → parse_params (LOW PRIORITY)

Audit done (2026-06-07). `bin/parse_params` replaces hand-written option loops
(see `bash.md` *Argument Parsing*), but it's a perl **subprocess** per call —
a clear win for option-heavy scripts, marginal for tiny 2–4 flag helpers where
`getopts` (a zero-cost builtin) already does the job. No urgent conversions
found; parse_params's real value is for **new** option-heavy scripts. Revisit a
script if it grows more options. Each conversion uses
`_pp=$(parse_params "$DEF" "$@") || show_usage; eval "$_pp"` (or `--auto`) and
updates that script's bats test.

Conversion candidates (dotfiles `bin/`; opportunistic, low priority):

- [ ] `bin/git-branch-clean` — `getopts nfah`; flags fit, but the `-f`/`-n`
  **mutual-exclusion** check stays manual.
- [ ] `bin/git-all` — `getopts :Sv` (two bool flags + positional); small, low
  payoff.
- [ ] `bin/proj` — `case $1` with `-h|--help` plus subcommand dispatch; only
  the option part maps, subcommands stay.
- [ ] `bin/yesno` — small `case $1` (`-h` + warn-suppress); marginal.

Not a fit (skip, with reason):

- `bin/ansi` — its `while` consumes tput *commands* (fg/bg/off…), a variadic
  command stream, not getopt options.
- `bin/where` — variadic list of command names (positional stream), not fixed
  options.
- `lib/docker_helpers` — a sourced library; parse_params works in functions
  but adds a subprocess per call to a hot helper.
- `shell-startup` (`addpath`) — runs at shell init, before `bin/` is reliably
  on `PATH`, and a per-call subprocess at startup is undesirable.

## 🧹 pre-commit doesn't lint extensionless shell files (MEDIUM PRIORITY)

The shfmt and shellcheck pre-commit hooks (`types: [shell]`) **skip
`shell-startup`** and likely the extensionless `config/shell-startup/*`
modules — pre-commit's `identify` isn't tagging them as shell, so they get
no lint/format gating (and the meta generator only scans `bin lib`).
`shell-startup` in fact has pre-existing shfmt debt that nothing currently
catches.

- [ ] Make the shfmt + shellcheck hooks cover extensionless shell files —
  add `files:` patterns (e.g. `^(shell-startup|config/shell-startup/)`) or
  `types_or: [shell, file]`, and confirm via `pre-commit run --files
  shell-startup`.
- [ ] Then clean up the shfmt debt those files surface.
- [ ] Consider adding `shell-startup` + `config/shell-startup` to the
  meta-test generator roots too.

## 🐫 Perl quality tooling (MEDIUM PRIORITY)

Build out perl QA across **both the test suite and the CLI scripts** (where
CLIs exist — e.g. `bin/parse_params`, `bin/perltidyrc-clean`), and make it as
strict as practical, in stages. Capture the resulting toolchain in **agent
rules/skills** (see *Rules & skills* below), not only human setup docs.

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
- [ ] Once perlcritic is clean + enforced, it **unblocks the deferred Perl
  pre-commit hook** (Pre-commit → Phase 3).

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

## 🧰 Tool/Version Manager Setup (perlbrew, nvm, …) (MEDIUM PRIORITY)

Goal: dotfiles should install and configure per-language version/tool
managers consistently, replacing the ad-hoc setup that's accreted over time.
Cover at least **perlbrew** (Perl) and **nvm** (Node), and evaluate the
equivalents for the other languages in play (pyenv/uv for Python, a Ruby
manager; `rustup` is already used). One documented, idempotent install +
shell-init path per manager — XDG-aware where possible, lazy-loaded in
`config/shell-startup/<lang>` to keep shell startup fast.

- [ ] perlbrew: install a pinned Perl + cpanm, then the toolchain the repo
  needs (notably **Perl::Tidy**). A controlled Perl::Tidy that's identical
  across machines **and CI** removes the version drift behind the non-gating
  perl job (see "perl CI: make perltidyrc-clean tests version-robust" above —
  pinning fixes the wording drift; the tests should still be hardened too).
- [ ] nvm: install + lazy-load; pin a default Node.
- [ ] Evaluate/standardize the rest (Python, Ruby; rustup already in use)
  under one consistent pattern, documented in each
  `config/shell-startup/<lang>` module.

## 🤖 grok (LOW PRIORITY)

> **Not a performance item.** Sourcing `grok.bash` is ~0.01s; the "1.54s" in
> the original profile was an xtrace artifact (tracing its 4,545-line
> completion function). This is now purely a cleanliness item.

- [ ] **Move the grok installer block out of `shell-startup`.** The
  `>>> grok installer >>>` block (PATH + completion) at the end of
  `shell-startup` runs *after* Cleanup and isn't a pre-load global — move it to
  a `config/shell-startup/grok` module (guarded like the others). First decide
  how to stop the grok installer re-appending it to `shell-startup` (retarget
  it, or accept periodic cleanup). *[needs thought]*

## 🔍 config/shell-startup Audit (MEDIUM PRIORITY)

Review all files in `config/shell-startup/` for correctness and security:

- [ ] Variables set at module scope but never unset (temporary/setup vars
  that pollute the shell environment)
- [ ] Sensitive values (tokens, keys, paths to secrets) that should be
  handled more carefully or not exported at all
- [ ] Variables exported unnecessarily (does the child process actually
  need it, or should it be local?)
- [ ] Patterns like `source`/`.` that execute arbitrary files without
  checking ownership or permissions
- [ ] Files read without checking they're not world-writable
- [ ] Missing `command -v ... || return 0` guards where a tool may not
  be installed
- [ ] Inconsistent guard style (`if command -v` vs `command -v || return 0`)
  — standardize to `|| return 0` pattern per `000-loadtokens` fix
- [ ] Any other shellcheck warnings not already suppressed with justification

Beyond correctness/security, audit each module for **improve / add / remove**:

- [ ] **Improve**: modernize patterns; fix the lint findings the
  extensionless-files coverage gap currently hides (e.g. terraform's
  `COMPREPLY=($(compgen …))` SC2207, perl's SC1003); cut per-startup cost
  (subprocesses that run at every login).
- [ ] **Add**: tools/integrations worth their own module that aren't covered.
- [ ] **Remove / retire**: modules for tools no longer used; dead or
  commented-out blocks (e.g. perl's `wtf_am_i_doing_here` early-`return`
  function); stale host assumptions.

## 🏠 $HOME Dotfile Audit (MEDIUM PRIORITY)

Reduce $HOME clutter by moving dotfiles to XDG directories where supported
and removing unused ones.

Reference: <https://wiki.archlinux.org/title/XDG_Base_Directory>
(comprehensive list of which apps support XDG and how to configure them)

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

Known offenders to investigate (as of 2026-05-20):

| Path | Tool | Notes |
| --- | --- | --- |
| `~/.aider` | aider AI | check if `--config-dir` or `AIDER_CONFIG` supports XDG |
| `~/.cpan` | CPAN | `CPAN::Config` supports custom dirs |
| `~/.cpanm` | cpanm | `PERL_CPANM_HOME` env var |
| `~/.docker` | Docker | `DOCKER_CONFIG` — already set in `010-general` but dir still in `$HOME` |
| `~/.gradle` | Gradle | `GRADLE_USER_HOME` env var |
| `~/.gradle-mcp` | gradle-mcp | likely follows `GRADLE_USER_HOME` or its own config |
| `~/.grok` | grok (xAI CLI) | check XDG / config-dir support; also relocate the installer block out of `shell-startup` (see the **grok** section) |
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

## 🧪 Testing (HIGH PRIORITY)

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

### Comprehensive BATS Test Coverage Audit (MEDIUM PRIORITY)

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
  (tmux display; also has the `set -ex` leftover to clean — see tmux section),
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

## 🪝 branch-protection hook: exempt gitignored paths (LOW PRIORITY)

**Pain (PR #118 retrospective):** writing an auto-memory note — under the
gitignored `config/claude/projects/*/memory/` dir, a path that can *never*
land in a commit — was blocked by the edit-time `branch-protection.py`
`PreToolUse` hook because `master` was checked out, forcing an unnecessary
throwaway branch just to satisfy the guard. A write that cannot be committed
cannot violate branch protection, so this is a false-positive in a
forcing-function hook (the memory system is meant to be written directly at
any time).

- [ ] **Artifact:** update the existing hook
  `config/claude/hooks/branch-protection.py` (global; symlinked to
  `~/.claude/hooks/`) to **allow** an `Edit`/`Write`/`MultiEdit` whose target
  path is gitignored (e.g. `git check-ignore -q <path>`), since such a write
  can't reach a commit on the protected branch. Keep failing safe (any error →
  allow). Scope: **global** dotfiles agent-config. Confirm it doesn't weaken
  the guard for tracked files.

## 🔭 Audit the Claude Code Setup (MEDIUM PRIORITY)

The Claude Code setup audit's *methodology* is the `claude-audit` skill; its
*record* lives under `config/claude/audit/` — `decisions-log.md` (the "why"),
`BACKLOG.md` (open audit follow-ups), `idea-sources.md` + `mining-census.md`
(mined repos) — indexed by `config/claude/SETUP-AUDIT.md`. None of it is
context-loaded; it is read only when running `/claude-audit`. Audit follow-ups
(e.g. the deferred `pydantic_ai` framework rule, repo-mining shortlists) are
tracked in `audit/BACKLOG.md`, not here, so this repo's `TODO.md` stays about
actual dotfiles work.

**TODO routing convention.** When capturing a follow-up, route it by scope: a
task about the **Claude agent config** (anything under `config/claude/` —
rules, skills, hooks, the agent-config docs) goes in
[`config/claude/audit/BACKLOG.md`](config/claude/audit/BACKLOG.md); a task about
the **broader dotfiles setup** stays in this `TODO.md`. A genuinely **mixed**
task is split into both with a cross-reference — *unless* the parts are merely
coupled (added together, or one can't be done until the other lands), in which
case keep it whole in its primary file and note the other scope inline. Also in
`WORKFLOW.md` → *TODO routing*.

## 🪝 Pre-commit hooks: phased rollout (MEDIUM PRIORITY)

**Key Rule:** CI/CD Phase N requires Pre-commit Phase N completed first.
Pre-commit can progress independently. CI/CD cannot lead pre-commit.

### Phase 1: Core Hooks (DONE)

Core (`.pre-commit-config.yaml`) + fix (`.pre-commit-config-fix.yaml`) configs
are in place, tested, documented (README + `.claude/rules/pre-commit.md`),
wired into CI (`pre-commit run --all-files`), and the CI `pre-commit` check is
required in the master ruleset alongside `bats`.

### Proposed: pre-commit skill, used by qa-check

*Claude-config note (TODO-routing):* a `config/claude` skill. Author it as part
of this work, or move it to `audit/BACKLOG.md` when the pre-commit rollout
completes — don't leave it stranded here.

- [ ] Evaluate a `pre-commit` **skill** packaging the operational workflow
  (fix → check → commit prep; `install` variants; `autoupdate` on suspected
  drift; `validate-config`; `gc`) now documented in
  `.claude/rules/pre-commit.md`. The rule is policy/reference; a skill is the
  forcing function that runs it (cf. qa-check).
- [ ] Have **qa-check** delegate its Format + Lint stages to pre-commit when
  `.pre-commit-config.yaml` is present (run the fix config, then the check
  config) instead of invoking shfmt/shellcheck/etc. directly; fall back to
  direct invocation when pre-commit is not configured.

### Phase 2: Security Hooks (DONE)

gitleaks + detect-private-key are in the check config and both pass
`--all-files`. gitleaks here is a commit-time guard; full-repo/history secret
scanning remains the **security-scan** skill's job (separate from this hook).

### Phase 3: Language-Specific Hooks

- [ ] **Python** (mypy/pyright) — stay CI/on-demand (per `python.md`), not in
  pre-commit. The `yapf` + `isort` + `flake8` hooks and `config/flake8` are
  done (see CHANGELOG); Rust is N/A for this repo.
- [ ] **Perl** — DEFERRED; staged commented in both configs. Blocked on:
  existing `perlcritic --severity 4` debt; `config/perl/perlcriticrc`
  referencing uninstalled policy bundles (OTRS, TryTiny); perltidy version
  drift; and needing perl tools installed in the CI pre-commit job. Enable
  after perlbrew pinning + perlcriticrc trim + debt cleanup.

### Phase 4: Documentation Linting

- [ ] Add documentation quality hooks:
  - [ ] proselint (prose linting)
  - [ ] Additional markdown checks
  - [ ] Link validation
- [ ] Test on repository documentation
- [ ] Update documentation

## 🚀 CI/CD Workflows (HIGH PRIORITY)

**Dependency:** Each CI/CD phase requires corresponding Pre-commit phase.
Current state: `tests.yml` runs bats (gating), perl (non-gating), and python
(self-activating), plus a `pre-commit` job (`--all-files`). The phased plan
below is the remaining buildout.

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

- [ ] Add language-specific jobs:
  - [ ] Python testing and linting
  - [ ] Perl linting
  - [ ] Rust checks (if applicable)
- [ ] Matrix testing for multiple bash versions (optional)
- [ ] Test language-specific jobs
- [ ] Document language workflows

### Phase 4: Documentation Validation (requires Pre-commit Phase 4)

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

## 💻 Code Improvements (LOW PRIORITY)

### bin/cleanpath: extend to other path vars (OPTIONAL)

`bin/cleanpath` is fixed, tested (`tests/shell/test_cleanpath.bats`), and
integrated into `shell-startup` (guarded so a failure can't blank PATH).

- [ ] (Optional) Extend to other path vars (`LD_LIBRARY_PATH`, `MANPATH`) if
  duplicates show up there too.

### PowerShell ↔ Bash Feature Parity (MEDIUM PRIORITY)

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

### Configuration File Issues

- [x] config/git/config - renamed force-delete `bD` to `bdf` so it no
  longer collides with safe-delete `bd` (git config keys are
  case-insensitive); `git bd` now safe-deletes as documented.
- [x] config/git/config - fixed swapped `unstage` / `unadd` semantics:
  both now unstage (`reset HEAD`); added `uncommit` (`reset HEAD^`) for
  undo-last-commit. Documented inline.

(The former `config/bash_prompt:131,137` poetry/venv detection item moved
to an in-code `ICEBOX:`/`NOTE:` at `lib/bash_prompt` — deferred, revisit on
request — per the comment-cleanup pass.)

### Surfaced from comment cleanup (LOW PRIORITY)

In-code `TODO:` markers promoted to tracked items by the comment-cleanup
pass:

- [ ] `config/shell-startup/tmux` - when multiple tmux sessions exist, have
  `ta` list them and let the user choose, instead of always attaching the
  `$USER` session. (Marker at the `ta` definition.)
- [ ] `config/claude/bin/statusline.sh` + `bin/ansi` - check whether tput /
  terminals support OSC 8 hyperlink escapes; if so, extend `bin/ansi` to
  emit them for clickable links repo-wide. (Markers in both files.)

## ⚙️ Configuration Enhancements (LOW PRIORITY)

### Bash Completion

- [ ] Enable bash completion for available but unconfigured tools
- [ ] Document completion setup in dedicated section or inline
- [ ] Create completion tests

### Shell Helpers

- [ ] Evaluate creating a reusable `select`/menu helper (sibling to
  `yesno`) for enumerated-option prompts
  - Survey existing callers in `bin/` and `config/shell-startup/` that
    roll their own selection logic or use bare `select`
  - Decide: dedicated `bin/` script (like `yesno`, `anykey`) vs. shell
    function in `config/shell-startup/`
  - Required behavior: numbered options, re-prompt on invalid input,
    optional default, quiet mode, return selected value on stdout

## 🖥️ Statusline Coordination (MEDIUM PRIORITY)

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

### Task 1: Claude Statusline Script (MEDIUM PRIORITY)

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

### Task 2: Unified Statusline Strategy (LOW PRIORITY — do after Task 1)

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

### Tool Configurations

- [ ] Look into lesshst/lesskey configuration
- [ ] Look into taskwarrior scripts from /usr/share/doc/task/scripts/
- [ ] Look into colorized columns tool:
  <https://github.com/LukeSavefrogs/column_ansi.git>

### Dependency Management

- [ ] Create check4update script for git completion files:
  - git-prompt.sh
  - git-completion.bash
- [ ] Set up automated or manual update process

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
- [ ] Consider folding the git-completion `check4update` item above into
  this same mechanism (give those files a `SOURCE.md` too).
- [ ] Optional: wire it to a periodic nudge (Claude `/schedule` or a CI
  `update-deps.yml` job — see CI/CD "Dependency Updates").

## 🔍 Research and Exploration (LOW PRIORITY)

- [ ] Look into serena MCP server: <https://github.com/oraios/serena>
- [ ] Look into pyscn tool: <https://github.com/ludo-technologies/pyscn>
  - [ ] Install via: `pipx install pyscn`
- [ ] Document bash changes resource:
  <https://web.archive.org/web/20230401195427/https://wiki.bash-hackers.org/scripting/bashchanges>

## 📋 Template Creation (LOW PRIORITY - FUTURE WORK)

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

## 📊 Progress Tracking

- **Documentation:** ~85% complete (foundation laid, XXX cleanup remaining)
- **Testing:** ~70% complete (docker harness + context matrix + parse_params,
  docker_helpers, 000-loadtokens, hr, …; a broad per-script coverage audit and
  Phase 4 remain)
- **Pre-commit:** Phases 1–2 done (core + security, in CI + required); Phases
  3–4 (language, docs) remain
- **CI/CD:** `tests.yml` (bats/perl/python) + `pre-commit` job live; phased
  expansion remains
- **Code Improvements:** ongoing (XXX cleanup cataloged)
- **Config Enhancements:** cataloged, addressed opportunistically

## 🎯 Next Actions (Priority Order)

1. **Perl quality tooling** — curated perlcritic + Test::Perl::Critic,
   Devel::Cover, Pod::Coverage, … (see that section)
2. **Comprehensive BATS coverage audit** — full pass over the remaining bin/
   scripts (Phase 3 wrap-up)
3. **Pre-commit Phase 4** (docs linting) and the phased CI/CD expansion

## Notes

- **HIGH PRIORITY** items should be completed first
- **LOW PRIORITY** items can be deferred or completed incrementally
- Pre-commit phases can progress independently
- CI/CD phases MUST NOT lead pre-commit phases (dependencies enforced)
- Code improvements and config enhancements are cataloged but can be addressed
  opportunistically
- Template creation is extensive future work, deferred for now

## References

- **[CHANGELOG.md](CHANGELOG.md)**: Finalized (completed) work — TODO's
  counterpart; items land there once their PR goes green
- **[WORKFLOW.md](.claude/WORKFLOW.md)**: Development guidelines and conventions
- **[TESTS.md](.claude/TESTS.md)**: Testing framework and strategy
- **[CLAUDE.md](config/claude/CLAUDE.md)**: AI agent behavior specification
- **[config/claude/rules/pre-commit.md](config/claude/rules/pre-commit.md)**:
  Pre-commit agent policy
- **Modernization Plan**: Full plan available in conversation transcript
