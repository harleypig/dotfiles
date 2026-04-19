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

# Docker Rules

**Version:** v1.0.0

## Image Pinning

- **Never use `:latest`.** Pin to a specific tag (e.g. `alpine:3.19`) or,
  for anything security-sensitive or reproducible, a digest
  (`alpine@sha256:...`).
- Prefer distroless or minimal base images (`alpine`, `distroless`,
  `slim`) over full distros unless a full distro is genuinely needed.
- Track upstream for base image CVEs and bump pins deliberately, not
  opportunistically.

## Layer Hygiene

- Order layers from least- to most-frequently changing. Dependencies
  (lockfiles, system packages) before source code so build cache stays
  warm across iterations.
- Combine related `RUN` steps with `&&` to keep layer count down and
  avoid leaving intermediate artefacts in separate layers.
- Clean up package manager caches in the same `RUN` that installs:

  ```dockerfile
  RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl \
      && rm -rf /var/lib/apt/lists/*
  ```

- Use `.dockerignore` aggressively. Exclude `.git`, `node_modules`,
  build output, secrets, and anything not required by the build.
- Prefer multi-stage builds to drop build-time tooling from the final
  image.

## Security

- Run as a non-root user. Add `USER <name>` near the end of the
  Dockerfile; create the user in an earlier layer.
- Never bake secrets (tokens, keys, credentials) into layers. Use build
  args cautiously (they persist in history), BuildKit secrets
  (`RUN --mount=type=secret,...`), or runtime env/volumes.
- Use `COPY` over `ADD` unless you explicitly need `ADD`'s URL fetch or
  tar auto-extract behaviour.
- Set `WORKDIR` explicitly; do not rely on `/`.
- Prefer `ENTRYPOINT` (exec form) for the main command and `CMD` for
  default arguments.

## Docker Compose

- Pin image versions in compose files too.
- Use named volumes over bind mounts for persistent data.
- Expose only the ports that need host access; internal-only services
  use `expose:` instead of `ports:`.
- Keep secrets in `.env` (gitignored) or Docker secrets, never inline.

## Agent Behavior

- When creating or editing Dockerfiles:
  - Verify base image tags are pinned (never `:latest`).
  - Check that `RUN` steps installing packages also clean up caches in
    the same layer.
  - Confirm a non-root `USER` is set before the final `CMD`/`ENTRYPOINT`.
  - Flag any `ADD` usage without clear justification.
- When creating or editing compose files:
  - Verify image pins.
  - Flag inline secrets or credentials.
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes (hadolint is check-only;
  no auto-fix equivalent exists).
