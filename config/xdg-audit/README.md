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
  it from the default report (a considered "leave it in place"). Each item is
  either a bare path string, or an object `{ "path": ..., "reason": ... }`
  where `reason` is a short why-it-is-ignored note shown next to the path in
  the `-a/--all` output.
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

## Current vs. recommended mechanism

The `mechanism` above is the **recommended** handling — what *should* redirect
a path. Independently, `xdg-audit` detects the **current** mechanism from
`$HOME` state and reports where the two diverge, so you can see not just "what
should handle this" but "what does":

- **symlink** — the `$HOME` path is a symlink. It is **complete** when its
  link-name is registered in the dotlinks file `check-dotfiles` reads
  (`$HOME/.dotlinks`, else `$DOTFILES/dotlinks-default`), else **partial** (a
  loose link `check-dotfiles` won't maintain).
- **env** — a declared `env` redirect is active (the variable is set, or the
  `rewrite` target exists). It is **clean** with no `$HOME` leftover, else
  **leftover**. A `symlink`-recommended path whose declared `env` var is
  **exported and active** also reports current `env` (a divergence — an
  `env → symlink` conversion candidate).
- **hardcoded** — a present, real, un-redirected file that is not a symlink:
  the unmanaged state to migrate away from.
- **unknown** — present but handled by a mechanism that can't be verified from
  a child process (an `alias`/`wrap`, detected in a later phase), or otherwise
  inconclusive.

A lookup's detail line appends `(recommended: <mechanism>)` when the current
mechanism diverges from the declared one, and `--json` carries
`current_mechanism`, `recommended_mechanism`, `current_completeness`, a
`divergence` verdict, and a `suggested_steps` array per record. `suggested_steps`
holds the "instruct the rest" steps an agent can apply — an `export VAR=<target>`
(`action: export`) a hardcoded/symlink-current env-recommended path needs, or an
`unset VAR` (`action: remove-export`) a symlink-recommended path currently
redirected by env must drop when it converts (empty when no step applies). This is the reporting half of the
mechanism state-machine ([ADR-0004](../../docs/adr/0004-xdg-audit-mechanism-state-machine.md));
the migration transitions between mechanisms build on it in later phases.

## Owner (externally-managed paths)

A path an external tool manages carries an `owner` — a generic overlay
annotation naming that manager, e.g. `"owner": "check-dotfiles"`. A declared
`mechanism: symlink` **implies** `owner: check-dotfiles` (which owns the
`.dotlinks` + `ln -fs` flow) without needing the field. `xdg-audit` reports
such a path as externally managed (`[owner: <who>]` in a detail line, `owner`
in `--json`) and, in later phases, coordinates its transitions with that owner
rather than acting blindly. `--submit` strips the field, as with the other
local-only annotations.

## Symlinked dotfiles

A dotfile that is itself a **symlink** (a deliberate managed link, e.g. into
another repo like `.vim` -> the dotvim repo, or `.claude` -> dotagents) is
reported in the `linked` group as `.x -> <target> (external)` rather than
flagged as a stray. Like the other non-actionable groups (`handled`,
`ignored`, `unknown`), it is shown only with `-a/--all`; it is informational —
the audit shows where it points so you can confirm the link, not migrate it.

## Unknown dotfiles

`-a/--all` also lists an **`unknown`** group: top-level `$HOME` dotfiles that
**no** db entry — upstream `programs/` or local `programs-local/` — covers.
These are candidates for a new overlay entry (a redirect, an `ignore`, or an
`addition`) once you decide how to handle them; the XDG base dirs
(`.config` / `.cache` / `.local`) are skipped as infrastructure.

## config vs. state routing

Only genuine **config** belongs under `config/` (tracked). Runtime
**state / cache / data** must target `$XDG_STATE_HOME` / `$XDG_CACHE_HOME` /
`$XDG_DATA_HOME` (which point into `$HOME`, untracked) — never the repo.

## Removing a leftover

The scan and lookups are read-only. The mutating modes — `--remove`,
`--migrate`, and `--fix` — each act on a named app or `$HOME` path, show
status, and ask before each change (default No).

`--remove` deletes a **confirmed leftover**:

```bash
xdg-audit --remove docker      # shows status, asks before each deletion
```

Only an eligible path is deletable: a **stray** (present, its redirect already
active — a duplicate) or a **remove**-marked (unused app) file. An
**un-redirected** (`unhandled`) file is refused — migrate it, don't delete it.
Every deletion is confined to `$HOME` and confirmed interactively (default No);
`--remove` never sweeps the whole scan, so a target must be named.

**Stray-target safety:** a `stray` is only deletable when its redirect
**target actually exists**. An env entry whose variable is set but whose
redirected copy was *never created* would otherwise read as a stray — deleting
its `$HOME` copy (the only copy) is data loss, so `--remove` refuses it and
points you at `--migrate env` (move the file to the target instead).

**Symlink teardown:** a **check-dotfiles-managed** symlink (one whose link-name
is *registered* in the dotlinks file) is **torn down** — the `~/.x` link is
removed and its `.dotlinks` entry dropped, so `check-dotfiles` won't recreate
it; the **canonical repo file is left intact** (never touched). A **loose**
(unregistered) or **external** symlink (e.g. `~/.vim` → the dotvim repo) is
refused — `--remove` only tears down a link it demonstrably manages. When the
active dotlinks file is the tracked `dotlinks-default`, the teardown edits a
tracked file (as `--migrate symlink` does); the git commit stays yours.

## Migrating a leftover

`--migrate <mechanism> <app|path>` transitions a target to `<mechanism>`. The
mechanism is a **required positional** (no silent default); `env`, `symlink`,
and `recommended` are implemented — the rest arrive in later phases (see
[ADR-0004](../../docs/adr/0004-xdg-audit-mechanism-state-machine.md)). So the
old bare `xdg-audit --migrate bash` is now `xdg-audit --migrate env bash`;
a bare `--migrate`, an unknown/unimplemented mechanism, or the old bare-app
form is a usage error that names the new signature.

`--migrate recommended <app|path>` resolves the target's **declared** mechanism
(the overlay `mechanism`) and dispatches to it (`env`/`symlink`). It refuses
when an app owns paths with *different* recommended mechanisms (run
`--migrate <mechanism>` per mechanism, or name a single `$HOME` path), when the
recommendation is one `--migrate` cannot yet perform (`alias`/`wrap`/`remove`),
or when no mechanism is declared.

`--migrate env` *moves* a present dotfile to its declared XDG target (the
overlay's `rewrite`), so an already-active redirect finds it there:

```bash
xdg-audit --migrate env bash   # move ~/.<file> to its rewrite target, asks
```

When the redirect is **active** it must point at the declared target (else it
refuses — reconcile first). When the redirect is **not active** it still moves
the file and **prints the exact `export VAR=<target>` line** to add to your
shell config *before running the app again* — automate the move, instruct the
export (ADR-0004's "automate the automatable, instruct the rest"; the same step
also rides in `--json`'s `suggested_steps` for an agent to apply). It refuses
when the **target already exists** (a redundant leftover — use `--remove`), when
either path escapes `$HOME`, or when an env-recommended entry declares **no
variable** to export. A cross-filesystem *directory* move is refused (move it by
hand).

**`symlink → env` conversion:** when the `$HOME` path is currently a **managed
symlink** and the entry recommends `env`, `--migrate env` converts it — it drops
the `~/.x` symlink and its `.dotlinks` entry, moves the dereferenced canonical
file to the XDG `rewrite`, and instructs the export (rolling back the move + the
dropped link/line on any partial failure). A broken symlink, or a `mechanism`
other than `env`, is refused.

Note: a `rewrite` under `$XDG_CONFIG_HOME` lands in the **tracked repo** (this
setup's `$XDG_CONFIG_HOME` is `$DOTFILES/config`) — the confirmation shows the
destination so you see where it goes; keep runtime **state/cache** out of the
repo (see *config vs. state routing* above).

`--migrate symlink` puts a **hardcoded** dotfile (a present real file with no
redirect — the unmanaged state) under `check-dotfiles` management:

```bash
xdg-audit --migrate symlink grok   # move ~/.grok into the repo + symlink, asks
```

It moves the file into the repo at its declared `rewrite` (which **must live
under `$DOTFILES`** — a symlink source has to be repo-resident), registers it in
a dotlinks file, then runs [`check-dotfiles`](../../bin/check-dotfiles) to
create the `$HOME` symlink back to the repo copy. xdg-audit never runs `ln`
itself — `check-dotfiles` (via `.dotlinks`) owns the linking. When `~/.dotlinks`
(the active dotlinks file) is absent it offers to **bootstrap** it — seeded from
`$DOTFILES/dotlinks-default` or empty — or to append to the shared, tracked
`dotlinks-default`. It writes into the **tracked repo** but never commits (the
git commit stays yours), and a partial failure **rolls back** (the file is moved
back and the dotlinks line stripped). It refuses when no repo `rewrite` is
declared, the target is outside `$DOTFILES` or already exists, or the source
escapes `$HOME`.

**`env → symlink` conversion:** when the path is currently redirected by an
**env** variable and the entry recommends `symlink` (declaring both a
`$DOTFILES` `rewrite` and the `env` var naming the live redirect), `--migrate
symlink` converts it — it moves the file at `$ENV{<env>}` into the repo,
registers it in `.dotlinks`, links it via `check-dotfiles`, and instructs
**removing** the export (`unset VAR` + deleting the shell-config line; the same
step rides in `--json` as a `remove-export` action). It refuses when a `$HOME`
leftover blocks the link (`--remove` it first) or the redirect's target no
longer exists. Because the redirect must be **visible** to xdg-audit, a
non-exported variable can't be detected — such a path reads as `hardcoded` and
the conversion is not offered.

## Fixing a partial setup

`--fix <app|path>` completes or repairs the **current** setup without changing
mechanism — sugar for `--migrate <current-mechanism>`:

```bash
xdg-audit --fix grok           # register a loose symlink so it is maintained
```

The implemented case is a **loose symlink** — a real symlink not registered in
the dotlinks file, reported as `partial`. `--fix` registers it (source = the
link's current target) and runs `check-dotfiles`, so the link is maintained from
then on. It refuses a `hardcoded`/`absent`/`unknown` path (nothing to fix — use
`--migrate` to choose a mechanism) and an `env` leftover (use `--remove`).

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
