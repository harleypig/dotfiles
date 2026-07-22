# ADR-0004: xdg-audit as a dotfile "mechanism" state-machine

- **Status:** Accepted (direction; built in phases)
- **Date:** 2026-07-22

## Context

`bin/xdg-audit` today **reports** on `$HOME` dotfiles (present/absent, redirect
active, symlinked) and performs two point mutations: `--remove` (delete a
leftover) and `--migrate` (move a present file to its XDG `rewrite` target —
**env-mechanism only**, shipped in PR #280). The overlay/db already declares a
*recommended* mechanism per path (`env` / `alias` / `symlink` / `wrap` /
`remove`).

Two gaps prompted this decision:

1. The db says how a dotfile *should* be handled, but xdg-audit never reports
   how it is *actually* handled right now — nor flags a divergence.
2. `--migrate` only knows one target (the env redirect). There is no way to
   *fix* a partial setup, or to move a dotfile to a *different* mechanism
   (e.g. `symlink`), and the biggest prize — moving a **hardcoded** dotfile
   (an app that pins its path with no redirect) onto a proper mechanism — is
   unreachable.

We want to minimise `hardcoded` dotfiles and automate the setup/fixing as much
as possible, for both a human and an AI agent driving the tool.

## Decision

Reframe xdg-audit around a **state-machine over dotfile mechanisms**.

- **Two mechanism axes per path:** the **recommended** mechanism (declared, in
  the overlay/help) and the **current** mechanism (**detected** from `$HOME`
  state), with an **`unknown`** fallback and a `hardcoded` state (present, no
  redirect, not a symlink — the thing we migrate *away* from). The scan/detail
  report both and flag divergence (`using recommended` / `using X, recommended
  Y` / `unknown`); `--json` carries `current_mechanism` + `recommended_
  mechanism`.

- **CLI as transitions:**
  - `xdg-audit --migrate <mechanism> <app|path>` — transition current →
    target; `<mechanism>` ∈ `recommended | env | symlink | alias | wrap |
    remove` (`recommended` resolves then dispatches). The mechanism is
    **required** — no silent default (explicitness for a mutation). This is a
    **breaking change** to the shipped env-only `--migrate <app>`, reframed as
    `--migrate env` (ours + brand-new, so acceptable; announced in its own
    commit + changelog).
  - `xdg-audit --fix <app|path>` — sugar for `--migrate <current-mechanism>`:
    complete/repair the current setup without changing mechanism (e.g. a
    symlink not in a dotlinks file → add the entry).
  - `xdg-audit --remove <app|path>` — the `remove` teardown transition.

- **Automate the automatable, instruct the rest — as a dual-audience
  suggestion.** Each transition does the file/dotlinks/deletion steps it *can*
  automate (confirmation-gated, with cleanup/error-out), and emits the
  remaining step(s) — a shell-config `export`, an alias line, "create the
  `bin/<app>` wrapper" — worded so **both a human and an AI agent** can act:
  implement it, or capture it as a TODO. `wrap` as a target *suggests* creating
  the wrapper rather than refusing.

- **Delegate, don't reimplement.** `symlink` transitions coordinate with
  `check-dotfiles` / `.dotlinks` (which own `ln -fs`); xdg-audit never
  recreates the linking. Current-mechanism detection of command-associated
  handling (is the command an `alias`/function/file?) **delegates to
  `bin/where`** (which wraps `type -t`), not a reimplemented `type`/grep.

- **`owner` field.** A generic overlay annotation naming the external manager
  of a path (`"owner": "check-dotfiles"`); `mechanism: symlink` implies it.
  xdg-audit reports the dotfile as externally managed and coordinates its
  transitions with that owner.

- **Phased build** (each its own PR): **Phase 1** — `owner` + reporting,
  symlink/env detection + divergence display, `--migrate symlink` + `--fix`,
  and the `--migrate env` reframe. **Phase 2** — `--migrate recommended`, the
  automatable matrix cells, `env`↔`symlink`, `--remove` teardown. **Phase 3**
  (candidate ICEBOX) — general installation-method detection, `alias`/`wrap`
  transitions, the full matrix.

## Alternatives considered

- **Build `--migrate symlink` as a one-off** (the original follow-up). Rejected:
  it is really one cell of a general mechanism-transition model; designing the
  model first keeps the CLI from boxing us in (e.g. `--migrate` needing a
  target mechanism).
- **WONTFIX symlink-migrate — "check-dotfiles owns it."** Rejected: automating
  the move-into-repo + `.dotlinks` edit is genuinely useful; xdg-audit
  *orchestrates* check-dotfiles rather than duplicating it.
- **Keep the env-only `--migrate <app>` signature.** Rejected: it does not
  generalise to other target mechanisms; the state-machine needs a target.
- **Reimplement the `type`/where classification inside xdg-audit.** Rejected:
  Rule of Three — `bin/where` already owns it; delegate.

## Consequences

- **Breaking change** to the shipped `--migrate` (env-only → required
  mechanism). Acceptable (ours + new), but it gets an explicit commit +
  changelog note and the reframe to `--migrate env`.
- xdg-audit gains a **tracked-repo-write surface**: `--migrate symlink` moves a
  file *into* the repo and appends to a tracked `dotlinks-*` file. It never
  auto-commits (the git commit stays the user's) and surfaces the destination
  in the confirmation preview.
- **New dependencies:** detection of `alias` handling depends on `bin/where`
  (which must first be fixed — its search locations miss this setup's config
  dirs) and on running in a shell context that has the user's aliases loaded
  (aliases are not exported to a child process).
- The build is **phased and demand-pulled**: the full N×N transition matrix and
  general installation-method detection are deferred (Phase 3 / ICEBOX
  candidate) rather than built speculatively.
- The concrete per-phase build detail lives in `TODO.md` (`### xdg-audit
  follow-ups`); this ADR records the *direction* and the load-bearing choices.
