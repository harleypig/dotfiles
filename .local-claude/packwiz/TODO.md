# packwiz fork TODO

Fork-specific work. Not upstream-shared. See `.claude/WORKFLOW.md` for
the broader workflow.

## Watched PRs

When the user asks to "check watched PRs" (or similar), walk this
list and report each PR's `state`, `mergeable`, `reviewDecision`, and
most recent `updatedAt` via `gh pr view <N> --repo packwiz/packwiz`.

### Our own upstream PRs

Watch for: review activity, merge events, mergeability changing to
`CONFLICTING` after a `main` sync.

- [ ] **PR #306** — `add-metadata` — CurseForge metadata with
      links/categories. Branch: `add-metadata`.
- [ ] **PR #359** — `list-pinned` — pinned/unpinned mod filtering for
      `packwiz list`. Branch: `list-pinned`. Addresses upstream issue
      #317 (`[feature] Add a way to list pinned mods` by
      @hatkidchan, 2024-08).

### Unsubmitted upstream candidates

`pr/<name>` branches that have been merged into `mine` but have
not yet been opened as upstream PRs. Periodically review and
decide whether each is ready to propose. See WORKFLOW.md
"Tracking unsubmitted upstream candidates" for the convention.

*Currently empty.* Both existing topic branches (`add-metadata`,
`list-pinned`) are already open upstream as PRs #306 and #359, so
they live in "Our own upstream PRs" above.

### Upstream PRs we're tracking but don't own

Watch for: author response, new commits, readiness to merge into
`mine`.

- [ ] **PR #281** — *add slug and provider options for list* by
      @Omay238. Posted review comment 2026-05-13 flagging
      `-g -v` swallow and slug-extraction panic risk. Author has
      previously acknowledged the PR is incomplete (`todo: url` in
      body). When/if author addresses concerns or pushes new commits,
      re-evaluate whether to merge into `mine`.

## Routine maintenance reminders

- After `main` advances from `upstream/main`: rebase each open PR
  branch onto fresh `upstream/main` and force-push (see
  `WORKFLOW.md` "Routine maintenance"). The skill's Operation 2
  handles individual branches.
- After a watched-PR merge upstream: corresponding local branch and
  worktree can be cleaned up (skill Operation 5). The merge gets
  absorbed into `mine` on the next `main` sync.

## Pending decisions

(none open)

## Planned work

Concrete work intended for `mine` (or to propose upstream), roughly
sequenced. Order matters where one item is a prerequisite for the
next.

- [ ] **Add/enhance tests.** The repo currently has exactly one test
      file (`core/versionutil_test.go`). Coverage is effectively nil
      across `cmd/`, the curseforge and modrinth backends, and the
      rest of `core/`. Start with unit tests for higher-traffic
      packages (manifest read/write, version comparison already
      partially covered, download URL handling) and the recently-
      added code paths from our open PRs. This is a prerequisite for
      the Go bump below — without a test suite, a version bump is
      unverifiable beyond "it still compiles."

      In progress on `pr/testing` (started 2026-05-13). First
      test: `core/urlutil_test.go` for `ReencodeURL`.

      **CI runs zero tests today.** `.github/workflows/go.yml`
      only builds via goreleaser. Plan: don't touch the upstream
      CI workflow until we have meaningful coverage. As a
      precursor, set up our own GitHub Actions workflow on
      `harleypig/packwiz` that runs `go test ./...` on push — this
      gives us a forcing function locally without proposing a
      noisy upstream change while the suite is small. When
      coverage is meaningful enough to be worth gating upstream
      reviewers on, port the workflow into a PR against
      `packwiz/packwiz`.
- [ ] **Audit and improve error handling.** Depends on the test
      work above. PR #384 (*Exit on download failure during modrinth
      pack export* by @jackwilsdon, 2026-01-04) is a concrete
      example: a one-line fix making `modrinth export` fail when a
      mod download fails instead of silently producing an
      incomplete `.mrpack`. The author's own framing — *"it's not
      clear if this is the intended behaviour"* — is the real
      symptom: the codebase has no documented error posture, so
      every failure path is an ad-hoc decision. Goal of this item:
      establish which paths should fail fast, which should surface
      to the user with context, and which can legitimately
      skip-and-warn. Expect this to be **iterative** with the test
      work — each silent-failure path uncovered while writing a
      test becomes an error-handling decision. Use PR #384 as a
      starting reference for the export path specifically; merge
      it (or its equivalent) as part of this work.
- [ ] **Bump Go version to latest.** `go.mod` currently pins
      `go 1.23.0`. Defer until the test work above is in place so
      regressions are catchable. When ready, also update:
      - `.github/workflows/` for any hardcoded Go versions.
      - `flake.nix` for any pinned `go_X_Y` package.
      - `default.nix` / `shell.nix` if present.
      - Any Dockerfile base image.

      **Note on PR #381** — *Add rate limiting to modrinth updates
      and bump Go version to 1.24* by @Dalethium (opened 2025-11-25,
      fixes upstream issue #376). Bumps Go 1.23.0 → 1.24.0 but
      bundles an unrelated Modrinth rate-limiter
      (`golang.org/x/time/rate`, 1 req per 150ms, burst 5) that
      required the bump to pull in `golang.org/x/time`. Don't merge
      #381 as-is for the version bump alone — wait until our tests
      are in place so the rate-limiter behavior can be verified
      independently. Either then merge #381 wholesale, or split: do
      our own bump first and treat the rate-limiter as a separate
      decision (the rate-limit constants are picked without any
      stated source).
- [ ] **Evaluate and adopt export-output-directory handling.** Two
      upstream PRs address the same UX gap — control over where
      `mrpack` / `zip` export artifacts get written — with different
      designs:

      - **PR #394** — *Support directories as values for the
        `--output` option during export* by @Kira-NT (2026-04-18,
        +16/-15, 3 files). One flag (`--output`) with smart
        behavior: creates the destination directory if missing, and
        treats any path without an extension as a directory
        (appending the default artifact name). Also fixes a real
        bug — currently `--output build/pack.mrpack` fails if
        `build/` doesn't exist.
      - **PR #401** — *feat(mr/export): add outdir as an option to
        choose directory* by @begbaj (2026-05-13, +10/-3, 1 file).
        Adds a separate `-d / --outdir` flag and renames the
        existing `-o` to `-f`. Author acknowledges the rename is
        breaking and offered to make it non-breaking.

      Action: evaluate both, then either merge one into `mine`,
      write our own combining the best of each, or mix. Lean #394
      — it's the more thoughtful design (one flag, smart
      heuristic, non-breaking, includes the
      directory-doesn't-exist fix). Best done after the test work
      so a regression test covers `-o filename.mrpack`, `-o build/`,
      and `-o build/custom.mrpack`.

      **Related: PR #395** — *Prevent invalid export filenames by
      using slugs instead of display names* by @Kira-NT (2026-04-18,
      +26/-5, same author and same day as #394). Currently packwiz
      uses the pack's `name` field directly as the default export
      filename, which can contain characters that are illegal on
      some filesystems (e.g., `:` is fine on Linux but forbidden
      on Windows) or just produce awkward filenames with spaces
      and punctuation. PR slugifies the name (lowercase,
      whitespace → `-`, keep digits, drop the rest) for the
      default. Independent fix worth considering alongside #394
      since both touch export filename/path handling — could
      bundle into one change on `mine` or land separately.
- [ ] **Audit CurseForge for the loader-comparison flaw fixed by
      PR #391.** PR #391 (*Filter out irrelevant loaders to improve
      version comparison accuracy* by @OrzMiku, 2026-03-10) fixes a
      bug in the Modrinth path: `compareLoaderLists` (defined in
      `modrinth/modrinth.go:236`) considered every loader in a
      version's loader list, including loaders the user's pack
      doesn't use. So an older multi-loader version could
      incorrectly beat a newer single-loader version. Author's
      example: IMBlock v5.0.2 `[fabric, forge, neoforge]` winning
      over v5.4.6.1 `[neoforge]` in a neoforge-only pack because
      fabric ranks ahead of neoforge in the preference list. The
      fix filters each version's loader list to only loaders
      relevant to the pack before the preference comparison.

      The fix is Modrinth-specific. CurseForge uses a different
      model — each CurseForge file has a single `modLoaderType`
      (see `filterLoaderTypeIndex` in `curseforge/curseforge.go:288`
      and the surrounding update path), not a list — so the exact
      bug pattern doesn't transfer directly. The investigation
      questions are: (1) does the CurseForge update path have an
      analogous failure mode when a pack supports multiple loaders
      and a mod has files across more than one? (2) is there
      another comparison step where irrelevant-loader files could
      win over relevant-loader files of a newer version?

      Best done after the test work so a regression test can lock
      in the correct behavior for both sides. Use #391 for context
      / framing; the implementation will likely look quite
      different on the CurseForge side.

- [ ] **Documentation: developer-facing.** The repo has only a
      `README.md` — no `CONTRIBUTING.md`, no architecture overview,
      no `docs/` directory, and sparse godoc on exported
      types/functions. Targets:
      - `CONTRIBUTING.md` covering local build, the test layout
        (once tests exist; see "Add/enhance tests" above), and the
        upstream contribution flow.
      - Godoc on exported types and functions in `core/`, `cmd/`,
        `curseforge/`, `modrinth/`. Prioritize extension points
        used by multiple call sites (`IndexPathHolder`,
        `Updater`/`UpdateCheck`, `Mod` / `Pack`).
      - A short architecture overview
        (`docs/architecture.md` or similar) covering the
        pack/index/manifest/file model, where the backends plug
        in, and the update/export pipelines.

      Decide per-target whether to land it on `mine` only or
      propose upstream (most of this should be upstream-suitable).
- [ ] **Documentation: user-facing (website).** Lives at
      `packwiz/packwiz-website` (separate repo, deployed at
      packwiz.infra.link). Anything we add or change in `mine`'s
      CLI behavior — or upstream contributions we land — needs
      corresponding docs there:
      - File a PR or issue against `packwiz-website` for each
        new flag/behavior shipped.
      - Track website-doc gaps for *our* features here so they
        don't get lost between repos.

      Onboarding step before contributing: fork `packwiz-website`
      under harleypig and set up the same `.claude/`-symlink /
      `.git/info/exclude` pattern we did for this repo. Until
      then, this item is a placeholder reminder.
- [ ] **Add a Dockerfile.** Provide a containerized runtime for
      packwiz so it can run in CI and automated workflows without
      a local Go toolchain. Shape:
      - Multi-stage build: builder with Go toolchain, runtime
        minimal (distroless or alpine).
      - Pinned Go version, kept in sync with the version-bump
        TODO above.
      - Sensible workdir (`/pack`) and non-root user.
      - `.dockerignore` to keep the image lean (vendor/ in or
        out depending on build strategy).
      - GitHub Container Registry publish target if going
        upstream — `ghcr.io/packwiz/packwiz:<version>` /
        `:latest`.

      Upstream-suitable contribution. Decide at implementation
      time whether to land it on `mine` first and propose
      upstream, or open the upstream PR directly.

## Future considerations

Notes parked under the topic that should re-surface them. When starting
work in one of these areas, re-read the relevant subsection before
designing the change.

### When test code accumulates repetitive stdlib assertions

We bootstrapped the test suite with stdlib `testing` only
(2026-05-13, `pr/testing` branch), matching the existing
`core/versionutil_test.go`'s style and upstream's dependency
choices.

If/when test code grows to the point that:

- Stdlib's `if got != want { t.Errorf(...) }` chains are
  cluttering tests and obscuring intent.
- Deep struct/slice equality with `reflect.DeepEqual` becomes
  verbose or hard to read.
- Multiple tests would benefit from fail-fast helpers
  (`require.NoError`, `require.Equal`).

… revisit adopting **testify** (`require` / `assert`). Decision
to factor in: upstream hasn't chosen testify either, so adoption
would either stay `mine`-only or pair with a deliberate upstream
proposal.

Trigger when reading a test file (yours or being added): does
"would testify make this clearer?" have an obvious yes answer?
If so, surface as a suggestion — don't make the switch
unilaterally.

### When implementing markdown output from `packwiz list`

- **PR #286** — *Add `-f` flag to `packwiz list`* by @laforcem. Adds
  `packwiz list -f <file>` that writes a column-aligned Markdown
  table; composes with `-v`, `-s`, and other existing flags. Open
  since 2024-02 with little activity. If/when we want markdown
  output from `mine`, evaluate merging this — either as-is or as a
  starting point. The column-alignment logic (no unevenness across
  rows) is a feature worth preserving in any alternative
  implementation.

### When evaluating Alias-field handling in pack exports

- **PR #396** — *Support aliased files in pack exports* by @cswimr
  (2026-04-21, +17/-1, 2 files). Fixes a real bug: the `Alias`
  field on index entries is silently ignored during
  `packwiz modrinth export` and `packwiz curseforge export`. Per
  packwiz's index-toml reference, `Alias` lets a file appear in
  the exported pack under a different name/path than it has
  locally (incompatible with `Metafile`). Fix adds
  `AliasPath()` to the `IndexPathHolder` interface, used in
  `downloadutil.AddNonMetafileOverrides`.

  **Open question for us:** it's unclear how `Alias` is useful in
  our packwiz usage — we may never set it. If we don't, this fix
  is a no-op for us and merging it is harmless but pointless. If
  we (or packs we plan to consume) ever do use `Alias`, the bug
  matters. Action when this surfaces: grep any packs we maintain
  for `alias = ` in `index.toml`; if absent and no plan to use it,
  leave parked. Otherwise evaluate for merge into `mine`.

### When adding CurseForge release-type support

We want `--releaseType` (release / beta / alpha pinning) to work for
CurseForge mods, not just Modrinth.

- **PR #316** — *Add `--releaseType` flag to `update`* by
  @LifeIsAParadox. Implements the flag for Modrinth only. Open since
  2024-08, last touched 2024-10. Two viable directions:
  1. Wait for #316 to merge upstream, then extend it with CurseForge
     support in a follow-up PR.
  2. Use #316 as a structural reference and implement combined
     Modrinth + CurseForge support in a single new PR.
  Either way, the flag surface and value naming should match #316 so
  a future merge or coexistence doesn't cause UX divergence. Check
  CurseForge's API for the equivalent of Modrinth's `version_type`
  field before designing.

## Notes

- This list is fork-local. It's never tracked in git and never sent
  upstream — `.claude/` is excluded via `.git/info/exclude`.
