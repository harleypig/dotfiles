# Base image for the repo's pinned Perl QA tool images (perltidy, perlcritic,
# ...). A single PARAMETERIZED Dockerfile: each tool image is a build of this
# with MODULES set to the cpanm module spec(s) it needs, so every image shares
# one base and definition. This is deliberately the seed of the roadmap's
# single combined tool image - that image is just this Dockerfile built with
# the full module list, no new Dockerfile:
#
#   perltidy   : --build-arg MODULES="Perl::Tidy@<v>"
#   perlcritic : --build-arg MODULES="Perl::Critic@<v>"                  (F3)
#   combined   : --build-arg MODULES="Perl::Tidy@<v> Perl::Critic@<v> ..."
#
# There is no ENTRYPOINT: the docker_wrapper invokes the tool by name
# (`docker run <image> perltidy ...`), so one image can run any tool it holds -
# which is exactly what the combined image needs.
#
# Built + pushed to ghcr.io/harleypig/<tool> by
# .github/workflows/publish-tool-images.yml (private packages).

FROM perl:5.40-slim

# Space-separated cpanm module spec(s), e.g. "Perl::Tidy@20250912". Required -
# the build fails loudly if unset so an image is never published toolless.
ARG MODULES

# hadolint ignore=DL3059,SC2086  # single reproducible layer; MODULES is a
# deliberately word-split list of cpanm specs.
RUN test -n "$MODULES" \
  && cpanm --notest --no-man-pages $MODULES \
  && rm -rf /root/.cpanm

# Run as non-root (docker.md). The repo is mounted at /mnt by the wrapper.
RUN useradd --create-home --shell /bin/bash tool
USER tool
WORKDIR /mnt
