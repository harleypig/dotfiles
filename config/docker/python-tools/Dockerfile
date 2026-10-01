# Image for the repo's Python-runtime QA tools — yamllint and ansible-lint —
# published to ghcr.io/harleypig/python-tools by
# .github/workflows/publish-tool-images.yml (private package). It is the
# Python-tools batch ADR-0005 keeps out of code-tools (#370): a tool that
# needs a Python runtime joins this image, not code-tools.
#
# bin/docker_wrapper and the yamllint pre-commit hook run each tool by name
# (`docker run <image> yamllint ...`), so there is NO ENTRYPOINT — the same
# model as code-tools and perl-tools.
#
# The full `ansible` community package is installed (not just ansible-core) so
# ansible-lint can resolve the common collections (community.general,
# community.docker, ansible.posix, ...) its rules reference. Repo-specific and
# git-sourced collections are NOT baked in — a consuming repo's CI installs its
# own requirements.yml and stays the authoritative lint gate; this image is the
# local-dev convenience CLI. ansible 14 needs Python >= 3.12, hence the base.
#
# Multi-stage: the venv is built in a throwaway stage and only the venv is
# copied into a fresh copy of the same base, so pip's build-time state never
# reaches the runtime image. The same base in both stages keeps the venv's
# interpreter symlink valid.
#
# The image is versioned independently of the tools it holds: bump its tag in
# publish-tool-images.yml when any ARG below changes, then re-pin the
# docker_wrapper image[] entries and the yamllint pre-commit hook to the new
# digest.

FROM python:3.13-slim AS build

ARG YAMLLINT_VERSION=1.38.0
ARG ANSIBLE_LINT_VERSION=26.6.0
ARG ANSIBLE_VERSION=14.2.0

RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir \
    "yamllint==${YAMLLINT_VERSION}" \
    "ansible-lint==${ANSIBLE_LINT_VERSION}" \
    "ansible==${ANSIBLE_VERSION}"

FROM python:3.13-slim

COPY --from=build /opt/venv /opt/venv

# The wrapper runs under the caller's --user with HOME=/tmp, so ansible-lint
# gets a writable cache; this user is only the default when none is given.
RUN useradd --create-home --shell /bin/bash tool

ENV PATH="/opt/venv/bin:${PATH}"
USER tool
WORKDIR /mnt
