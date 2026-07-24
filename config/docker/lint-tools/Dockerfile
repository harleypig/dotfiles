# Combined multi-linter "toolbox" image for this repo's cross-language QA tools
# (shellcheck, shfmt, yamllint, hadolint, markdownlint, prettier, ruff). One
# image holds many tools; there is NO ENTRYPOINT, so bin/docker_wrapper invokes
# each by name (`docker run <image> shellcheck ...`) — the same model as
# config/docker/perl-tools and ansible-lint. See ADR-0005.
#
# Multi-stage: each static binary is COPYed straight from its official pinned
# image (no compiling); the Node runtime (node:22-slim) is the final base since
# prettier/markdownlint need Node >= 20, and yamllint runs from a venv built
# with the image's own python3 (so the venv interpreter symlink stays valid).
# Only artifacts land in the final image — no compilers, no package caches
# (docker.md).
#
# Built + pushed to ghcr.io/harleypig/lint-tools by
# .github/workflows/publish-tool-images.yml (private package). The image is
# versioned independently of the tools it holds (bump its tag when any pinned
# tool version below changes); the tool versions are the ARGs + FROM tags here,
# kept in SYNC with the docker_wrapper image[] pins and the pre-commit hooks
# when consumers are re-pointed (ADR-0005 Phase 2).

FROM koalaman/shellcheck:v0.11.0 AS shellcheck
FROM mvdan/shfmt:v3.13.1 AS shfmt
FROM hadolint/hadolint:v2.14.0-alpine AS hadolint
FROM ghcr.io/astral-sh/ruff:0.16.0 AS ruff

FROM node:22-slim

# Tool version pins (SYNC target — see header). shellcheck/shfmt/hadolint/ruff
# are pinned by their FROM tags above.
ARG PRETTIER_VERSION=3.9.6
ARG MARKDOWNLINT_VERSION=0.48.0
ARG YAMLLINT_VERSION=1.38.0

COPY --from=shellcheck /bin/shellcheck /usr/local/bin/shellcheck
COPY --from=shfmt /bin/shfmt /usr/local/bin/shfmt
COPY --from=hadolint /bin/hadolint /usr/local/bin/hadolint
COPY --from=ruff /ruff /usr/local/bin/ruff

# One layer: python runtime + yamllint venv, the two Node tools, cache cleanup,
# and the non-root user (docker.md). npm's global prefix is /usr/local, so the
# tool bins land on PATH. Ignores: DL3016/DL3013 — the pip/npm versions ARE
# pinned via ARG interpolation, which hadolint can't see as a literal pin;
# DL3008 — the pinned base image (node:22-slim) already fixes the debian
# release, so pinning apt point-versions adds nothing and breaks on base
# rebuilds.
# hadolint ignore=DL3008,DL3013,DL3016
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 python3-venv \
  && rm -rf /var/lib/apt/lists/* \
  && python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir "yamllint==${YAMLLINT_VERSION}" \
  && npm install -g "prettier@${PRETTIER_VERSION}" "markdownlint-cli@${MARKDOWNLINT_VERSION}" \
  && npm cache clean --force \
  && useradd --create-home --shell /bin/bash tool

ENV PATH="/opt/venv/bin:${PATH}"
USER tool
WORKDIR /mnt
