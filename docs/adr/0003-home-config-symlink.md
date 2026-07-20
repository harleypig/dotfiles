# ADR-0003: Whether to symlink `~/.config` to `$DOTFILES/config`

- **Status:** Accepted
- **Date:** 2026-07-19

## Context

`XDG_CONFIG_HOME` is set to `$DOTFILES/config` (see `shell-startup`), so any
app that honours the variable already writes into the repo's `config/`. Apps
that **hardcode** `~/.config` and ignore `XDG_CONFIG_HOME`, however, write to
the real `~/.config` instead — a split store. The `$HOME` dotfile audit
(`TODO.md`) raised whether to **symlink `~/.config -> $DOTFILES/config`** so
both paths resolve to the same place.

The concern on record was that the repo working tree would then become the
live write-target for anything dropping files in `~/.config`, risking stray
files getting committed.

That concern is **neutralised** by `config/.gitignore`: it is a deny-all
allowlist (`/*`, then `!/<tracked>`), and every allowed subdirectory repeats
the pattern. Anything an app newly writes under `~/.config` (= the repo's
`config/`) is therefore **git-ignored by default** — it cannot be accidentally
committed. The only residual is on-disk (ignored) clutter in the working tree.

## Decision

**Adopt the symlink in principle — it is safe — but do not auto-wire it, and
route state/cache away from it.**

- The wholesale `~/.config -> $DOTFILES/config` symlink is an **acceptable,
  reversible** choice: the allowlist `.gitignore` removes the accidental-commit
  risk, and it unifies the split store for hardcoded-path apps.
- It is **not** added to `dotlinks-default`. On essentially every machine
  `~/.config` **already exists** as a real directory (apps write there), so
  `bin/check-dotfiles` would only *warn* ("not linked to …"), never create the
  link — auto-wiring would produce recurring login-time noise, not a
  migration. Establishing the symlink is a deliberate **per-machine
  migration** (move the existing `~/.config` contents into `config/`, then
  replace `~/.config` with the symlink), tracked in `TODO.md`.
- **Prefer per-app env vars over relying on the symlink** for anything that is
  *state/cache/data* rather than config: those belong in `$XDG_STATE_HOME` /
  `$XDG_CACHE_HOME` / `$XDG_DATA_HOME` (which point into `$HOME`, untracked),
  never in the tracked working tree. The symlink is a fallback for
  genuinely-config, hardcoded-path apps — not a blanket substitute for the
  mechanism hierarchy (`config/xdg-audit/README.md`).

## Consequences

- No behavioural change ships in this decision: the split store persists until
  a machine performs the migration on purpose.
- If adopted on a machine, hardcoded-`~/.config` apps and XDG-respecting apps
  converge on `config/`, and the allowlist keeps their stray writes untracked.
- Reversible: delete the symlink and restore a real `~/.config` to back out.
- Revisit if a future tool cannot tolerate its config directory being a
  symlink, or if the on-disk clutter becomes material.
