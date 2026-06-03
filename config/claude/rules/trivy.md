---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/*.dockerfile"
  - "**/docker-compose*.yml"
  - "**/docker-compose*.yaml"
  - "**/compose.yml"
  - "**/compose.yaml"
---

# trivy Rules

**Version:** v1.0.0

trivy is an all-in-one scanner: image vulnerabilities, filesystem/dependency
CVEs, IaC/Dockerfile misconfigurations, and exposed secrets. It complements
[`docker.md`](docker.md) (best practice) and `hadolint.md` (Dockerfile lint)
by checking what those cannot — the actual CVEs in base images and
dependencies.

## Supply-Chain Pinning (READ FIRST)

trivy was compromised **twice** in March 2026:

- The **binary v0.69.4** was malicious (C2 callout); Docker images
  **v0.69.5 / v0.69.6** were pulled for the same reason.
- The **`aquasecurity/trivy-action`** (all tags 0.0.1–0.34.2 except 0.35.0)
  and **`aquasecurity/setup-trivy`** GitHub Actions were trojaned
  (CVE-2026-33634).

Consequences for how we run it:

- **Pin the image by digest, never a floating tag.** The wrapper pins
  `aquasec/trivy` by digest.
- **In CI, run the pinned image directly — do NOT use the marketplace
  Actions.** If an action is unavoidable, only `trivy-action@0.35.0` and
  `setup-trivy@v0.2.6`, each **SHA-pinned**, are known-good.
- Current clean release line is **v0.71.0+**.

## Invocation

```bash
trivy image <local-image>     # CVEs in a built image (via docker socket)
trivy fs .                    # dependency CVEs + secrets in the repo tree
trivy config .                # Dockerfile / compose / IaC misconfigurations
```

Run a relevant scan after building or changing an image, or after changing
dependency manifests/lockfiles. Default behaviour fails nothing; gate
explicitly with `--severity HIGH,CRITICAL --exit-code 1` (optionally
`--ignore-unfixed` to ignore CVEs with no released fix).

## Configuration File

- A repo-local `trivy.yaml` (working dir) sets defaults (scanners, severity,
  exit code); CLI flags override it.
- A repo-local `.trivyignore` lists CVE IDs to accept, **one per line with a
  trailing comment justifying each** — treat like an inline disable, not a
  silent waiver. Prefer `--ignore-unfixed` over ignoring fixable CVEs.

## Docker Wrapper

`bin/trivy` is a Docker wrapper (image pinned by digest). It:

- mounts `$PWD` as `/mnt` and runs there (so `fs .` / `config .` scan the
  repo; path args must be under `$PWD`);
- mounts a persistent vuln-DB cache at `${XDG_CACHE_HOME:-~/.cache}/trivy`
  so the DB is not re-downloaded each run;
- mounts the docker socket (with its group) so `trivy image <local-image>`
  can read locally-built images.

## Agent Behavior

- After building or materially changing a Dockerfile/image, run
  `trivy image` on the built image and `trivy config` on the Dockerfile;
  surface HIGH/CRITICAL findings and prefer a base-image bump to a waiver.
- After changing dependency manifests/lockfiles, run `trivy fs .`.
- When wiring trivy into CI: run the **digest-pinned image directly**, cache
  the DB, gate on `--severity HIGH,CRITICAL --exit-code 1`. Never reach for
  `aquasecurity/trivy-action` / `setup-trivy` (see *Supply-Chain Pinning*).
- `.trivyignore` entries require a per-CVE justification comment.
