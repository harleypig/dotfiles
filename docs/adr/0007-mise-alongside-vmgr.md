# ADR-0007: Support mise alongside vmgr, with vmgr preferred per language

- **Status:** Accepted
- **Date:** 2026-10-01
- **Revises:** [ADR-0001](0001-custom-polyglot-version-manager.md)

## Context

[ADR-0001](0001-custom-polyglot-version-manager.md) chose to build `vmgr`, a
small orchestrator over each language's native manager, and rejected mise as
the way to manage toolchains. Since then `config/shell-startup/mise`
activates mise on any machine that has it (#411), so both can be installed
at once and nothing said which one wins.

The trigger was operational: vmgr had a problem on another server, and mise
was what worked there. The operator's direction (#363, 2026-09-29): *"We
should support either. Go with whatever is installed. If both are installed,
we should go with vmgr first."*

Two facts shape how that can be done at login:

- `config/shell-startup/` is sourced in glob order, so `mise` runs before
  `node`, `perl` and `python`.
- mise's default activation lets PATH changes made after it take precedence.
  Only the `activate_aggressive` setting (`MISE_ACTIVATE_AGGRESSIVE`, default
  off) pushes mise's paths back to the front on each prompt
  ([mise settings][mise-settings], fetched 2026-10-01). Checked against mise
  2026.9.10 on this machine: a directory prepended after `mise activate`
  stayed in front through later `hook-env` runs, and moved behind mise's once
  `MISE_ACTIVATE_AGGRESSIVE=1` was set.

## Decision

We will **support vmgr and mise side by side**, and decide precedence **per
language**: where vmgr manages a language and its toolchain is installed,
vmgr's toolchain is ahead of mise's on PATH. mise supplies everything else.

The mechanism is load order, not a switch. mise stays first; each vmgr-side
module prepends its toolchain after it:

- **node** prepends nvm's default Node at login when the default alias names
  an installed version, which is what `vmgr install node` sets. Any other
  alias (`lts/*`, `node`) is left to the existing lazy loader.
- **perl** sources the vmgr-managed perlbrew's `etc/bashrc`, which already
  prepends the default Perl.
- **python** prepends nothing. vmgr's python manager installs uv and pipx,
  not an interpreter, so with mise installed mise supplies `python` itself.

`activate_aggressive` must stay off; a test fails if anything tracked in
`config/` or `shell-startup` turns it on.

ADR-0001's decision stands: vmgr is still the lifecycle tool this repo
builds and prefers. What changes is that mise is now a supported fallback
rather than a rejected alternative.

## Alternatives considered

### Run mise last, after the per-language modules — rejected

Renaming the module to sort after `python` would make mise's activation the
last PATH change, putting mise **ahead** of vmgr: the opposite of the
direction given. It would then need its own logic to step back behind vmgr,
language by language.

### Stop mise managing a language vmgr has (`MISE_DISABLE_TOOLS`) — rejected

`disable_tools` lists tools mise should ignore. With a tool disabled, its
mise shim stops working rather than falling through to the next one on PATH
(*"node is not a valid shim"*, measured 2026-10-01), so a stray shim can
break the tool outright. It also needs the mise module to know which
languages vmgr manages, which load order gives for free.

### One global switch (vmgr or mise for everything) — rejected

vmgr manages three languages and mise may manage more. A global switch
would either hide mise's other tools whenever vmgr is installed, or let mise
shadow vmgr's toolchains, and neither is what was asked.

## Consequences

**Easier:**

- A machine where vmgr fails can fall back to mise without any change to the
  dotfiles, and a machine with both gets vmgr's toolchains.
- With nvm installed, vmgr's Node is on PATH at login, so `#!/usr/bin/env
  node` scripts and other non-interactive callers get it without first
  loading nvm.

**Harder / accepted costs:**

- Precedence depends on two facts outside the modules: their glob order, and
  mise's default activation behaviour. Renaming a module, or a mise release
  that changes the default, breaks it. The tests in
  `tests/shell/test_shell_startup_vmgr_mise_precedence.bats` cover both
  installed, only one, and neither, and fail if `activate_aggressive` is
  turned on in tracked config. A user-level mise config is outside the repo,
  and the tests cannot see it.
- vmgr's uv and pipx land in `~/.local/bin`. If mise also manages uv or
  pipx, mise's copies win there, because prepending `~/.local/bin` ahead of
  mise would shadow mise for every tool in that directory.
- Ruby and Rust (#363) follow the same pattern: their module prepends after
  mise.

[mise-settings]: https://mise.jdx.dev/configuration/settings.html
