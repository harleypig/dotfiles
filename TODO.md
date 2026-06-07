# TODO - Dotfiles Repository Modernization

**Last Updated:** 2026-04-18
**Plan Version:** Based on Dotfiles Repository Modernization Plan

This TODO file tracks the modernization effort for the dotfiles repository,
organized by work area with phase markers. See `WORKFLOW.md` for development
guidelines and `TESTS.md` for testing strategy.

## 📝 Documentation (HIGH PRIORITY)

### Immediate Tasks

- [x] Review and consolidate docs/ directory
  - [x] Evaluate docs/bash-completion.md - moved to config/completions/README.md
  - [x] docs/git_aliases.md - leave in docs/; user-facing reference, not config
  - [x] docs/bin.md and docs/windows-notes.md - both user-facing reference, stay in docs/

### Code Comment Cleanup

- [ ] Address XXX/TODO/FIXME comments (convert to documentation or fix)
  - See "Code Improvements (LOW PRIORITY)" section for detailed list

## ✅ Git File-Mode Normalization (DONE 2026-06-06)

The local `.git/config` had `core.filemode = false` (from a Windows-path
clone), which hid wrong modes in the index. Resolved on
`bugfix/git-filemode-normalization`:

- **Index modes corrected** (committed): commands made executable
  (`bin/motd`, `bin/perltidyrc-clean`, `config/claude/bin/statusline.sh`,
  `config/claude/hooks/rule-coverage.py`,
  `config/claude/skills/ship-pr/scripts/ship.sh`, `archive/bin/*`); sourced
  libs (`lib/is`, `lib/parse_params`, `lib/strings`) reset to 644 to match
  the other `lib/*`. (`bin/mymcp` was fixed earlier.)
- **`core.filemode` flipped to `true` locally** and all working-tree disk
  modes aligned to the index, so `git status` is clean and future mode
  drift is now tracked.

Caveats (per-clone, not committable):

- `core.filemode` lives in each clone's `.git/config`. A fresh clone on a
  filesystem where exec bits work picks up `true` automatically; one made
  on a Windows path may need `git config --local core.filemode true` again.
- There is no `.gitattributes` mechanism for exec bits; `.ps1` files are
  left as-is (the exec bit is moot for PowerShell).

## ✅ Dependabot Security Alerts (DONE 2026-06-07)

Pinned `dulwich >= 1.2.5` (PR #10); both high-severity advisories
(GHSA-9277-mp7x-85jf, GHSA-897w-fcg9-f6xj) auto-closed — 0 open alerts. Keep
the triage habit: `gh api repos/harleypig/dotfiles/dependabot/alerts -f
state=open` (see `gh.md` *Issues & triage*).

## 🛡️ Protect the master Branch (DONE 2026-06-07)

Enforced on GitHub via the `protect-master-solo.json` ruleset (id 17364459,
enforcement active): PR required, squash-only merge, stale-review dismissal,
required thread resolution, deletion + force-push blocked, `bats` required
green; `current_user_can_bypass: never`.

- [x] Applied `protect-master-solo.json` (solo: 0 reviews, squash-only,
  stale-review dismissal, thread resolution, deletion + force-push blocked).
  `protect-master-team.json` remains the variant if this becomes a team repo.
- [x] Fixed the required-check context to the repo's real check (`bats`);
  removed the `Build` / `Pre-commit checks` placeholders. Add the pre-commit
  CI check to the required set once it lands (see Pre-commit → CI).
- [x] Imported via the rulesets API with the OAuth token (the narrow PAT
  can't).
- [x] Verified: ruleset active on `master`; direct pushes are rejected and a
  PR needs `bats` green to merge.
- [x] Documented the enforced workflow in `WORKFLOW.md`.
- [ ] Confirm Dependabot / auto-merge interplay once a Dependabot PR appears
  (squash-only + required `bats` — ensure auto-merge still completes).

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

## ✅ Evaluate / Clean Up Stale Branches (DONE 2026-06-07)

The two `codex/*` branches (both already merged into master) were deleted on
2026-06-07; no stale branches remain. Going forward, review any non-merged
stray branch's diff before deleting it.

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

## 🔁 shell-startup: Double-load Guard + Interactive Guards (MEDIUM PRIORITY)

- [x] **Idempotency guard.** Added a non-exported `_DOTFILES_STARTUP_DONE`
  sentinel near the top of `shell-startup` that `return`s early on a second
  source in the same shell (child shells, not inheriting it, still run their
  own startup). Covered by `tests/shell/test_shell_startup_guard.bats`.
  (To force a reload: `unset _DOTFILES_STARTUP_DONE` then re-source.)
- [ ] **Interactive vs non-interactive guards.** Modules in
  `config/shell-startup/` define things that only make sense in an interactive
  shell (aliases, prompt, completions) — and aliases aren't even expanded in
  non-interactive shells. Guard interactive-only content so a non-interactive
  shell (scripts, scp, non-interactive ssh) skips it: e.g. `[[ $- == *i* ]]`
  per-module, or split interactive-only modules out. Decide the convention and
  apply it across the modules.

## 🧹 shell-startup Follow-ups (LOW PRIORITY)

Deferred from the shell-startup trim (PR #16):

- [ ] **Move the grok installer block out.** The `>>> grok installer >>>`
  block (PATH + completion) at the end of `shell-startup` runs after Cleanup
  and isn't a pre-load global — move it to a `config/shell-startup/grok`
  module (guarded like the others). First decide how to stop the grok
  installer re-appending it to `shell-startup` (retarget it, or accept
  periodic cleanup). *[needs thought]*
- [ ] **Rename the hook dirs — before the startup tests are finalized.**
  `{,.}shell_startup.d` hold *hooks* while `config/shell-startup` holds
  always-loaded files; rename the hook dirs to `{,.}shell_startup_hooks.d` to
  make that obvious. Do this before the containerized startup tests are done
  so they target the final names. Update `load_files`, the pre-setup hook
  path, `run_hook`'s default `$dfdir`, and the directories themselves.
- [x] **Test `run_hook`, then comment it out.** Added
  `tests/shell/test_run_hook.bats` (custom `$dfdir`, default
  `$DOTFILES/shell_startup.d` fallback, missing hook, failing hook) — verified
  passing with `run_hook` active, then commented `run_hook` out in
  `shell-startup` and set the tests to `skip` (preserved for future use;
  remove the skip + uncomment to reactivate).

## 🐚 Test dotfiles Startup in Containers (MEDIUM PRIORITY)

Goal: confirm the **dotfiles startup actually functions** in a fresh,
reproducible environment — deploy the dotfiles into a clean container and
verify a login shell comes up *working*, not merely that the scripts parse.
This catches missing-tool guards, host assumptions, bashisms, and broken
deploy/symlink (dotlinks) steps that never show on the dev machine.

- [x] bash: harness built (`tests/docker/`) — a slim Debian image; the repo
  is mounted read-only at `/dotfiles`; `~/.bash_profile`/`~/.bashrc` →
  `shell-startup`; a login shell is started through the real chain.
  `tests/shell/test_integration_startup.bats` asserts the env comes up
  (`DOTFILES`, `XDG_CONFIG_HOME`, bin on PATH), the double-source guard
  holds, and cleanpath dedups PATH. Harness skips when docker is absent.
- [x] Minimal image (most dev tools absent) — that's exactly what the slim
  harness exercises; startup still yields a working shell (only `command -v`
  guards / probes for absent tools, no fatal errors).
- [ ] **Extend the context matrix** — the harness covers interactive-login
  (`bash -lc`). Add the other contexts (interactive non-login, non-interactive
  login/non-login, incomplete terminal) once the per-module interactive
  guards land (see "shell-startup: Shell Context Detection").
- [x] PowerShell: deploy + load `ps-startup.ps1` (+ `powershell/startup/*`)
  in a PowerShell image (`mcr.microsoft.com/powershell`) and verify the
  profile comes up functioning, no errors —
  `tests/shell/test_integration_powershell.bats`. Surfaced + fixed two real
  parser bugs (`$env:$var` is invalid PowerShell) in `000-loadtokens.ps1` and
  `aider.ps1`, plus the `Test-Path … -and Test-Path …` paren bug.
- [x] Decide the runner — driven from bats (like the bash harness): runs the
  stock `mcr.microsoft.com/powershell` image directly (no custom Dockerfile),
  deploys `ps-startup.ps1` as the pwsh profile, runs `pwsh -File`. Sits in the
  gating suite and **skips** when docker is unavailable.

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
- [ ] Wire that check in as a meta-test (`tests/build-meta-tests` /
  `meta_*.bats`, per `TESTS.md`'s symlink validation) so CI flags a missing
  or stray symlink.
- [ ] Add a create/repair mode (a `--fix` flag or a small maintenance
  command) that creates any missing `bin/<tool>` symlinks and reports stale
  ones, so adding a tool or setting up a fresh clone is one command.
- [ ] Assert the link *target* (`docker_wrapper`), not file contents —
  symlink mode is 120000 and unaffected by `core.filemode=false` (see Git
  File-Mode Normalization above).

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

## 📧 Move gmailctl scripts to private_dotfiles (MEDIUM PRIORITY)

`bin/gmailfilter_toyaml` (and likely `bin/filter_gmail`) support **gmailctl**,
which holds/accesses sensitive Gmail filter config — that work only happens
out of `private_dotfiles`, so the scripts don't belong in the public dotfiles
repo. The scripts themselves aren't insecure; this is about keeping
gmail-related tooling alongside the private config it serves.

- [ ] Move `bin/gmailfilter_toyaml` to `private_dotfiles` (decide the layout —
  a `bin/` there, or alongside the gmailctl config). Evaluate moving
  `bin/filter_gmail` too.
- [ ] Update any references (PATH expectations, docs) after the move.
- [ ] This also retires the public meta-suite `perl -c` debt for
  `gmailfilter_toyaml` (it needs `XML::LibXML`) — it leaves the public repo.

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

## 🐛 bin/creds-helper PAT fallback bug (MEDIUM PRIORITY)

Found during the lint cleanup (not a lint error, so left unfixed there).
When the credential isn't found in `~/.netrc`, `bin/creds-helper` checks
`$PROJECTS_DIR/private_dotfiles/api-key/github` for existence but then reads
a **different** variable, `$PAT_FILE` (unset) — so it tries `< ""` and errors
(`No such file or directory`) instead of using the PAT.

- [ ] Reconcile the check and the read: either read the file it checked
  (`$PROJECTS_DIR/private_dotfiles/api-key/github`) or define/point `$PAT_FILE`
  at it, and guard against an empty/unset path.
- [ ] Add a bats test covering the .netrc-miss → PAT-fallback path.

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

## 🧹 Lint/format Debt in Legacy Scripts (MEDIUM PRIORITY)

The shellcheck/shfmt debt across `bin/` and `lib/` has been **cleared** — the
pre-commit check config now passes `--all-files`. What remains is a meta-suite
perl dependency (below).

Run `tests/scaffold/build-meta-tests && bats tests/shell/*.meta.bats` to see
meta-suite status. Once the perl dep is resolved the meta suite can be wired
into CI as a gate (today CI gates only the hand-written `tests/shell/test_*`).

- [x] **bin/** (shellcheck/shfmt): cleared — ansi, check-dotfiles,
  creds-helper, envsubstitute (real `=>`→`>=` bug fixed), git-all,
  tmux_edit_buffer, tmux_mode_indicator hand-fixed; the rest auto-fixed by
  `shfmt -w`.
- [x] **lib/** (shellcheck/shfmt): cleared — debug, parse_params.
      (`is`, `Arrays`, `strings` archived; `git-prompt` folded into git-status.)
- [ ] **bin/** (perl -c): gmailfilter_toyaml — needs `XML::LibXML`. Resolves
  itself once the script moves to private_dotfiles (see "Move gmailctl
  scripts to private_dotfiles" below); it leaves the public meta suite.
- [x] `bin/CleanPath.tmp`: archived to `archive/bin/` as part of the cleanpath
  fix (see "bin/cleanpath: Fix and Integrate").
- [ ] Once a script is clean, confirm its `<dir>-<name>.meta.bats` passes;
  when all pass, add the meta suite to CI and run it in pre-commit.

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

## 🐪 perl CI: make perltidyrc-clean tests version-robust (MEDIUM PRIORITY)

The `perl` CI job (`prove tests/perl/`) is **non-gating** for now
(`continue-on-error` in `.github/workflows/tests.yml`). Several
`perltidyrc-clean` tests assert *exact* Perl::Tidy error wording and break
across Perl::Tidy versions (pass on local 20250912, fail on the runner's
older package): `call_perltidy.t:129,207` and `get_perltidy_config.t:103`
(4/24 and 1/52 subtests).

- [ ] Make the assertions match *that an error was reported* (exit code /
  non-empty error), not the upstream phrasing — the fix may also reach into
  `bin/perltidyrc-clean`'s own error-wrapping path, so treat it as its own
  task (cf. parse_params).
- [ ] Once green across versions, drop `continue-on-error` and **promote
  perl to a required check**.

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
- [ ] Finish the **interactive-context guards**: reorder the heavily-mixed
  modules (`010-general`, `perl`) into env → `[[ $- == *i* ]] || return 0` →
  interactive. (`python`, `ssh-config-completion`, `terraform`, `tmux`,
  `bash_prompt`, `taskwarrior`, `git` are already guarded.)

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
- [ ] Ensure meta-tests are up to date (`./tests/build-meta-tests`)
- [ ] Create test fixtures in `tests/fixtures/`
- [ ] Create helper functions in `tests/helpers/common.bash`

### Phase 3: Core Test Coverage

- [ ] Add tests for shell-startup
  - [ ] Test DOTFILES detection
  - [ ] Test PATH building
  - [ ] Test module loading without errors
- [ ] Add tests for critical bin/ scripts
  - [x] cleanpath (unit tests) — `tests/shell/test_cleanpath.bats`
  - [x] yesno (unit tests) — `tests/shell/test_yesno.bats`
  - [x] git-status (integration tests) — `tests/shell/test_git_status.bats`
        (skips the prompt assertion if system `git-prompt.sh` is absent)
  - [x] check-dotfiles (integration tests) —
        `tests/shell/test_integration_check_dotfiles.bats`, run in the docker
        harness so its `ln -fs` into `$HOME` can't touch the host. Fixed the
        latent bug along the way (`check_dotfiles` linked
        `$DOTFILES/shell_startup` (underscore) instead of `shell-startup`, so
        the `.bash_profile`/`.bashrc`/`.profile` linking silently no-op'd).
- [ ] Add tests for lib/ libraries
  - [x] debug — `tests/shell/test_debug.bats` (refuses execution; debug()
        silent unless $DEBUG; prefixes + prints args and stdin to stderr).
  - [ ] parse_params — complex (657 L); its own task. Evaluate rewriting
        in perl (much simpler than the bash version); note it's currently a
        sourced lib that sets caller variables, so a perl version would need
        to emit eval-able shell (getopt-style) for the caller to `eval`.
        Write tests for whichever form it ends up as. **Also consider
        converting `bin/cleanpath` to perl** (same kind of text munging).
        Constraint: a perl rewrite of either must use **only core modules
        shipped with perl** — no CPAN dependencies (keeps them runnable
        anywhere perl is, and avoids the Perl::Tidy/XML::LibXML kind of
        install gap; see perl CI notes).
  - (`is`, `Arrays`, `strings` archived to `archive/lib/` — legacy/unused,
    not tested; `git-prompt` factored into `bin/git-status`)
- [ ] Add tests for config/shell-startup/ modules
  - [ ] Test conditional loading
  - [ ] Test error handling

### Phase 4: Extended Coverage

- [ ] Completion tests for config/completions/
- [ ] Integration tests for tool configurations
- [ ] Performance tests for PATH building

### Test Infrastructure

- [ ] tests/build-meta-tests:5,6,71 - Add tests for sh compilation, improve
  shebang check, handle symbolic links (XXX)

### Comprehensive BATS Test Coverage Audit (MEDIUM PRIORITY)

Phase 3 covers a handful of critical scripts. This task is a full pass to
ensure everything that should have tests does.

- [ ] Inventory all scripts in `bin/` and classify each:
  - Already tested (Phase 3 covers cleanpath, yesno, git-status, check-dotfiles)
  - Needs unit tests (pure logic, no external deps)
  - Needs integration tests (calls external tools, modifies state)
  - Wrapper/trivial — document why tests aren't needed
- [ ] Write `test_<script>.bats` for each untested bin/ script
- [ ] Evaluate what else needs BATS tests beyond bin/:
  - [ ] `lib/` libraries (surface area for reuse bugs)
  - [ ] `config/shell-startup/` modules (sourcing, conditional logic)
  - [ ] `bin/check-dotfiles` and dotlinks behavior
  - [ ] Any scripts in other locations (setup-work, etc.)
- [ ] Ensure `tests/build-meta-tests` generates tests for all new scripts
- [ ] Update Phase 3 checklist once items are covered here

## 🧠 Claude Rules Files (MEDIUM PRIORITY)

Rules files in `config/claude/rules/` (global, `~/.claude/rules/`) tell the
agent how to use each tool. Already have: bash.md, perl.md, powershell.md,
pre-commit.md, python.md.

- [x] Check `../dotvim` for existing tool parameters before writing rules
  (shellcheck and shfmt configs are known to be there via ALE)
- [ ] Audit all tools in use across the repo and create missing rules files:
  - [x] shellcheck — inline disable conventions; .shellcheckrc location is an
    open question (global vs repo-local vs both) documented in the rules file
  - [x] shfmt — flags `-i 2 -s -bn -ci -sr` from dotvim ALE config
  - [x] `.editorconfig` for shfmt: repo-root `.editorconfig` encodes
    `indent_size`, `binary_next_line`, `switch_case_indent`,
    `space_redirects`. Only `-s` remains CLI-only (no editorconfig
    equivalent). Rules doc covers both forms (with/without editorconfig).
  - [x] yamllint — config file location, common relaxations
  - [x] markdownlint — line length, allowed HTML, rules to disable
  - [x] yapf — already have config/yapf; document how agent should invoke it
  - [x] git — commit conventions, branch naming, worktree workflow reference
  - [x] bats — test structure expectations, helper usage
  - [x] docker — image pinning, layer hygiene, security, compose rules
  - [x] gh — PR/issue conventions; fork-mode PR target; worktree skill ref
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
- [x] Consider a template for new rules files so they stay consistent
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

## 🔒 Pre-commit Configuration (HIGH PRIORITY)

**Key Rule:** CI/CD Phase N requires Pre-commit Phase N completed first.
Pre-commit can progress independently. CI/CD cannot lead pre-commit.

### Phase 1: Core Hooks (DONE — except the rule Agent-Behavior pass below)

- [x] Create `.pre-commit-config.yaml` with core hooks (all remote, pinned):
  - [x] shellcheck (`--external-sources`)
  - [x] shfmt (`-d`, check-only; flags per shfmt.md/.editorconfig)
  - [x] yamllint (`-c config/yamllint/config`)
  - [x] markdownlint (`--config dot-general/.markdownlintrc`)
  - [x] check-yaml, check-json, check-merge-conflict, check-added-large-files
  - trailing-whitespace / end-of-file-fixer: **moved to the fix config** —
    those hooks can only modify, which violates the check config's
    non-modifying contract (`.claude/rules/pre-commit.md`).
- [x] Create `.pre-commit-config-fix.yaml` with auto-fix hooks:
  - [x] trailing-whitespace, end-of-file-fixer
  - [x] shfmt `-w` (write mode)
  - [x] prettier (excludes md/yaml — owned by markdownlint/yamllint)
- [x] Test pre-commit configuration with sample files (check + fix; clean
  files pass and are left unmodified; revs confirmed current via autoupdate)
- [x] Document pre-commit usage in README.md (+ full command reference —
  `install` variants, `autoupdate`, `validate-config`, `gc` — in
  `.claude/rules/pre-commit.md`)
- [ ] Update all `config/claude/rules/*.md` Agent Behavior sections to
  prioritize pre-commit over direct tool invocation:
  - Normal ops: `pre-commit run --files <file>` instead of `shfmt`/`shellcheck`/etc.
  - Fix ops: `pre-commit run --config .pre-commit-config-fix.yaml --files <file>`
  - Direct tool invocation becomes the fallback when pre-commit is not
    configured or the file is not covered by any hook
- [x] **Wire pre-commit into CI** — `tests.yml` has a `pre-commit` job running
  `pre-commit run --all-files` (the legacy debt is cleared, so it's clean).
  `no-commit-to-branch` is skipped in CI (`SKIP=...`) since it would fail on
  the master-push run.
- [x] Made the CI `pre-commit` check a **required status check** in the master
  ruleset (ruleset 17364459 now requires `bats` + `pre-commit`).

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

- [x] Add security checks to `.pre-commit-config.yaml`:
  - [x] gitleaks (secret detection — scans staged content at commit time)
  - [x] detect-private-key
- [x] Test security hooks on repository (both pass `--all-files`)
- Note: gitleaks here is a commit-time guard; full-repo/history secret
  scanning remains the **security-scan** skill's job (separate from this hook).

### Phase 3: Language-Specific Hooks

- [ ] Add Python hooks (commented/conditional):
  - [ ] black (formatting check)
  - [ ] isort (import sorting check)
  - [ ] flake8 (linting)
  - [ ] mypy (type checking)
- [ ] Add Perl hooks:
  - [ ] perlcritic (linting)
  - [ ] perltidy (formatting check)
- [ ] Add Rust hooks (if applicable):
  - [ ] cargo fmt (check mode)
  - [ ] clippy (linting)
- [ ] Update fix configuration with language-specific auto-fixes
- [ ] Test with actual project files
- [ ] Update documentation

### Phase 4: Documentation Linting

- [ ] Add documentation quality hooks:
  - [ ] proselint (prose linting)
  - [ ] Additional markdown checks
  - [ ] Link validation
- [ ] Test on repository documentation
- [ ] Update documentation

## 🚀 CI/CD Workflows (HIGH PRIORITY)

**Dependency:** Each CI/CD phase requires corresponding Pre-commit phase.

### Phase 1: Basic CI (requires Pre-commit Phase 1)

- [ ] Create `.github/workflows/ci.yml`:
  - [ ] Run on push to master
  - [ ] Run on pull requests
  - [ ] Execute BATS tests
  - [ ] Run shellcheck
  - [ ] Run yamllint
  - [ ] Run markdownlint
  - [ ] Report results as job status
- [ ] Test workflow with sample PR
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

### Shell-startup Issues

- [x] shell-startup:26 - Removed dead Windows MSYS block (see docs/windows-notes.md)
- [x] shell-startup:94 - Added --first/-f and --last/-l options to addpath
- [x] shell-startup:114 - Replaced XXX with description comment; run_hook is valid
- [x] shell-startup:180 - Removed dead placeholder export-script block
- [ ] Move the grok installer block out of the top-level `shell-startup`
  file into a dedicated `config/shell-startup/` module (e.g. `0NN-grok`).
  The grok installer appends directly to `shell-startup`, which is the
  wrong location and risks duplicate blocks on re-install; relocate it and
  guard against re-append.

### shell-startup: Shell Context Detection (HIGH PRIORITY)

`shell-startup` is symlinked from `.bashrc`, `.bash_profile`, and `.profile`,
but currently runs identically regardless of context. Shells have four main
contexts that need different behavior:

- **interactive login** — full environment, aliases, functions, prompts
- **interactive non-login** — already has login env; needs aliases, prompts
- **non-interactive login** — rare; env vars only, no aliases
- **non-interactive non-login** — scripts/subshells; env vars only, no
  aliases, no prompts (e.g., shell spawned from vim, cron, ssh command)

Problems to solve:

- [x] Guard against double-sourcing — done: non-exported
  `_DOTFILES_STARTUP_DONE` sentinel returns early on a second source in the
  same shell (`tests/shell/test_shell_startup_guard.bats`). The
  context-appropriate partial-run is the remaining context work below.
- [x] Detect shell context — modules use `[[ $- == *i* ]]` to gate
  interactive-only content (convention; see the guarded modules below).
- [x] Skip alias/function/prompt setup for non-interactive shells — all
  interactive-content modules now guarded with `[[ $- == *i* ]] || return 0`:
  `bash_prompt`, `taskwarrior`, `git` (pre-existing), `python`,
  `ssh-config-completion`, `terraform`, `tmux`, and the heavily-mixed
  `010-general` + `perl` reordered into env → guard → interactive. Verified
  in the harness (`test_integration_context.bats`).
- [x] Handle incomplete terminal environments gracefully (e.g., vim shell,
  docker exec, ssh command) — `bin/ansi` falls back to `TERM=dumb` when TERM
  is unset, so the prompt path (bash_prompt/git-status → ansi → tput) no
  longer errors with "No value for $TERM". Covered by the TERM-unset case in
  `test_integration_context.bats`.
- [x] Audit `config/shell-startup/` modules: tag/split by context — done as
  the guarding above (env-only content kept unguarded; interactive-only
  content moved below the guard). Broader improve/add/remove audit tracked in
  the config/shell-startup audit section above.
- [ ] Write integration tests using Docker to cover each context:
  - [x] Harness + interactive/non-interactive login covered
    (`tests/shell/test_integration_context.bats`: env in both, prompt +
    aliases interactive-only).
  - [x] Interactive non-login (`bash -ic`, reads .bashrc): env + prompt +
    aliases present.
  - [x] Non-interactive login (`bash -lc`): env vars set, aliases/prompt NOT
    defined (the "non-interactive login" case in the context test).
  - [x] Non-interactive non-login (`bash -c`): shell-startup does not run
    (DOTFILES empty) — scripts don't inherit the interactive setup.
  - [x] Incomplete terminal: TERM unset → comes up, no tput errors.
  - [x] Double-source guard: covered hermetically
    (`test_shell_startup_guard`) and in the harness
    (`test_integration_startup`) — second source leaves PATH unchanged.
  - [x] Research: can/should BATS drive Docker-based tests? Decided: **BATS on
    the host `docker run`s** the harness image and asserts on output/exit
    (the `dotfiles_harness_image`/`dotfiles_login` helpers), skipping when
    docker is absent. Documented in TESTS.md.
  - [x] Update TESTS.md to document Docker-based integration test approach.

### bin/cleanpath: Fix and Integrate (DONE 2026-06-07)

`bin/cleanpath` deduplicates PATH-style colon-separated variables; it was
broken (the `${ARR[$d]+isset} -ne 0` pattern treated scalar control vars as
arrays — `syntax error: operand expected` on every entry).

- [x] Audited `bin/cleanpath` (canonical) vs `bin/CleanPath.tmp` (stray WIP);
  archived the latter to `archive/bin/` and dropped it from the pre-commit
  exclude.
- [x] Fixed `bin/cleanpath`: `build_path` now parses the colon-separated
  control vars (`SHOULD_BE_FIRST/LAST/IGNORED/STRIPPED`) into real lookup
  sets and uses `[[ -v set[key] ]]`; de-dupes by resolved path. shellcheck +
  shfmt clean.
- [x] Added `tests/shell/test_cleanpath.bats` (7 tests: dedup, FIRST/LAST,
  STRIPPED, IGNORED-verbatim, blank/dot, error paths).
- [x] Integrated into `shell-startup` after `load_files` — guarded
  (`if _cleaned=$(cleanpath PATH) && [[ -n ... ]]`) so a failure can never
  blank PATH. Verified: collapses the duplicate `…/dotfiles/bin` entry.
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

### PowerShell: Linux Dev/Test Environment (RESEARCH FIRST)

Before doing PowerShell work, research whether Linux PowerShell Core (`pwsh`)
is a viable dev/test environment for scripts intended to run on Windows
PowerShell 5.1.

- [ ] Research compatibility between `pwsh` (Core) and Windows PowerShell 5.1:
  - Known gaps: COM objects, Windows-only modules (`ActiveDirectory`, etc.),
    `$PSVersionTable.PSEdition` differences, some .NET APIs
  - Determine if `ps-startup.ps1` and `config/powershell/` scripts use any
    Windows-only features that would break under `pwsh` on Linux
  - Check if Pester (PowerShell test framework) runs identically on both
- [x] Research using Docker for PowerShell testing — **viable and done**: the
  stock `mcr.microsoft.com/powershell` image (Linux `pwsh`) runs the profile
  cleanly. `tests/shell/test_integration_powershell.bats` drives it from bats
  (skip-if-no-docker), documented in TESTS.md.
  - [ ] (Still open) Whether a Windows container is needed to test true
    Windows PowerShell 5.1 behavior, and whether that's practical (requires a
    Windows host for Windows containers).
- [x] Test harness set up — the bats-driven container harness above. (Pester
  unit tests under `tests/powershell/` can layer on later for pure-logic
  functions; the integration smoke test exists now.)

### Bin Scripts

- [x] git-all:3 - Refactored: replaced missing utility functions inline, fixed
  shellcheck issues (SC2155, unquoted vars, array appends)
- [x] git-status:3 - Add STASH information (XXX)
- [x] yesno:33 - Add option to suppress warnings (XXX)

### Library Documentation and Testing

- [x] lib/debug:3,4 - Test (documented) — `tests/shell/test_debug.bats`
- [ ] lib/strings:7,8,9 - Document, test, enforce sourcing only (XXX)
- [ ] lib/Arrays:7,8,9,38 - Document, test, enforce sourcing, consider moving to
  tools/bin (XXX)
- [ ] lib/is:3,4,9 - Document, test, check for being sourced (XXX)
- [ ] lib/parse_params:3 - Test (XXX)

### Configuration File Issues

- [x] config/perl:12,54 - Existing checks are adequate; removed stale XXX
  markers and commented-out alternative
- [x] config/less:85,86 - lesspipe.sh handles syntax highlighting; removed XXX
- [x] config/tmux:37 - Detect multiple sessions (XXX)
- [x] config/terraform:9 - Comparison done; cleaned up XXX and dead code
- [x] config/taskwarrior:8,9,10 - Removed aspirational XXX markers (sourcing
  check unnecessary for shell-startup module; taskwarrior scripts item
  tracked below under Tool Configurations)
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

### Prompt Enhancements

- [ ] bash_prompt:131 - Fix poetry venv detection
- [ ] bash_prompt:137 - Fix manual venv color issue

### Shell Helpers

- [ ] Evaluate creating a reusable `select`/menu helper (sibling to
  `yesno`) for enumerated-option prompts
  - Survey existing callers in `bin/` and `config/shell-startup/` that
    roll their own selection logic or use bare `select`
  - Decide: dedicated `bin/` script (like `yesno`, `anykey`) vs. shell
    function in `config/shell-startup/`
  - Required behavior: numbered options, re-prompt on invalid input,
    optional default, quiet mode, return selected value on stdout
  - If justified, implement it first and have the `proj` task above
    use it

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

- [x] Decided location: Option B — `config/claude/bin/statusline.sh` (`~/.claude/bin/`)
  - `~/.claude/` IS `config/claude/` in this setup (no symlink needed)
  - Script is Claude-session-only → keep it claude-adjacent, not in general bin/
  - `statusLine.command` accepts any path; no requirement to be under `~/.claude/`
- [x] Created `config/claude/bin/statusline.sh`:
  - Shows: `model.display_name | ctx N% | $cost`
  - Context % colored cyan < 50%, yellow 50–74%, red ≥ 75%
  - All jq fields use `// fallback`; graceful exit if jq missing
- [x] Wired up in `config/claude/settings.json`:
  `"statusLine": { "type": "command", "command": "~/.claude/bin/statusline.sh", "refreshInterval": 5 }`
- [ ] Observe in a live session and tune (model name length, field order, colors)
- [x] Worktree marker: added to `bin/git-status` (shows `[wt:<main-repo>]`
  when in a linked worktree); surfaces automatically via the `git-status`
  segment in the Claude statusline
- [ ] Consider suppressing model name when $TMUX is set (if tmux bar shows it)

### Task 2: Unified Statusline Strategy (LOW PRIORITY — do after Task 1)

Once the Claude statusline exists, audit all four surfaces together:

- [ ] Inventory what each surface currently shows:
  - bash prompt (`config/bash_prompt`, `bin/git-status`)
  - tmux (`config/tmux/tmux.conf` status-left/right)
  - vim (vimrc / airline / lightline config in `../dotvim`)
  - claude (`config/claude/statusline.sh` — built in Task 1)
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

**Documentation:** ~80% complete (foundation laid, cleanup remaining)
**Testing:** ~20% complete (framework defined, implementation needed)
**Pre-commit:** ~0% complete (ready to start Phase 1)
**CI/CD:** ~10% complete (one workflow exists, needs expansion)
**Code Improvements:** ~0% complete (cataloged, not addressed)
**Config Enhancements:** ~0% complete (cataloged, not addressed)

## 🎯 Next Actions (Priority Order)

1. **Pre-commit Phase 1** - Create core pre-commit configuration
2. **CI/CD Phase 1** - Expand GitHub Actions with basic CI
3. **Testing Phase 2** - Review and enhance test infrastructure
4. **Testing Phase 3** - Add core test coverage for critical components
5. **Pre-commit Phase 2** - Add security hooks
6. **CI/CD Phase 2** - Add security checks to CI

## Notes

- **HIGH PRIORITY** items should be completed first
- **LOW PRIORITY** items can be deferred or completed incrementally
- Pre-commit phases can progress independently
- CI/CD phases MUST NOT lead pre-commit phases (dependencies enforced)
- Code improvements and config enhancements are cataloged but can be addressed
  opportunistically
- Template creation is extensive future work, deferred for now

## Version History

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
