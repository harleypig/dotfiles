---
name: containerize
description: Author, harden, scan, and size-check Docker images and compose files, routing every step through the Docker rules so they actually get consulted. Use whenever the user works with containers: "add a Dockerfile", "dockerize this", "containerize the app", "harden the image", "scan the image for CVEs", "lint the Dockerfile", "why is this image so big", "shrink the image", "review my Dockerfile", "write a docker-compose", or any request that creates, edits, builds, scans, or optimizes a Dockerfile / compose file / container image. Also use proactively right after creating or editing any Dockerfile.
---

# Containerize

**Version:** v1.0.0

Drive Docker work through its rules. The rules below are easy to forget
because container work is infrequent — this skill exists to force them into
the loop. It orchestrates; the rules remain the source of truth.

## Read first (load these rules)

Before touching a Dockerfile, compose file, or image, read:

- **`rules/docker.md`** — the policy: image pinning, layer hygiene, image
  size, non-root, secrets, compose. Everything else enforces this.
- **`rules/hadolint.md`** — Dockerfile linting.
- **`rules/trivy.md`** — CVE / misconfig / secret scanning. **Has a
  supply-chain section you must honour** (pin by digest; never use the
  `aquasecurity/trivy-action` / `setup-trivy` Actions).
- **`rules/dive.md`** — image-size / layer analysis (reach for it only when
  size is in question).

The tools run as zero-install Docker wrappers, all pinned by digest:
`bin/hadolint`, `bin/trivy`, `bin/dive`.

## Workflow

Not every step fires every time — match them to the request (a compose-only
change skips build/scan; a pure size question jumps to step 5). But never
skip lint+scan after authoring or changing a Dockerfile/image.

1. **Author / edit** — follow `docker.md`: pin the base by tag or digest
   (never `:latest`), order layers least- to most-frequently-changing, clean
   caches in the same `RUN`, multi-stage to drop build tooling, a non-root
   `USER` before `CMD`/`ENTRYPOINT`, a tight `.dockerignore`, no baked
   secrets.

2. **Lint** — `hadolint <Dockerfile>`. Fix everything at or above `warning`.
   Inline `# hadolint ignore=DLxxxx` needs a reason comment.

3. **Build** — build the image so it can be scanned and measured
   (`docker build -t <name> <context>`).

4. **Scan** — `trivy config <Dockerfile>` (misconfig) and
   `trivy image <name>` (base/dependency CVEs); `trivy fs .` after dependency
   manifest changes. Gate on `--severity HIGH,CRITICAL --exit-code 1`. Prefer
   bumping the base image over a `.trivyignore` waiver; any waiver needs a
   per-CVE justification.

5. **Size** — compare `docker images` sizes; if an image is unexpectedly
   large, run `dive <name>` (TUI) to find wasted space, then fix per
   `docker.md` layer hygiene.

6. **Wire into the project (when asked / when setting up a repo)** — add a
   check-only **hadolint** hook to `.pre-commit-config.yaml` (no fix variant;
   see `rules/pre-commit.md`); add a CI scan step that runs the
   **digest-pinned trivy image directly** (never the marketplace Action) and
   gates on HIGH/CRITICAL. Optionally a `dive --ci` gate with a `.dive-ci`.

## Report

State what you ran and the outcome: hadolint findings fixed, trivy
HIGH/CRITICAL counts (and any accepted waivers + why), and image size /
efficiency if size was in scope. Don't claim an image is "clean" without
having run the scan.
