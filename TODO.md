# TODO - Dotfiles Repository Modernization

**Last Updated:** 2026-06-07
**Plan Version:** Based on Dotfiles Repository Modernization Plan

This TODO file tracks the modernization effort for the dotfiles repository,
organized by work area with phase markers. See `WORKFLOW.md` for development
guidelines and `TESTS.md` for testing strategy.

## 📝 Documentation (HIGH PRIORITY)

### Code Comment Cleanup

- [ ] Address XXX/TODO/FIXME comments (convert to documentation or fix)
  - See "Code Improvements (LOW PRIORITY)" section for detailed list

## 🛡️ Protect the master Branch — follow-up

`master` is protected (ruleset 17364459: PR-only, squash-only, required
`bats` + `pre-commit`, no bypass; local `no-commit-to-branch` guard). One
follow-up remains:

- [ ] Confirm Dependabot / auto-merge interplay once a Dependabot PR appears
  (squash-only + required checks — ensure auto-merge still completes).

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

## 🔎 CodeFactor & Snyk: Use Their Output? Rule/Skill? (MEDIUM PRIORITY)

Both run as PR checks (alongside `bats`), but we don't yet act on their
findings. Research how to actually use each and whether to formalize it.

- [ ] **CodeFactor**: what it analyzes, where findings surface (PR inline
  comments, the codefactor.io dashboard, the badge), how to configure it
  (`.codefactor.yml`), and how to triage/suppress. Decide if it earns a
  required status check.
- [ ] **Snyk** (`security/snyk`): what the check scans (deps / code / IaC?),
  where findings live (app.snyk.io, PR annotations), its auth/config, and how
  it overlaps with Dependabot and the existing security rules
  (`semgrep`/`trivy`/`osv-scanner`) plus the `security-scan` skill.
- [ ] Decide **per tool**: a `config/claude/rules/<tool>.md` (how to read and
  act on its output), a skill, folding into the existing `security-scan` skill
  / `qa.md` security dimension, or nothing — without duplicating what those
  already cover.
- [ ] If a tool adds no actionable value, consider disabling its check to cut
  PR-check noise; if it does, document the triage workflow.

## 🔐 Evaluate trufflehog & Checkmarx scanners (MEDIUM PRIORITY)

Two candidate security scanners to weigh for pre-commit and/or GitHub
Actions. For each, determine what it scans, how it overlaps with the tools
already in play (gitleaks/detect-private-key, the `security-scan` skill,
`semgrep`/`trivy`/`osv-scanner`), and where it belongs — then fold any
adoption into the `security-scan` skill / `qa.md` security dimension rather
than wiring it as a one-off.

- [ ] **trufflehog** (secret scanning): evaluate adding it to pre-commit and
  GitHub Actions, and how it complements the existing secret-scanning story —
  gitleaks is the commit-time guard (Pre-commit Phase 2) and full-repo/history
  scanning is the `security-scan` skill's job. Decide whether trufflehog's
  verified-secret detection augments or replaces either, and where it runs
  (commit-time hook vs CI vs the skill).
- [ ] **Checkmarx** (SAST): evaluate adding it to pre-commit and/or GitHub
  Actions; compare against the existing SAST layer (`semgrep`) and decide
  whether it earns a place. Ties into the perl-SAST investigation under "Perl
  quality tooling → Security scanning", which already flags Checkmarx for its
  believed perl support.

## 🧹 shell-startup Follow-ups (LOW PRIORITY)

Deferred from the shell-startup trim (PR #16):

- [ ] **Rename the hook dirs — before the startup tests are finalized.**
  `{,.}shell_startup.d` hold *hooks* while `config/shell-startup` holds
  always-loaded files; rename the hook dirs to `{,.}shell_startup_hooks.d` to
  make that obvious. Do this before the containerized startup tests are done
  so they target the final names. Update `load_files`, the pre-setup hook
  path, `run_hook`'s default `$dfdir`, and the directories themselves.

## 🧭 Audit Project .claude/ Dirs for Promotable Rules/Skills (MEDIUM PRIORITY)

Review every repo under `$PROJECTS_DIR` and decide, per the three-tier model
in `CLAUDE.md`, whether anything repo-local in its `.claude/` should be
promoted to the global config (`config/claude/rules/` or `.../skills/`).

- [ ] Enumerate projects with a `.claude/`:
  `find "$PROJECTS_DIR" -maxdepth 2 -name .claude -type d`.
- [ ] For each, compare its `rules/`, `skills/`, and CONVENTIONS/WORKFLOW/
  TESTS against the global set; flag anything language- or repo-agnostic
  (tier 1/2) that's repo-local or duplicated.
- [ ] Promote tier-1/2 items to global `config/claude/rules/<name>.md` or
  `config/claude/skills/`; leave truly repo-specific bits in place.
- [ ] Consolidate drift: the same rule copied (and diverging) across repos
  should become one global source that repos reference.
- [ ] Note any project that lacks a `.claude/` but should have one.

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

## ✅ Move gmailctl scripts to private_dotfiles (DONE 2026-06-07)

`gmailfilter_toyaml` and `filter_gmail` support **gmailctl** (sensitive Gmail
config) and `filter_gmail` is explicitly marked "contains sensitive data" with
a hardcoded personal path — they only run from `private_dotfiles`.

- [x] Moved both to `private_dotfiles/bin/` (a new `bin/` there, beside the
  `.gmailctl/` config + gmail certs).
- [x] Removed their entries from `docs/bin.md` (also dropped the stale
  `poetry2setup` entry — that script was archived earlier).
- [x] Retired the public meta-suite `perl -c` debt for `gmailfilter_toyaml`
  (it needed `XML::LibXML`) — it has left the public repo.

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

## ✅ bin/creds-helper PAT fallback bug (DONE 2026-06-07)

When the credential wasn't found in `~/.netrc`, `creds-helper` checked
`$PROJECTS_DIR/private_dotfiles/api-key/github` but then read a **different**,
unset `$PAT_FILE` (`< ""` → error) instead of the PAT.

- [x] Read the file it checked (via a single `pat_file` variable).
- [x] Also made it exit 0 when it has no credential (a helper shouldn't fail
  just because it has no answer).
- [x] `tests/shell/test_creds-helper.bats` — netrc hit, netrc-miss → PAT
  fallback (the regression), netrc-wins precedence, and the no-credential
  no-op.

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
  it's gone.

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

- [x] `bin/hr` — converted to parse_params (the worked example); its title is
  a `#@` slurp positional. `tests/shell/test_hr.bats`.
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

## 🐪 perl CI: promote to a required check (MEDIUM PRIORITY)

- [x] Made the perl test assertions **version-robust** — assert *that a problem
  was reported* (non-zero code / non-blank message), not the exact Perl::Tidy
  wording or exit code (old Perl::Tidy treats a missing perltidyrc as a
  warning, err 2, not an error, err 1), and key parse_params `-h` on POD body
  rather than pod2usage header formatting. Fixed across `call_perltidy.t`,
  `get_perltidy_config.t`, `integration.t`, `parse_params-modes.t`. The perl
  job is now green on the runner's older Perl::Tidy.
- [x] Dropped `continue-on-error` from the perl job — it now gates the CI run.
- [x] Added `perl` to the master ruleset's required status checks (now
  `bats` + `perl` + `pre-commit`); applied live to ruleset 17364459 and
  recorded in `../private_dotfiles/github-rulesets/protect-master-solo.json`.

## 🐫 Perl quality tooling (MEDIUM PRIORITY)

Build out perl QA across **both the test suite and the CLI scripts** (where
CLIs exist — e.g. `bin/parse_params`, `bin/perltidyrc-clean`), and make it as
strict as practical, in stages.

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

- [ ] Look into perl SAST: investigate **Checkmarx** (believed to support
  perl) and open-source alternatives, and fold any perl SAST into the
  `security-scan` skill / `qa.md` security dimension rather than a one-off.

### Setup / documentation

- [ ] Document installation + setup for **all of the above** (Perl::Critic +
  the chosen policy dists, Test::Perl::Critic, Devel::Cover, Pod::Coverage /
  Test::Pod::Coverage / Test::Pod, B::Lint, Perl::Analyzer, any perl SAST)
  alongside the existing setup docs (WORKFLOW.md *Tool Setup Procedures* /
  Prerequisites). Use the repo's standard install path — perlbrew + cpanm (see
  *Tool/Version Manager Setup*) or pinned docker wrappers — so a fresh machine
  reproduces the whole perl QA toolchain from one documented place.

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

## 🐢 Login shell slowdown — RESOLVED (~1.1s, was 5.8–7.25s)

A login shell had regressed to 3–5s (peaks ~7s). Fixed by the cleanpath +
`havecmd` work; now a stable **~1.05–1.15s**, under the original <2s baseline.

**Profiling caveat (important).** Both `bash -lixc` (xtrace) **and** `DEBUG=1`
*inflate* any module that runs many lines or calls `debug()` internally
(`check-dotfiles`, `cleanpath`). Several early "findings" were measurement
artifacts — grok 1.54s / nvm 0.95s / check-dotfiles 220ms / less-probe 67ms
all evaporated when measured directly (real: ~0.01s / ~0s / ~25ms / ~0s).
**Measure a suspect module directly (non-DEBUG) before optimizing it.**
`lib/debug` now prints a `+Nms` delta for per-step timing, but only trust it
for modules that don't themselves call `debug`.

- [x] **cleanpath** — parallelized per-entry `readlink` with `xargs -P`
  (sequential fallback; GNU `parallel` benchmarked *slower* for many tiny
  jobs). Real cost ~145ms: the largest single login cost, already optimized —
  only a rewrite (e.g. perl) would help further.
- [x] **`command -v` probe tail** — added `havecmd` (a `command -v` wrapper
  that drops `/mnt/c` for one lookup, then restores PATH) and converted every
  boolean-guard probe in `config/shell-startup/*`. The biggest real win.
- [x] **bash_prompt** — the prompt called `ansi` (a subprocess) on *every*
  render for constant colors; moved all color computation to load time in the
  `config/shell-startup/bash_prompt` wrapper so rendering spawns no `ansi`
  (~16ms/render). `_HAS_PSTREE`/`_HAS_PACMAN_STATUS` cached at load; `loadavg`
  (bin) called unconditionally. Tested via `tests/shell/test_havecmd.bats` +
  manual render checks.
- [x] **debug wiring** — `shell-startup` and `check-dotfiles` sourced the
  nonexistent `bin/debug` (the lib moved to `lib/debug`), so `DEBUG=1` did
  nothing; pointed both at `lib/debug`, guarded on `DEBUG`.
- **Left alone (accepted costs):**
  - **`git-status` ~99ms/render** — does necessary work for the git-aware
    prompt; only async/caching would cut it, not worth the complexity.
  - **grok / nvm** — not real costs (xtrace artifacts); no lazy-load needed.

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
- [x] Helper functions in `tests/helpers/common.bash` (`load_bats_libs`,
  `dotfiles_root`, `make_stub`, docker harness)

### Phase 3: Core Test Coverage

- [x] shell-startup (DOTFILES detection, PATH building, module loading) —
  `tests/shell/test_integration_startup.bats` + `test_integration_context.bats`
  (full context matrix) in the docker harness.
- [ ] Add tests for critical bin/ scripts
  - [x] cleanpath (unit tests) — `tests/shell/test_cleanpath.bats`
  - [x] yesno (unit tests) — `tests/shell/test_yesno.bats`
  - [x] git-status (integration tests) — `tests/shell/test_git_status.bats`
        (skips the prompt assertion if system `git-prompt.sh` is absent)
  - [x] check-dotfiles (integration tests) —
        `tests/shell/test_integration_check_dotfiles.bats`, run in the docker
        harness so its `ln -fs` into `$HOME` can't touch the host.
- [ ] Add tests for lib/ libraries
  - [x] debug — `tests/shell/test_debug.bats`
  - [x] parse_params — **rewritten in core-only perl as `bin/parse_params`**
        (the old bash `lib/parse_params` was broken — it `source`d a long-gone
        `utility` lib + missing is_char/is_integer/verify_filename — and is
        archived to `archive/lib/`). Emits `eval`-able shell assignments
        (`_pp=$(parse_params "$DEF" "$@") || show_usage; eval "$_pp"`) so it
        replaces hand-written `while` arg loops. Fixed the original's design
        flaws: no code-gen/eval, no shell-killing `die` (it's a subprocess),
        safe quoting, clear exit codes (0/1/2). New features: signed integers,
        negatable booleans (`--no-x`, DEFAULT 0|1 for default-on), repeatable
        `type@` → shell arrays, fixed + `#@` slurp positionals, `--prog`,
        turnkey `--auto`, POD-driven `--help` (Pod::Usage) + `--usage`. Tests:
        `tests/perl/parse_params-{options,types,boolean,errors,modes}.t` (85).
  - [ ] **Consider converting `bin/cleanpath` to perl** (same kind of text
        munging). Constraint: core perl modules only — no CPAN (keeps it
        runnable anywhere; avoids the Perl::Tidy/XML::LibXML install gap).
  - [x] docker_helpers — `tests/shell/test_docker_helpers.bats` (20 cases).
  - (`is`, `Arrays`, `strings` archived to `archive/lib/`; `git-prompt`
    factored into `bin/git-status` — not tested.)
- [ ] Add tests for config/shell-startup/ modules
  - [x] `000-loadtokens` — `tests/shell/test_000-loadtokens.bats` (conditional
    token loading, comment/missing-file skips, no-op when absent, temp-var
    cleanup). The one module with real standalone logic worth isolating.
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

- [x] `where` — `tests/shell/test_where.bats` (keyword/builtin/file/not-found).
  Surfaced + fixed two bugs: a missing command hit the "Unexpected type"
  branch (modern `type -t` prints nothing for unknowns), and it exited 1 even
  on success.
- [ ] (reclassified to integration) `showvars` — needs `shfmt` (docker
  wrapper) + `jq`; covered under the integration group, not pure-unit.
- [x] `creds-helper` — `tests/shell/test_creds-helper.bats`; landed with the
  PAT-fallback bug fix (see its section above).
- [x] `available-subnets` — **removed** (obsolete: old GCP-subnet tooling no
  longer used); archived to `archive/bin/`. No test needed.
- [ ] (marginal) `loadavg` (output depends on real load), `dateh` (date-format
  table — mostly display).

**Integration (external tools / state) — to do:**

- [x] `git-branch-clean` — `tests/shell/test_git-branch-clean.bats` (guards +
  gone-upstream dry-run/force/never-pushed, against a throwaway repo with a
  local bare remote).
- [x] `git-all` — `tests/shell/test_git-all.bats` (usage/REPOHOME/option
  guards, run-across-repos summary, `-S` dirty-only). The test exposed that
  git-all was **completely broken** under `set -euo pipefail` (three cascading
  bugs, all masked by the first) — all fixed: the `read -d '' < <(find)` abort
  (→ `mapfile -t`), the `grep && printf` abort on a clean repo (→ `if`), and
  empty-array expansion under `set -u` (→ `declare -a fail=()` etc.).
- [x] `proj` — `tests/shell/test_proj.bats` (no-arg/existing path, -h, unknown
  option, too-many-args, unset PROJECTS_DIR, and the select menu create/cancel
  paths via stdin). No bugs found.
- [x] `ansi` — `tests/shell/test_ansi.bats` (usage, TERM=dumb no-color
  fallback, escape-sequence emission, `-sb` PS1 delimiters, hex color). No
  bugs found.
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

## 🧠 Claude Rules Files (MEDIUM PRIORITY)

Rules files in `config/claude/rules/` (global, `~/.claude/rules/`) tell the
agent how to use each tool. Already have, among others: bash, perl,
powershell, pre-commit, python, shellcheck, shfmt, yamllint, markdownlint,
yapf, git, gh, bats, docker (plus `.editorconfig` coverage for shfmt).

- [ ] Remaining rules to author:
  - [ ] new project setup — rule covering the general checklist for
    initializing a project (git init, pre-commit, .claude/ scaffold,
    DEVELOPER.md, TODO.md, etc.); evaluate splitting language-specific
    bootstrapping steps (e.g. NeoForge MDK, Poetry, npm init) into the
    relevant per-language rules file rather than bloating the general rule.
    Points to consider from experience:
    - Investigate actual storage/file formats before designing around them;
      official docs may describe outdated formats (e.g. JourneyMap switched
      from per-waypoint JSON to a binary DAT in 6.x without updating docs)
    - Check whether related/foreign repos are already cloned as siblings
      before suggesting clone locations (../reponame convention)
    - Defer .claude/ scaffold until project-specific conventions emerge;
      Phase 0 setup rarely produces enough repo-specific content to justify it
    - Editor config belongs in the editor's own config repo, not the project;
      DEVELOPER.md should note the maintainer's editor but not prescribe setup
    - When adding language support to an editor config, verify that
      indentation and formatting settings match the chosen formatter's output
      rather than blindly following language community conventions (e.g.
      google-java-format uses 2-space, not the traditional 4-space Java style)
    - New project setup frequently exposes gaps in existing global config
      (missing docs, redundant settings, stale paths); capture these as
      follow-up items in the relevant repo's TODO rather than blocking setup
    - DEVELOPER.md should cover the full build/test workflow including
      platform-specific quirks (e.g. build in WSL2, test in Windows Minecraft)
    - Pin pre-commit hook versions to current stable at time of setup;
      note that versions need periodic review as hooks release updates
    - Document the rationale for non-obvious decisions (e.g. why 2-space
      Java indent) so future sessions don't relitigate them
  - [ ] commitizen — rule and/or skill for conventional commit message
    formatting; evaluate whether a rule (policy + invocation) is sufficient
    or whether the multi-step workflow warrants a skill
  - [ ] git tagging — rule and/or skill for version tag conventions (semver
    vs calver, signed vs unsigned, when to tag vs branch, how tags relate
    to release branches); likely a rule unless the tagging+push+release
    sequence is complex enough to warrant a skill
  - [ ] changelog generation — rule and/or skill for producing changelogs
    from git history on version changes; evaluate tools (git-cliff,
    conventional-changelog, keep-a-changelog manual pattern) and whether
    changelog generation should be part of a broader release skill alongside
    tagging and commitizen
  - [ ] Any other tools discovered during pre-commit or CI work
- [ ] Add a "best practices" rules/skills layer. The current
  `rules/code-style.md` may be better recast as a general best-practices
  document with language-specific subdocuments — i.e. a shared core that
  per-language rules files extend. Decide structure: one general
  best-practices doc + per-language extensions, vs. keeping `code-style.md`
  as the shared base that the language rules reference.
- [ ] When creating/modifying a rule or skill, check known sources for an
  existing implementation to adapt (vendor with a `SOURCE.md` and audit to
  fit) rather than authoring from scratch:
  - GitHub (search repos/topics)
  - <https://github.com/VoltAgent/awesome-agent-skills>
  - <https://officialskills.sh/>
  - other locations as discovered
  Ties into the vendored file/skill update checker (see Configuration
  Enhancements → Dependency Management).

## 🪝 Claude Code PostToolUse Hooks (MEDIUM PRIORITY)

Rules files instruct the agent to run shellcheck/shfmt, but only if the agent
remembers. `PostToolUse` hooks in `settings.json` enforce this automatically
after every `Edit` or `Write` on a shell file.

- [ ] Decide hook approach:
  - Option A: inline command in `settings.json` (simple, but not version-controlled
    separately from settings)
  - Option B: `config/claude/bin/post-edit-shell.sh` script invoked by the hook
    (keeps logic in a file, easier to maintain)
- [ ] Implement hook in `config/claude/settings.json`:
  - Match on `Edit` and `Write` tool use
  - Detect if the modified file is a shell file (by path pattern or shebang)
  - Run `shfmt -i 2 -s -bn -ci -sr -w <file>` then `shellcheck <file>`
  - Output failures so Claude sees them and can fix before continuing
- [ ] Research Claude Code hook input format: what env vars / stdin does a
  `PostToolUse` hook receive? (need file path of edited file)
- [ ] Document hook setup in this repo's WORKFLOW.md once stable

## 🧩 Audit Claude Code Plugins + MCP Servers (MEDIUM PRIORITY)

Enabled plugins live in `~/.claude/settings.json` (`enabledPlugins`); each is
cached under `~/.claude/plugins/`. **MCP servers in this setup are provided by
plugins** — an enabled plugin may bundle its own `.mcp.json` (e.g. the github
plugin shipped a *hosted* server at `https://api.githubcopilot.com/mcp/`
authed via `${GITHUB_PERSONAL_ACCESS_TOKEN}`). There is no hand-maintained
global `mcp.json`, so auditing plugins **is** auditing the MCP surface. The
standing convention is captured in `config/claude/rules/mcp.md`.

- [ ] **Inventory** every enabled plugin: what it does, whether it bundles an
  MCP server, and whether we actually use it.
- [ ] **Cull** plugins that duplicate the `gh` CLI / existing rules+skills or
  go unused. (github plugin already being removed — its hosted MCP server
  authed with `GITHUB_PERSONAL_ACCESS_TOKEN`, a *different* token than the gh
  CLI's `GH_TOKEN`; that mismatch was the earlier "sketchy github responses".)
- [ ] **Gaps**: identify capabilities we want but have no plugin for.
- [ ] **Record decisions** (keep/remove + why) so the audit is repeatable.
- [ ] Create a **rule and/or skill to run this audit routinely** — multi-step
  (inventory → classify → cull → gap-check) ⇒ likely a *skill* per the "When
  to Propose a Skill" threshold in `CLAUDE.md`. Evaluate the existing
  `claude-code-setup:claude-automation-recommender` plugin for the gap-finding
  part before authoring from scratch.
- [ ] **Cadence:** run the *detailed* audit on a short recurring interval (it
  should not be a long time between runs — e.g. monthly), not just once. Wire
  the audit skill to a reminder / `/schedule` routine so it recurs.
- [ ] **Plugin-aware proposals (behavior rule):** when proposing a new
  language/tool *rule* or *skill* for a capability, also check whether a
  **plugin** already provides it (or whether one should be added). Extend
  `CLAUDE.md`'s *Missing or Conflicting Tool Rules* + *When to Propose a Skill*
  sections and the `rule-coverage.py` hook to cover plugins, not just
  rules/skills. (Plugins can bundle commands, skills, subagents, hooks, and
  MCP servers — so they are a first-class option alongside a rule or skill.)

## 🔒 Pre-commit Configuration (HIGH PRIORITY)

**Key Rule:** CI/CD Phase N requires Pre-commit Phase N completed first.
Pre-commit can progress independently. CI/CD cannot lead pre-commit.

### Phase 1: Core Hooks (DONE)

Core (`.pre-commit-config.yaml`) + fix (`.pre-commit-config-fix.yaml`) configs
are in place, tested, documented (README + `.claude/rules/pre-commit.md`),
wired into CI (`pre-commit run --all-files`), and the CI `pre-commit` check is
required in the master ruleset alongside `bats`. One follow-up remains:

- [x] Update all `config/claude/rules/*.md` Agent Behavior sections to
  prioritize pre-commit over direct tool invocation — added a canonical
  *Prefer pre-commit Over Direct Tool Invocation* section to `pre-commit.md`
  and pointed all 17 tool rules (bash, shellcheck, shfmt, yamllint,
  markdownlint, yapf, isort, flake8, black, ruff, biome, perl, powershell,
  docker, hadolint, vitest, TEMPLATE) at it; direct invocation is now the
  documented fallback when pre-commit isn't configured / doesn't cover a file.

### Proposed: pre-commit skill, used by qa-check

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

- [x] **Python** — wired the repo's actual toolchain (`yapf` + `isort` +
  `flake8`, **not** black/mypy): `isort --check` + `yapf -d` + `flake8` in the
  check config, `isort` + `yapf -i` in the fix config. Added `config/flake8`
  (reconciles flake8 with yapf's 2-space style) and
  `config/claude/rules/flake8.md`. All Python is gated (no excludes):
  `rule-coverage.py` and `bin/available-subnets` reformatted to pass (added
  `E265,E266` to `config/flake8` to honor the `#####`/`#----` separators);
  `bin/poetry2setup` archived to `archive/bin/` (legacy setup.py generator, no
  longer needed).
  - [ ] mypy/pyright stay CI/on-demand (per `python.md`), not in pre-commit.
- [ ] **Perl** — DEFERRED; staged commented in both configs. Blocked on:
  existing `perlcritic --severity 4` debt; `config/perl/perlcriticrc`
  referencing uninstalled policy bundles (OTRS, TryTiny); perltidy version
  drift (the perl CI job is already non-gating for this — see "perl CI"); and
  needing perl tools installed in the CI pre-commit job. Enable after perlbrew
  pinning + perlcriticrc trim + debt cleanup.
- [x] **Rust** — N/A (no Rust in this repo); noted in the config.
- [x] Update fix configuration with language-specific auto-fixes (isort, yapf).
- [x] Test with actual project files (rule-coverage.py passes; full check run
  green).
- [x] Update documentation (`flake8.md` added; `python.md`/`yapf.md`/`isort.md`
  already cover the tools).

### Phase 4: Documentation Linting

- [ ] Add documentation quality hooks:
  - [ ] proselint (prose linting)
  - [ ] Additional markdown checks
  - [ ] Link validation
- [ ] Test on repository documentation
- [ ] Update documentation

## 🔧 Bump GitHub Actions off Node.js 20 (MEDIUM PRIORITY)

CI runs surface deprecation warnings: `actions/checkout@v4` (×4) and
`actions/setup-python@v5` (×2) in `.github/workflows/tests.yml` run on
Node.js 20, which GitHub forces to Node 24 by default on 2026-06-16 and
removes from runners on 2026-09-16.

- [ ] Bump `actions/checkout@v4` → `@v5` (already used in `opencode.yml`)
  and `actions/setup-python@v5` → a Node 24-compatible release in
  `tests.yml`, clearing the deprecation warnings. Re-check the run's
  annotations afterward for any other actions still on Node 20.

## 🚀 CI/CD Workflows (HIGH PRIORITY)

**Dependency:** Each CI/CD phase requires corresponding Pre-commit phase.
Current state: `tests.yml` runs bats (gating), perl (non-gating), and python
(self-activating), plus a `pre-commit` job (`--all-files`). The phased plan
below is the remaining buildout.

### Phase 1: Basic CI (requires Pre-commit Phase 1)

- [ ] Consolidate/confirm the CI workflow:
  - [x] Run on push to master and on pull requests (`tests.yml`)
  - [x] Execute BATS tests; run shellcheck/yamllint/markdownlint via the
        `pre-commit` job
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

- [ ] config/bash_prompt:131,137 - Fix poetry/venv detection and colors (XXX)
- [ ] config/git/config:239-240 - `bd` / `bD` aliases collide because git
  config keys are case-insensitive. `bD` overwrites `bd`, so `git bd`
  force-deletes instead of safe-deleting. Rename `bD` to a case-distinct
  key (e.g. `bdf` for force-delete) so both intents are reachable. See
  XXX comment in file.
- [ ] config/git/config:199-200 - `unstage` / `unadd` have swapped
  semantics relative to common terminology: `unstage` resets to HEAD^
  (undoes last commit), `unadd` resets to HEAD (actual unstage). Either
  rename for clarity or document the convention in docs/git_aliases.md.
  See XXX comment in file.

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

## 🤖 Claude Code -> local OpenWebUI offload (HIGH IMPORTANCE, LOW PRIORITY)

**Importance: high** (cost, privacy, and actually leveraging the dedicated
AI box, `beaker`). **Priority: low** (exploratory; depends on beaker's GPU
stack being finished and on finding the right integration point).

Idea: route the simpler, high-volume Claude Code subtasks to a locally
hosted model served from my own OpenWebUI/Ollama on `beaker` (see
`bin/openwebui`, `bin/ollama`), keeping the heavy reasoning on Claude.
Start with cheap, well-bounded work — qa-check triage, running and
evaluating test output, summaries — then generalize.

- [ ] Find the integration surface. Claude Code's main loop is
  Anthropic-only, so investigate the realistic hook points:
  - a **hook** (`PostToolUse`, etc.) that shells out to a local-LLM
    script for a specific check;
  - a **subagent** or **MCP server** that wraps the local endpoint;
  - the **Claude Agent SDK** for a custom delegating agent.
- [ ] Pick the API: OpenWebUI exposes an OpenAI-compatible endpoint;
  Ollama serves its own API on `:11434`. Decide which to target.
- [ ] Choose local model(s) sized for beaker's RTX 4080 (~12 GB VRAM) and
  capable enough for the offloaded tier (code-aware small/mid models).
- [ ] Define the task split: what is safe to delegate (triage, test-output
  evaluation, summarization) vs. what stays on Claude.
- [ ] Evaluate quality / cost / latency on real tasks before adopting; keep
  a fallback to Claude when the local model is unsure.
- [ ] Depends on: beaker GPU setup (driver + NVIDIA Container Toolkit) and
  ollama/openwebui running.

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

## Version History

- **v1.1.0** (2026-06-07): Cleanup pass — removed completed sections (git
  file-mode normalization, Dependabot alerts, stale-branch cleanup, the
  container-harness build, shell context detection, and assorted done
  sub-items), fixed stale/contradictory statuses, deduplicated entries
  (grok block, bash_prompt venv, parse_params), dropped stale items for
  archived libs, and refreshed Progress Tracking + Next Actions.
- **v1.0.0** (2026-01-18): Initial consolidated TODO based on modernization
  plan. Documented completed tasks, organized remaining work by phase and
  priority.

## References

- **[WORKFLOW.md](.claude/WORKFLOW.md)**: Development guidelines and conventions
- **[TESTS.md](.claude/TESTS.md)**: Testing framework and strategy
- **[CLAUDE.md](config/claude/CLAUDE.md)**: AI agent behavior specification
- **[config/claude/rules/pre-commit.md](config/claude/rules/pre-commit.md)**:
  Pre-commit agent policy
- **Modernization Plan**: Full plan available in conversation transcript
