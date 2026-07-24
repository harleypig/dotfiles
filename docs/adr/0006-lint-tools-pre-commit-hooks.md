# ADR-0006: Consolidate non-Python lint tooling onto lint-tools via a non-entrypoint runner

- **Status:** Accepted
- **Date:** 2026-07-24

## Context

[ADR-0005](0005-multi-linter-docker-image.md) built the combined `lint-tools`
image and its Phase 2 re-pointed `hadolint`, `prettier`, and `ruff`'s
`docker_wrapper` entries onto it. It **left `shellcheck` / `shfmt` /
`markdownlint` on their upstream `docker_image` pre-commit hooks**
(koalaman/shellcheck-precommit, scop/pre-commit-shfmt,
igorshubovych/markdownlint-cli) as a provisional call — converting them
*seemed* to cost:

1. rewriting the tag-based version-sync `bats` tests (which assert
   `image[shellcheck]="koalaman/shellcheck:v0.11.0"` == the hook `rev:` == the
   CI meta `SC_VER`);
2. losing free upstream hook updates (`pre-commit autoupdate` bumps a `rev:`);
3. slow per-file `docker run` if CI ever ran these from the image.

Investigating the conversion showed **none of those are real costs**, and the
mechanism is already proven in-repo — `perltidy` / `perlcritic` run as local
`docker_image` hooks against our own **entrypoint-less** ghcr images
(`entry: ghcr.io/harleypig/perlcritic:… perlcritic`). pre-commit mounts the
repo, sets the workdir, and appends the matched files, so a `lint-tools` hook
is just `entry: <lint-tools-image> <tool> <flags>`; only the image *source*
changes — tool, flags, file-selection (`types` / `files` / aliases), and
config auto-discovery are identical.

Re-examining the three "costs":

- **Version-sync is a *change*, not added complexity** — in fact simpler. The
  invariant becomes "every consumer references the same `lint-tools` image
  string," with the tool version living in **one** place: the Dockerfile
  `FROM` tags. One assertion, one source of truth, instead of reconciling a
  wrapper tag, a hook `rev:`, and a CI env var.
- **The version-bump process is the *uniform* one we already run** for
  `perltidy` / `perlcritic` / `ansible-lint`: edit the Dockerfile → republish
  → re-pin the digest. Converting these three does not add a process; it
  *removes* a second one (tracking upstream `rev:`s), giving one bump flow for
  every image-backed tool.
- **A non-entrypoint runner dissolves the CI per-file concern.** A plain
  on-`PATH` script in the image (e.g. `/usr/local/bin/run-tools`) that loops
  over tools/files internally lets CI do a batched pass in **one** container —
  while, because it is *not* an ENTRYPOINT, the tool-by-name path still works
  for the wrapper and pre-commit.

## Decision

Build our own hooks and consolidate all **non-Python** lint tooling onto the
one `lint-tools` image, keeping the image entrypoint-less so three consumers
coexist:

- **`docker_wrapper`** → `docker run lint-tools <tool> "$@"` (name the tool).
- **pre-commit (check *and* fix)** → local `docker_image` hooks,
  `entry: lint-tools <tool> <flags>`, replacing the upstream hooks for
  `shellcheck`, `shfmt`, `markdownlint` (preserving each hook's `args` /
  `types` / `files` / `*-sourced` aliases). pre-commit already batches all
  matched files into one run, so **no runner is needed here**.
- **CI** → `docker run lint-tools run-tools <…>` for a batched pass over all
  the tools.

Also re-point those three `docker_wrapper` `image[]` entries onto `lint-tools`
(as `hadolint` / `prettier` / `ruff` already are). The version source of truth
is the Dockerfile `FROM` tags; the rewritten version-sync test asserts the
consumers reference the same image.

**Keep it dotfiles-coupled for now.** The runner and hooks live in the repo
(`config/docker/lint-tools/`); if it proves out, it lifts cleanly into a
standalone hook repo later (a `.pre-commit-hooks.yaml` pointing at the image —
how upstream hook repos are already structured).

## Alternatives considered

- **Leave Group B on the upstream hooks** (the provisional ADR-0005 Phase-2
  stance). Rejected: the perceived costs dissolved on inspection, and
  consolidation yields one image + one bump process + a simpler version-sync
  invariant. Its one genuine merit — free upstream `rev:` bumps — is minor
  against the uniformity gained.
- **Bake the runner in as the image ENTRYPOINT.** Rejected: an entrypoint
  forces every invocation through the runner and breaks the tool-by-name path
  the wrapper and pre-commit depend on. A plain on-`PATH` script keeps both.
- **Fix only the Docker Hub flakiness via `docker/login-action` / caching.**
  This is **orthogonal and still worth doing** (it lifts the anonymous
  rate-limit for *all* Docker Hub hooks, `gitleaks` included), but it does not
  achieve consolidation — the two are complementary, not either/or.

## Consequences

- One image backs `docker_wrapper` + pre-commit (check *and* fix) + CI for
  **every** non-Python tool, with one uniform version-bump flow and a simpler
  version-sync test (same-image-string assertion, version in the Dockerfile).
- Upstream hook `rev:` auto-bumps are given up for these three — folded into
  the same Dockerfile-edit → republish → re-pin flow already used for the
  perl/ansible images. A known, accepted trade.
- First-pull size (`lint-tools` ~428 MB) is larger than the tiny per-tool
  images, but it is one cached image replacing several, and the private-ghcr
  `docker login` is **already** required (perltidy/perlcritic) — no new
  burden. Net registry pulls likely go *down*.
- **The CI-meta integration is the one deferred design call.** The runner
  *enables* a batched meta pass, but the current meta suite is per-file
  generated `bats` tests; choosing "keep meta on pinned binaries (already
  fast)" vs "restructure meta into a batched `run-tools`" is separate work and
  not required for the wrapper + pre-commit consolidation, which stands alone.
- Python-*runtime* tools (`yamllint`, `ansible-lint`) remain **out** of scope
  here — they stay separate and are handled in the python setup (ADR-0005
  update), so this is strictly the non-Python consolidation.
