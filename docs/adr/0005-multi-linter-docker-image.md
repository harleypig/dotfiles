# ADR-0005: A self-owned multi-linter Docker image (toolbox, not orchestrator)

- **Status:** Accepted
- **Date:** 2026-07-24

## Context

`TODO.md` (*Docker tooling Setup* → "Research: run more linters/formatters via
Docker") asks whether to deliver our linters/formatters through a single
maintained image rather than the current spread of per-tool images — several
of them pulled from Docker Hub, which is also the subject of a separate
"harden the pre-commit job against Docker Hub pull flakiness" item.

Today each tool has its own pinned image, wired three ways that must stay in
lock-step (the `# SYNC:` discipline): `bin/docker_wrapper`'s `image[<tool>]`
registry, the pre-commit `docker_image` hooks, and the CI meta job's pinned
`shellcheck`/`shfmt`. The current registry mixes registries and pin qualities
— e.g. `koalaman/shellcheck:v0.11.0` and `mvdan/shfmt:v3.13.1` (Docker Hub,
tag-pinned), `cytopia/yamllint:latest` and `prettier:latest` (Docker Hub,
**unpinned** — a `docker.md` violation), `hadolint/hadolint@sha256:…`
(digest-pinned), and our own `ghcr.io/harleypig/{ansible-lint,perltidy,
perlcritic}` (private ghcr).

We surveyed the established multi-linter projects to decide what to reuse,
improve, or avoid:

- **MegaLinter** / **Super-Linter** — monolithic images (1–7 GB even in
  "flavors"/slim) bundling a **runner + config model + reporters**, built to
  scan a whole repo in CI. Huge coverage, but you inherit their orchestrator,
  their pins, and their size; they do not expose each linter as a plain CLI.
- **AZLint** — a curated ~48-tool bundle positioned as a complement; smaller,
  but still an upstream bundle *we don't control*.
- **Code Cleaner Buffet** — **build-your-own**: an Alpine image where tools
  are selected by `--build-arg <tool>=<version>` from per-tool Dockerfile
  fragments, and each tool keeps its **native interface** (check vs fix is
  just the caller's flags). This is essentially our target model.
- **cytopia awesome-ci** — many tiny **single-purpose**, pinned images (one
  tool each). Matches what we already do; the downside is many registry pulls.

The repo already contains the seed of the answer: `config/docker/perl-tools/
Dockerfile` is a **parameterized multi-stage image** — a fat build stage
`cpanm`s the tool set, a slim runtime `COPY`s only the installed tree, there
is **no ENTRYPOINT** (so `docker_wrapper` invokes each tool *by name*, and one
image can hold many tools), and it runs non-root at `WORKDIR /mnt`. Its own
header calls it "the seed of the roadmap's single combined tool image."

## Decision

Build and maintain **our own** multi-linter image — a **toolbox, not an
orchestrator** — generalizing the `perl-tools` pattern, and pointedly *not*
adopting MegaLinter/Super-Linter.

- **Toolbox, not orchestrator (the key "avoid").** The image ships only the
  **tools**, invoked by name (`docker run <image> <tool> …`), with **no**
  bundled runner, config model, or reporters. Orchestration — per-file
  selection, parallelism, check-vs-fix modes — already lives in **pre-commit**
  (the `.pre-commit-config.yaml` / `-fix.yaml` split) and **CI**. We do not
  rebuild that; adopting MegaLinter's runner would duplicate it and drag in
  gigabytes.
- **Multi-stage, artifacts-only, debian-slim runtime.** Pull each **static
  binary straight from its official pinned image**
  (`COPY --from=koalaman/shellcheck:v0.11.0 …`), install Node/Python tools in
  isolated stages, and `COPY` only the results into a `debian:stable-slim`
  final stage carrying no compilers or package caches (`docker.md`). Final
  base is **debian-slim, not Alpine** (Code Cleaner Buffet's choice): musl
  breaks some Python wheels and glibc-only binaries, and the size delta is
  small once multi-stage.
- **Check vs fix is the caller's flags**, never a mode baked into the image —
  matching both the existing pre-commit check/fix config split and Code
  Cleaner Buffet's native-interface model.
- **Published to private ghcr**, like `perl-tools`/`ansible-lint`, via
  `publish-tool-images.yml` (build on PR, push on merge to master). One
  authenticated ghcr image replaces several Docker Hub pulls — directly
  addressing the Docker-Hub-flakiness item.
- **Pins in one manifest, SYNC'd across consumers**, guarded by the existing
  version-sync `bats` tests (`test_docker_wrapper.bats`). Digest-pin
  supply-chain-sensitive tools (`hadolint`, per `trivy.md`/`docker.md`);
  version-pin the rest.
- **Adopt `ruff` for Python**, retiring the `flake8`/`isort`/`yapf`/`black`
  plan the TODO listed: one fast static Rust binary that lints *and* formats
  and subsumes all four.
- **Start unified; split by runtime only if `dive` says so.** One image for
  the core set; measure with `dive` against a budget (~500 MB — still ~1/10th
  of MegaLinter). The multi-stage structure makes a later split into
  `lint-static` (tiny) + `lint-node` + reusing `perl-tools` mechanical, so we
  do not split preemptively (`qa.md` measure-first).

**Initial core set** (what the repo already gates, plus `ruff`): shell
(`shellcheck`, `shfmt`), YAML (`yamllint`), Dockerfile (`hadolint`), Markdown
(`markdownlint-cli`), JS/JSON/CSS/MD/YAML formatting (`prettier`), Python
(`ruff`). `perltidy`/`perlcritic` stay in `perl-tools` for now; folding them
in is trivial later (same slim base family). Expansion slots (a build stage, a
`bin/<tool>` symlink, and a hook each): `actionlint`, `taplo`, `Vale`,
`ansible-lint`, `gitleaks`.

### Phased rollout

1. **Build + publish the image** (its own PR): the `lint-tools` Dockerfile, a
   `publish-tool-images.yml` matrix entry, and the `config/docker/.gitignore`
   allowlist. The PR-build verifies the Dockerfile; merge publishes to ghcr.
   **No consumers re-pointed yet** — zero migration risk in this step.
2. **Wire consumers incrementally**, once the image is proven on ghcr: add
   `ruff` as a new `bin/ruff` (purely additive — nothing to migrate), then
   re-point the existing `docker_wrapper` entries and pre-commit hooks to the
   combined image one at a time, updating **both** asserting test files each
   time (`test_docker_wrapper.bats` **and** `test_docker_wrapper_links.bats` —
   the `--images` assertion checks each full image string) and re-pinning the
   digest after the first publish.

## Consequences

- One maintained image we control replaces a spread of third-party images and
  Docker Hub pulls, unifying the wrapper + pre-commit + CI on a single pinned
  artifact — the SYNC surface shrinks from many images to one, and the
  existing version-sync tests generalize to guard it.
- We own the maintenance: version bumps, base-image CVE tracking (`trivy`),
  and size (`dive`). This is the deliberate trade for control and size —
  accepted over inheriting a multi-GB upstream bundle plus its orchestrator.
- A size floor exists: static-binary tools combine into tens of MB, but Node
  (`prettier`, `markdownlint`) and Python (`yamllint`) tools each drag in a
  runtime. The one-image start keeps consumption simple; the measure-first
  split path is the escape hatch if the budget is exceeded.
- The rollout is reversible per step — deleting the image and reverting the
  registry pins restores the per-tool images. The decision is recorded here so
  it is not silently re-litigated as the TODO research thread is pruned.

## Update (2026-07-24): Python-runtime tools stay out of the combined image

Measuring the Phase-2 consolidation refined the "split by runtime" escape
hatch above into a standing rule: **a tool that needs a Python *runtime* is
kept out of the combined image and handled with the other Python tools later,
in the python setup (likely via `pipx` / `uv`).** Two consequences:

- **`ruff` stays in the combined image** — it is a static Rust binary that
  lints Python but needs *no* Python runtime, so it folds in like the other
  static binaries. Phase 2 exposes it as a new `bin/ruff` backed by the
  published image.
- **`ansible-lint` is not folded** (the trigger for this refinement).
  Evidence: `ansible==14.2.0` needs **Python ≥ 3.12**, but the `node:22-slim`
  base ships Python 3.11 (so the fold would need a *copied* Python 3.13
  runtime); and the standalone ansible-lint image is **540 MB** on its own
  (ansible + collections ≈ 420 MB), which would push the combined image to
  ~850 MB — nearly double, and far over the ~500 MB budget. It keeps its own
  image, digest-pinned in Phase 2.
- **`yamllint`** (Python) was included in the Phase-1 image; it too belongs
  with the Python tools. Extracting it (rebuilding the combined image without
  the Python runtime) is deferred to the python-setup work that re-homes
  `yamllint` + `ansible-lint` together via `pipx` / `uv`.

So the combined image trends toward **non-Python linters only** (static
binaries + Node tools + `ruff`); the Python-runtime linters are a separate,
later batch.

## Update (2026-07-24): rename `lint-tools` → `code-tools`

`lint-tools` misleads for the same reason the runner did (renamed `run-tools`,
ADR-0006): the image holds **formatters** (`shfmt`, `prettier`) as well as
linters, and `ruff` is both. The image is renamed **`code-tools`** — tools
that operate on code — published as `ghcr.io/harleypig/code-tools`.

The rename is **bundled with the next image rebuild** (the ADR-0006
implementation — adding the `run-tools` runner, converting hooks, and
extracting `yamllint`), not done standalone: that rebuild already republishes
and re-pins the image, so renaming there means **one** republish + **one**
re-pin of every consumer (the `docker_wrapper` `image[]` entries, the
pre-commit hooks) + **one** ghcr cleanup, instead of two. Until then, the
live references stay `lint-tools` (the published `0.1.0` image); the rebuild
flips them all to `code-tools` atomically and deletes the old `lint-tools`
ghcr package. Tracked in `TODO.md`.
