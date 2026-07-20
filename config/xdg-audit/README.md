# xdg-audit database

Data for [`bin/xdg-audit`](../../bin/xdg-audit) — the tool that audits `$HOME`
for dotfiles a program supports relocating to an [XDG base directory][xdg], and
tracks which of them this repo already redirects.

In this setup `XDG_CONFIG_HOME` is `$DOTFILES/config`, so this directory *is*
the live XDG config home for the tool.

## Layout

```text
config/xdg-audit/
  json-schema/program.json     # PRISTINE vendored schema (xdg-ninja)
  programs/*.json              # PRISTINE vendored program definitions
  programs-local/*.json        # OUR overlay: overrides, additions, ignores
  programs-local/.schema.json   # superset schema for the overlay
  upstream.json                # pinned upstream repo + ref (for --update-db)
  LICENSE.xdg-ninja            # upstream MIT license (attribution)
  .index.json                  # generated cache (gitignored)
```

`json-schema/` and `programs/` are a **pristine mirror** of
[xdg-ninja][xdgninja] (MIT). Never hand-edit them — `xdg-audit --update-db`
refreshes them wholesale from the pinned ref. All local divergence lives in
`programs-local/`.

## Overlay roles

An overlay file (`programs-local/<app>.json`) plays one of these roles, and is
validated against `programs-local/.schema.json`:

- **override** — same `name` as an upstream program; corrects or annotates it.
  Carries `override-of` and `upstream-digest` (the sha256 of the upstream file
  it was written against) so `--update-db` can flag it *possibly obsolete* once
  upstream changes.
- **addition** — a `name` upstream does not cover (e.g. an internal tool).
- **ignore** — list the `$HOME` path in the top-level `ignore` array to suppress
  it from the report (a considered "leave it in place").
- **wrap annotation** — a file entry with `mechanism: wrap` + a `rewrite`
  target, handled by a `bin/<app>` namespace bind-mount wrapper (planned).

An entry has `files` (paths that need handling or carry help), `ignore` (paths
left in place), or both. An overlay entry **replaces** the upstream entry of
the same name, so list every path you still want reported — but a `files` entry
that omits `help`/`movable` backfills them from the matching upstream path.

## Mechanism hierarchy

For each stray path, prefer the first mechanism that fits — the same ladder the
repo's prior migrations follow:

1. **env** — the program honours an environment variable
   (`DOCKER_CONFIG`, `LESSHISTFILE`, `PERL_CPANM_HOME`, …). Annotate the entry
   with `mechanism: env` and `env: <VARNAME>`; `xdg-audit` then reports the
   path as handled when that variable is set.
2. **alias** — no env var, but a command flag works (e.g. `wget --hsts-file=`).
3. **symlink** — the file must physically live at a `$HOME` dotpath; link it
   from the repo via `bin/check-dotfiles`.
4. **wrap** — the app hardcodes its path and offers no knob; run it inside a
   namespace bind-mount that redirects the path (planned; see `TODO.md`).
5. **remove** — the app is unused; delete the stray.

## Symlinked dotfiles

A dotfile that is itself a **symlink** (a deliberate managed link, e.g. into
another repo like `.vim` -> the dotvim repo, or `.claude` -> dotagents) is
reported as `linked -> <target>` rather than flagged as a stray. It is
informational and non-actionable — the audit shows where it points so you can
confirm the link, not migrate it.

## config vs. state routing

Only genuine **config** belongs under `config/` (tracked). Runtime
**state / cache / data** must target `$XDG_STATE_HOME` / `$XDG_CACHE_HOME` /
`$XDG_DATA_HOME` (which point into `$HOME`, untracked) — never the repo.

## Keeping the mirror current

```bash
xdg-audit --update-db          # refresh programs/ + json-schema/ from upstream
```

This clones the pinned upstream, overwrites the pristine files, records the new
ref in `upstream.json`, rebuilds the index, and reports any overlay override
whose `upstream-digest` no longer matches — a signal that upstream may have
caught up and the override can be retired.

To contribute a local addition or fix back upstream:

```bash
xdg-audit --submit <app>       # planned: opens an upstream PR (local fields stripped)
```

[xdg]: https://specifications.freedesktop.org/basedir-spec/latest/
[xdgninja]: https://github.com/b3nj5m1n/xdg-ninja
