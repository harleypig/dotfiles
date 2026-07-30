# Repository Workflow

**Version:** v1.10.0

## Purpose

This document defines repository-specific workflow rules, development
guidelines, and tool setup procedures. It provides concrete operational
guidance that extends and, where necessary, overrides `CLAUDE.md`.

For testing procedures and framework details, see `TESTS.md`.

**Precedence hierarchy:** `WORKFLOW.md` > `TESTS.md` > `CLAUDE.md`

Repository-specific rules in this document override general principles in
`CLAUDE.md`. Testing-specific rules in `TESTS.md` override both `WORKFLOW.md`
and `CLAUDE.md` for test-related operations.

## Repository Structure

### Core Directories

* **`bin/`** - Executable scripts and utilities
* **`lib/`** - Shared shell libraries (sourced, not executed)
* **`snippets/`** - Reusable code fragments for copy-paste reference (not
  loaded); organized by type (`bash/`, `pre-commit/`). See
  `snippets/README.md`
* **`config/`** - Configuration files organized by tool/application
* **`config/shell-startup/`** - Modular shell initialization files
* **`tests/`** - Test files using BATS framework
* **`docs/`** - Supplementary documentation (minimal, prefer inline)
* **`.github/`** - GitHub Actions workflows and templates

### Special Files

* **`shell-startup`** - Main shell initialization orchestrator
* **`shell-startup.md5`** - Blessed checksum of `shell-startup`, used by the
  `shell-startup-guard` skill to detect out-of-band changes (see
  *Shell-startup integrity guard*)
* **`ps-startup.ps1`** - PowerShell initialization for Windows
* **`CLAUDE.md`** - AI agent behavior specification
* **`WORKFLOW.md`** - This file
* **`TESTS.md`** - Testing framework and strategy
* **`TODO.md`** - Consolidated task tracking

## Development Workflow

### Documentation Philosophy

**Principle:** Documentation lives WITH code

1. **Individual files document themselves**
   * Scripts in `bin/`: Usage documentation in comments or `--help` output
   * Modular configs in `config/shell-startup/`: Inline comments
   * Configuration directories: `README.md` or inline documentation
   * Libraries in `lib/`: Docstrings and inline comments

2. **`README.md` (root): Minimal setup + navigation only**
   * How to set up new instance
   * Where to find specific documentation
   * High-level overview
   * Navigation pointers

3. **`docs/` directory: Minimize or eliminate**
   * Move documentation inline when possible
   * Keep only overviews or cross-cutting concerns
   * Avoid duplicating information available elsewhere

### XDG Base Directory Compliance

This repository follows XDG Base Directory specifications:

* **`$XDG_CONFIG_HOME`** (default: `~/.config`) - Configuration files
* **`$XDG_DATA_HOME`** (default: `~/.local/share`) - Data files
* **`$XDG_CACHE_HOME`** (default: `~/.cache`) - Cache files
* **`$XDG_STATE_HOME`** (default: `~/.local/state`) - State files

When creating new configurations or modifying existing ones, agents MUST:

* Use XDG variables when supported by the tool
* Document XDG paths in tool-specific READMEs
* Provide fallbacks for tools that don't support XDG

### Pre-commit Workflow

**Policy:** See `.claude/rules/pre-commit.md` for complete rules.

**Quick reference:**

* **Default mode: Check-only** (`.pre-commit-config.yaml`)
  * Runs on git commit
  * Blocks commit on failures
  * Read-only checks, no modifications

* **Fix mode: Auto-fix** (`.pre-commit-config-fix.yaml`)
  * Run manually: `pre-commit run --config .pre-commit-config-fix.yaml --all-files`
  * Modifies files to fix issues
  * Use before committing or to clean up repository

**Phased implementation:**

1. **Phase 1 (Core):** shellcheck, yamllint, markdownlint, trailing-whitespace
2. **Phase 2 (Security):** gitleaks, detect-private-key
3. **Phase 3 (Language):** Python, Perl, Rust hooks
4. **Phase 4 (Docs):** Vale (prose; chosen over proselint — see `TODO.md`),
   additional documentation linting

Agents MUST complete each phase before implementing the next. GitHub Actions
CI workflows MUST NOT include hooks from a phase until that phase is complete
in the pre-commit configuration.

### Testing Workflow

**Framework:** BATS (Bash Automated Testing System)

**See `TESTS.md` for this repo's testing strategy, and the global
the dotagents repo's `rules/bats.md` for bats conventions.**

**Quick reference:**

* Run the gating suite: `bats tests/shell/test_*.bats`
* Run everything present: `bats tests/shell/`
* Run a specific file: `bats tests/shell/test_<name>.bats`
* Regenerate meta tests: `tests/scaffold/build-meta-tests`
* Tests MUST pass before merging to master
* New functionality MUST include tests

### Shell-startup integrity guard

`shell-startup` is what `~/.bash_profile` and `~/.bashrc` symlink to, so any
tool installer that "adds itself to your shell profile" writes **into
`shell-startup`** without going through git or the agent. The grok (xAI) CLI
installer is the known case — its target file is hardcoded to `~/.bashrc` (no
override), so it re-adds its `>>> grok installer >>>` block whenever the
marker is absent. Its PATH + completion lines now live in
`config/shell-startup/grok` instead, but the installer will still
re-pollute `shell-startup` on reinstall.

A committed **`shell-startup.md5`** at the repo root records the blessed
checksum, and the **`shell-startup-guard`** skill
(`.claude/skills/shell-startup-guard/`) detects drift against it. Wiring:

* **Run the guard during push-pr's first half** (Step 1, before commit) and
  again at **merge-finalization** (Step 4.5) — invoke the
  `shell-startup-guard` skill, which on drift shows the diff since the last
  blessed state and offers approve / restore / relocate / defer.
* **The agent's own edits stay blessed automatically.** The global
  `md5-guard.py` `PostToolUse` hook regenerates `shell-startup.md5`
  whenever the agent edits `shell-startup` through Edit/Write — so only
  *un-managed* changes leave the checksum stale. **Always stage
  `shell-startup` and `shell-startup.md5` together** in the same commit;
  if you ever edit `shell-startup` outside the tools, run the skill's
  `bless` step.

### Git Workflow

**Branch strategy:**

* **`master`** - Main branch, stable code
* Feature branches: `feature/<name>`
* Bugfix branches: `bugfix/<name>`
* Documentation: `docs/<name>`

**Pull requests:**

* Must pass all CI checks
* Pre-commit hooks must pass
* Tests must pass
* At least one review for significant changes

**Enforced branch protection (`master`):**

`master` is protected by a GitHub ruleset (`protect-master-solo.json` in
`../private_dotfiles/github-rulesets/`, enforcement active). It is **not**
advisory — the remote enforces it:

* **Direct pushes to `master` are rejected** — all changes land via PR.
* **Squash is the only allowed merge method.**
* **`bats`, `meta`, `perl`, `perl-compile`, and `pre-commit` must be green**
  to merge (required status checks). `perl-compile` builds a real pinned Perl
  in CI, but only when a PR touches the perl toolchain — it exits early-green
  otherwise (see `.github/workflows/tests.yml`).
* Deletion and force-push of `master` are blocked; unresolved review threads
  block merge; stale reviews are dismissed on push.
* No bypass actors — even the owner goes through a PR.
* A local `no-commit-to-branch` pre-commit hook also blocks a direct commit
  to `master` at commit time (early guard; the server ruleset is what
  actually enforces it). See the dotagents repo's `rules/git.md`.
* The global `branch-protection.py` `PreToolUse` hook blocks an agent
  `Edit`/`Write`/`MultiEdit` while `master` is checked out — the earliest
  guard, at edit time (it allows plan files and gitignored, untracked files —
  local-only state that can't be committed). It derives the protected branch
  from the `no-commit-to-branch` args above, so this repo activates it
  automatically. See the dotagents repo's `rules/git.md` *Protecting the Default
  Branch*.

To change the ruleset, edit the JSON and re-apply. A plain `gh` uses the
stored OAuth credential, which has the admin rights this needs — the old
`GH_TOKEN= GITHUB_TOKEN=` prefix is gone because nothing exports those any
more (see *GitHub credentials* below):

```bash
gh api repos/harleypig/dotfiles/rulesets/17364459 \
  --method PUT --input ../private_dotfiles/github-rulesets/protect-master-solo.json
```

**GitHub credentials:**

A single ambient PAT could not reach an org that owns its own resources, so
`GH_TOKEN` is no longer exported. Instead:

* **`gh …`** uses gh's own stored OAuth credential
  (`config/gh/hosts.yml`) — the broadest reach on the personal account.
* **`ghx <scope> …`** (`bin/ghx`) runs the same command under that scope's
  token from `../private_dotfiles/github/tokens/<scope>`. The token directory
  *is* the registry: a scope exists when its file does, a symlink is a short
  alias, and an empty file declares a scope that defers to the stored
  credential. `ghx --list` shows what is configured.
* The first non-dash argument decides: a gh command (or none) passes
  straight through untouched; anything else is the scope.

See `../private_dotfiles/github/README.md` for minting each token — in
particular that an org scope needs a **fine-grained PAT with the org as
resource owner**, which may require org-owner approval.

**Linode credentials:**

`bin/linx` is the same wrapper for `linode-cli`, reading
`../private_dotfiles/linode/tokens/<scope>` and running the command with that
token in `LINODE_CLI_TOKEN`. Same registry-is-the-directory rule, same
dispatch (a linode-cli command passes through; anything else is the scope),
same `--list` / `--expiry` / `--rotate` / `--refresh`.

Three differences follow from what the Linode side offers, all handled inside
`linx` — see its header comment:

* linode-cli names its commands only via `linode-cli commands`, not on an
  unknown command, so the keyword probe reads that table.
* linode-cli **does** have global options that take a value (`--format`,
  `--as-user`, …), which `gh` does not, so `linx` learns them from
  linode-cli's own usage line and skips their values when looking for the
  scope.
* The Linode API cannot say which token authenticated a request, so
  `--expiry` matches the stored token against the leading characters
  `/profile/tokens` returns for each. That needs `profile:read_only` on the
  token; one without it is reported as unreadable, not as an error.

An empty scope file means "use whatever user `linode-cli` itself is
configured with" — and clears any ambient `LINODE_CLI_TOKEN`, which would
otherwise override that config.

**`LINODE_TOKEN` is a separate thing** and is still exported ambiently by
`config/shell-startup/000-loadtokens`: it is what the **Terraform** Linode
provider reads (via `bin/docker_wrapper`), not linode-cli. Retiring that
ambient export the way `GH_TOKEN` was retired is tracked in `TODO.md`.

**Auto-merge (`auto-merge: enabled`):**

Because the guardrails above are strong — the server-side ruleset requires a
PR with `bats` / `meta` / `perl` / `pre-commit` green, blocks direct pushes
and force-push, and admits no bypass actors — a manual "ask before merge" gate
adds no safety here. This repo therefore opts in: the `auto-merge: enabled`
sentinel in the heading above tells the **push-pr** skill (Step 5) that
invoking it is consent through the **whole** flow. Once CI is green and the
merge-time finalization below (Step 4.5) is done, push-pr merges on its own —
no separate "merge it" needed. push-pr reads this sentinel **from `master`**
(the policy already in effect), not the working tree, so the PR that
*introduces* the sentinel still merges manually — auto-merge applies from the
**next** PR. The merge still goes through `push.sh merge`, which the ruleset
gates (squash-only, required checks); the opt-in skips the prompt, **never**
the checks. To revert to a manual merge gate, delete this sentinel. See
the dotagents repo's `skills/push-pr/SKILL.md` Step 5 and
`rules/gh.md`.

**Merge-time finalization (`merge-finalization: enforce`):**

This repo opts in to the merge-time documentation finalization (push-pr
Step 4.5). Completed items are **pruned outright** from `TODO.md` (and
`ROADMAP.md` if one exists) once the PR that finishes them goes green —
finalized work is migrated to [`CHANGELOG.md`](../CHANGELOG.md), not left as
`[x]` markers. The `merge-finalization: enforce` sentinel in the heading above
activates the `PreToolUse` hook (`~/.claude/hooks/merge-finalization.py`),
which **blocks** a `gh pr merge` / `push.sh merge` while any completed `- [x]`
items still remain in the planning docs. See the dotagents repo's
`skills/push-pr/SKILL.md` and `rules/git.md`.

The agent-config planning backlog now lives in the **dotagents** repo (it was
extracted there with `config/claude`), so this repo's merge-finalization only
enforces its own `TODO.md` (and `ROADMAP.md` if one exists) — no extra
`merge-finalization-docs` are declared.

### TODO Routing

This repo tracks all its work in one list, root [`TODO.md`](../TODO.md):
`bin/`, `lib/`, `config/`, shell-startup, tests, CI, packaging, the OS/$HOME
setup. Its former second list — the Claude-agent-config backlog — moved out
with `config/claude` when that was extracted into the **dotagents** repo.

When capturing a follow-up, decide where it belongs before writing it:

* **Dotfiles work** → root [`TODO.md`](../TODO.md).
* **Claude-agent-config work** (rules, skills, hooks, the agent-config docs,
  plugin/MCP setup) → the **dotagents** repo, which now owns that config and
  its own `audit/BACKLOG.md`. Capture it there directly when working in
  dotagents; when it surfaces while you're here in dotfiles, treat it as a
  **cross-repo** item (below).
* **Cross-repo** → a follow-up that belongs to a **different repo than the one
  you're in** (an agent-config item surfaced here and bound for dotagents; or
  a global-config change spawning a per-repo evaluation for pigify /
  scripturestudy-app). You usually can't write it into the target repo's
  planning doc from here, so don't lose it: **capture it in the current repo's
  `TODO.md`**, tagged with the **target repo** and a **migrate-on-next-visit
  trigger** — e.g. "→ dotagents: migrate to its `BACKLOG.md` when next working
  it". The reciprocal: when you **start work in a repo**, scan the other
  repos' parking spots for items tagged to it and migrate them in. The
  **github-tasks** sweep is the natural place to run that inbound check.

`TODO.md` carries no routing preamble — only open tasks — per the global
`rules/todo.md`.

## Tool Setup Procedures

### Prerequisites

Required tools for development:

* `bash` (4.0+)
* `git` (2.0+)
* `bats-core` (for testing)
* `pre-commit` (for pre-commit hooks)

Optional but recommended:

* `shellcheck` (shell script linting)
* `shfmt` (shell script formatting)
* `yamllint` (YAML linting)
* `markdownlint-cli` (Markdown linting)

### Initial Setup

1. Clone repository:

   ```bash
   git clone <repo-url> ~/dotfiles
   ```

2. Install pre-commit:

   ```bash
   pip install pre-commit
   # or
   brew install pre-commit
   ```

3. Install pre-commit hooks:

   ```bash
   cd ~/dotfiles
   pre-commit install
   ```

4. Run tests to verify:

   ```bash
   bats tests/shell/
   ```

5. Follow setup instructions in root `README.md`

### Perl QA toolchain (perlbrew via vmgr)

The Perl QA tools that run **locally** — `perltidy` (Perl::Tidy), `perlcritic`
(Perl::Critic), and the coverage/POD test modules — are installed into a
pinned, perlbrew-managed Perl by `bin/vmgr`, so every machine has the same
Perl and module versions. (The commit/CI **gate** does not depend on this — it
runs `perltidy`/`perlcritic` from pinned docker images — so this toolchain is
for local development and running `tests/perl/` under a controlled Perl.)

```bash
vmgr install perl     # install pinned perlbrew, build the pinned Perl, and
                      # cpanm the QA module set into it (compiles Perl from
                      # source — minutes)
vmgr report perl      # show expected (pins) vs. current install + drift
vmgr update perl      # reconcile an existing install after bumping a pin
```

The pins live in [`config/vmgr/perl`](../config/vmgr/perl) (perlbrew release,
Perl version, and the cpanm module list); bump them there. `vmgr install perl`
does **not** touch a pre-existing system-perl + local::lib setup until it
completes — `config/shell-startup/perl` prefers the vmgr-managed perlbrew only
once it is present, and otherwise leaves the existing Perl environment alone.

**The perl gates need a ghcr login.** The pre-commit `perltidy` and
`perlcritic` hooks (and the `bin/perltidy` / `bin/perlcritic` docker wrappers)
pull the pinned, **private** `ghcr.io/harleypig/perltidy` and
`ghcr.io/harleypig/perlcritic` images built by
[`publish-tool-images.yml`](../.github/workflows/publish-tool-images.yml). So a
one-time `docker login ghcr.io -u <you>` with a `read:packages` token is
required for those hooks to run locally; CI logs in with the workflow token.
Both images are the one parameterized `config/docker/perl-tools/Dockerfile`
(they differ only by the `MODULES` build-arg). Bumping a pinned module version
is a SYNC — the publish-workflow matrix, `bin/docker_wrapper` `image[<tool>]`,
and the tag+digest in the pre-commit config(s) — re-pin the digest after it
publishes (perlcritic has a check hook only; perltidy has both check and fix).

## Agent-Specific Overrides

### Pre-commit

* MUST follow phased implementation strategy.
* MUST ensure CI workflows match pre-commit configuration.
* MUST NOT advance to next phase until current phase is complete.
* MUST document any new hooks in `.claude/rules/pre-commit.md`.

## Integration Points

### External Services

Currently integrated:

* **GitHub Actions:** CI/CD workflows in `.github/workflows/`
* **OpenCode:** Issue management via `.github/workflows/opencode.yml`

### Environment Variables

Key environment variables used:

* `$DOTFILES` - Path to this repository
* `$XDG_CONFIG_HOME` - XDG config directory
* `$XDG_DATA_HOME` - XDG data directory
* `$XDG_CACHE_HOME` - XDG cache directory
* `$XDG_STATE_HOME` - XDG state directory

See individual tool configurations for additional variables.

## Maintenance

### Regular Tasks

* Review and update `TODO.md` as tasks are completed
* Update documentation when code changes
* Run `pre-commit run --all-files` periodically
* Review and address TODO/FIXME/XXX comments in code
* Keep git completion files updated (check upstream)

### Versioning

* `CLAUDE.md` - Versioned (see that file)
* `WORKFLOW.md` - Versioned (this file, v1.6.0)
* `TESTS.md` - Versioned (see that file)
* `.claude/rules/*.md` - Individual versions

Update version numbers when making significant changes to these files.

## Questions and Issues

* For general usage questions, see root `README.md`
* For agent behavior questions, see `CLAUDE.md`
* For testing questions, see `TESTS.md`
* For bug reports or feature requests, open a GitHub issue
