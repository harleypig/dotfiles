# Image for the repo's pinned ansible-lint, published to
# ghcr.io/harleypig/ansible-lint by .github/workflows/publish-tool-images.yml
# (private package). bin/docker_wrapper runs it by name
# (`docker run <image> ansible-lint ...`), so there is NO ENTRYPOINT — matching
# the perl-tools images, and letting one image hold more than one tool later.
#
# The full `ansible` community package is installed (not just ansible-core) so
# ansible-lint can resolve the common collections (community.general,
# community.docker, ansible.posix, ...) its rules reference. Repo-specific and
# git-sourced collections (e.g. robertdebock.roles, a git-source quera.github)
# are NOT baked in — a consuming repo's CI installs its own requirements.yml and
# stays the authoritative lint gate; this image is the local-dev convenience
# CLI. Both versions are pinned; bump the tag + these ARGs together (the tag in
# publish-tool-images.yml tracks ANSIBLE_LINT_VERSION).

FROM python:3.13-slim

ARG ANSIBLE_LINT_VERSION=26.6.0
ARG ANSIBLE_VERSION=14.2.0

# One RUN (no wheel cache, both packages pinned → deterministic for a tag) that
# also adds the non-root user (docker.md), so there are no consecutive-RUN
# layers (hadolint DL3059). The repo is mounted at /mnt by the wrapper, and
# HOME=/tmp (set by the wrapper) gives ansible-lint a writable cache under
# --user.
RUN pip install --no-cache-dir \
  "ansible-lint==${ANSIBLE_LINT_VERSION}" \
  "ansible==${ANSIBLE_VERSION}" \
  && useradd --create-home --shell /bin/bash tool
USER tool
WORKDIR /mnt
