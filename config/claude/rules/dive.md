---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/*.dockerfile"
---

# dive Rules

**Version:** v1.0.0

dive inspects a built image layer by layer to find wasted space (files added
then deleted/overwritten in later layers) and report an efficiency score. It
is the measurement tool behind the image-size guidance in
[`docker.md`](docker.md). Lightly but still maintained (v0.13.x, 2025); no
real alternative for layer analysis.

## Invocation

```bash
dive <local-image>        # interactive TUI: explore layers + wasted space
dive <local-image> --ci   # non-interactive: evaluate rules, non-zero on fail
```

Use the TUI to investigate *why* an image is large; use `--ci` for a
scriptable pass/fail gate.

## Configuration File

`--ci` thresholds come from a repo-local `.dive-ci` (working dir), e.g.:

```yaml
rules:
  lowestEfficiency: 0.95      # fail below 95% efficiency
  highestWastedBytes: 20MB    # fail above this wasted space
  highestUserWastedPercent: 0.10
```

Keep thresholds realistic for the stack; a multi-stage build that copies only
artifacts forward usually scores near 100%.

## Docker Wrapper

`bin/dive` is a Docker wrapper (image pinned by digest). It mounts the docker
socket (with its group) to read local images, allocates a TTY only when
attached (so the TUI works interactively while `--ci` stays non-interactive),
and mounts a repo-local `.dive-ci` if present.

## Agent Behavior

- Reach for dive when an image is unexpectedly large or after a change that
  could bloat layers — not on every Dockerfile edit. Investigate with the
  TUI; if adding a CI gate, use `--ci` with a `.dive-ci`.
- Fixes for wasted space follow `docker.md` layer hygiene (clean caches in
  the same `RUN`, order layers least- to most-frequently-changing, prefer
  multi-stage to drop build tooling).
