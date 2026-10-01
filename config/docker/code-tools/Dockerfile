# Combined "toolbox" image (code-tools) for this repo's cross-language QA
# tools — formatters AND linters: shellcheck, shfmt, hadolint, markdownlint,
# prettier, ruff, vale, lychee. One image holds many tools; there is NO ENTRYPOINT, so
# bin/docker_wrapper invokes each by name (`docker run <image> shellcheck ...`)
# — the same model as config/docker/perl-tools and python-tools. See ADR-0005
# (and its rename + ADR-0006 hook-consolidation updates).
#
# No Python runtime: a tool that needs one belongs in config/docker/
# python-tools (ADR-0005, #370). ruff is here because it is a static binary.
#
# Multi-stage: each static binary is COPYed straight from its official pinned
# image (no compiling); the Node runtime (node:22-slim) is the final base since
# prettier/markdownlint need Node >= 20. Only artifacts land in the final image
# — no compilers, no package caches (docker.md).
#
# `run-tools` is a non-entrypoint on-PATH helper (ADR-0006) for a batched CI
# pass — it runs several tool invocations in one container; the tool-by-name
# path above is unaffected.
#
# Built + pushed to ghcr.io/harleypig/code-tools by
# .github/workflows/publish-tool-images.yml (private package). The image is
# versioned independently of the tools it holds (bump its tag when any pinned
# tool version below changes); the tool versions are the ARGs + FROM tags here,
# kept in SYNC with the docker_wrapper image[] pins and the pre-commit hooks
# when consumers are re-pointed (ADR-0005 Phase 2 / ADR-0006).

FROM koalaman/shellcheck:v0.11.0 AS shellcheck
FROM mvdan/shfmt:v3.13.1 AS shfmt
FROM hadolint/hadolint:v2.14.0-alpine AS hadolint
FROM ghcr.io/astral-sh/ruff:0.16.0 AS ruff

# Vale (prose linter, #385) plus the proselint style its config names. The
# official jdkato/vale image ships a musl-linked binary that will not run on
# this glibc base, so the glibc release tarball is fetched instead. The style
# is baked in rather than fetched by `vale sync`, so a hook run needs no
# network and the style version is pinned here with the binary. Every
# download is checksum-verified (ADD --checksum): bump a version together
# with its sha256.
FROM busybox:1.37.0 AS vale
ARG VALE_VERSION=3.23.0
ARG PROSELINT_VERSION=0.3.4
ADD --checksum=sha256:cc35445a45186b8f0b01e11c01359694cf941e72cf6ab0fc44774f0e54c9d5fc \
  https://github.com/vale-cli/vale/releases/download/v${VALE_VERSION}/vale_${VALE_VERSION}_Linux_64-bit.tar.gz \
  /tmp/vale.tar.gz
ADD --checksum=sha256:48b1fb481ba44f6505d44346b283f6cdc74efd234f913bbdb09bf34420fab81c \
  https://github.com/vale-cli/proselint/releases/download/v${PROSELINT_VERSION}/proselint.zip \
  /tmp/proselint.zip
RUN mkdir -p /out/styles \
  && tar -xzf /tmp/vale.tar.gz -C /out vale \
  && unzip -q /tmp/proselint.zip -d /out/styles \
  && chmod -R a+rX /out

# lychee (link checker, #452). The musl release tarball: unlike Vale's, it is
# static-pie linked, so it runs on this base — whose glibc (2.36) is too old
# for the gnu build (needs 2.39). Checksum-verified like Vale's above.
FROM busybox:1.37.0 AS lychee
ARG LYCHEE_VERSION=0.24.2
ADD --checksum=sha256:73657a111819a30c47c08352896796f23d64e4eb2b3ed39b6d32149241566fc5 \
  https://github.com/lycheeverse/lychee/releases/download/lychee-v${LYCHEE_VERSION}/lychee-x86_64-unknown-linux-musl.tar.gz \
  /tmp/lychee.tar.gz
RUN mkdir -p /out \
  && tar -xzf /tmp/lychee.tar.gz -C /tmp \
  && mv /tmp/lychee-x86_64-unknown-linux-musl/lychee /out/lychee \
  && chmod a+rx /out/lychee

FROM node:22-slim

# Tool version pins (SYNC target — see header). shellcheck/shfmt/hadolint/ruff
# are pinned by their FROM tags above.
ARG PRETTIER_VERSION=3.9.6
ARG MARKDOWNLINT_VERSION=0.48.0

COPY --from=shellcheck /bin/shellcheck /usr/local/bin/shellcheck
COPY --from=shfmt /bin/shfmt /usr/local/bin/shfmt
COPY --from=hadolint /bin/hadolint /usr/local/bin/hadolint
COPY --from=ruff /ruff /usr/local/bin/ruff
COPY --from=vale /out/vale /usr/local/bin/vale
COPY --from=vale /out/styles /opt/vale/styles
COPY --from=lychee /out/lychee /usr/local/bin/lychee
# lychee builds its HTTP client at startup and exits without a CA bundle,
# even under --offline, and node:22-slim ships none. The alpine hadolint
# stage already carries the Mozilla bundle, at the path rustls probes.
COPY --from=hadolint /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# One layer: the two Node tools, cache cleanup, and the non-root user
# (docker.md). npm's global prefix is /usr/local, so the tool bins land on
# PATH. DL3016 is ignored because the npm versions ARE pinned via ARG
# interpolation, which hadolint can't see as a literal pin.
# hadolint ignore=DL3016
RUN npm install -g "prettier@${PRETTIER_VERSION}" "markdownlint-cli@${MARKDOWNLINT_VERSION}" \
  && npm cache clean --force \
  && useradd --create-home --shell /bin/bash tool

# The batched-CI runner (ADR-0006). Non-entrypoint, on PATH; world-executable
# so it works under the wrapper's --user (arbitrary host uid).
COPY --chmod=755 run-tools /usr/local/bin/run-tools

# VALE_STYLES_PATH is Vale's default StylesPath when a .vale.ini sets none,
# so a repo config can name the baked styles without knowing where they live.
ENV VALE_STYLES_PATH=/opt/vale/styles
USER tool
WORKDIR /mnt
