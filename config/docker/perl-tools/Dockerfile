# Base image for the repo's pinned Perl QA tool images (perltidy, perlcritic,
# ...). A single PARAMETERIZED Dockerfile: each tool image is a build of this
# with MODULES set to the cpanm module spec(s) it needs, so every image shares
# one base and definition. This is deliberately the seed of the roadmap's
# single combined tool image - that image is just this Dockerfile built with
# the full module list, no new Dockerfile:
#
#   perltidy   : --build-arg MODULES="Perl::Tidy@<v>"
#   perlcritic : --build-arg MODULES="Perl::Critic@<v>"
#   combined   : --build-arg MODULES="Perl::Tidy@<v> Perl::Critic@<v> ..."
#
# There is no ENTRYPOINT: the docker_wrapper invokes the tool by name
# (`docker run <image> perltidy ...`), so one image can run any tool it holds -
# which is exactly what the combined image needs.
#
# Multi-stage: the module set is built in the FULL perl image (it carries a C
# toolchain for XS dependencies - e.g. the PPI/Params::Util chain Perl::Critic
# pulls; perl:5.40-slim has none), then only the installed module tree is
# copied into a slim runtime, so the published image stays small and ships no
# compiler (docker.md).
#
# Built + pushed to ghcr.io/harleypig/<tool> by
# .github/workflows/publish-tool-images.yml (private packages).

FROM perl:5.40 AS build

# Space-separated cpanm module spec(s), e.g. "Perl::Tidy@20250912". Required -
# the build fails loudly if unset so an image is never published toolless.
ARG MODULES

# hadolint ignore=DL3059,SC2086  # single reproducible layer; MODULES is a
# deliberately word-split list of cpanm specs.
RUN test -n "$MODULES" \
  && cpanm --notest --no-man-pages $MODULES

FROM perl:5.40-slim

# The site modules and their scripts (perltidy, perlcritic, ...) from the build
# stage. Same perl version + arch, so compiled XS loads in the slim runtime.
COPY --from=build /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=build /usr/local/bin /usr/local/bin

# Run as non-root (docker.md). The repo is mounted at /mnt by the wrapper.
RUN useradd --create-home --shell /bin/bash tool
USER tool
WORKDIR /mnt
