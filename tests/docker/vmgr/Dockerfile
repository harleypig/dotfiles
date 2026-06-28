# Integration-test harness for bin/vmgr.
#
# Unlike the startup harness (tests/docker/), vmgr's tests install REAL
# toolchains, so this image carries what the native managers need: git (clone
# nvm), curl (nvm downloads Node; uv's standalone installer), xz-utils + tar
# (extract the Node tarball), ca-certificates (TLS), python3 + python3-pip
# (prereqs for the python managers - pip is PEP 668-managed here, exercising
# uv as the pipx fallback). The managers themselves (nvm, uv, pipx) are
# deliberately NOT preinstalled - the point is to prove vmgr installs them.
#
# The repo under test is mounted read-only at /dotfiles at run time, and
# /dotfiles/bin is on PATH so `vmgr` resolves directly. Tests run a plain
# bash command (no dotfiles login shell needed).

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       bash ca-certificates curl git xz-utils python3 python3-pip \
  && rm -rf /var/lib/apt/lists/*

# A non-root user with a writable HOME - vmgr writes the manager into the XDG
# data dir under $HOME.
RUN useradd --create-home --shell /bin/bash tester

USER tester
WORKDIR /home/tester
ENV PATH="/dotfiles/bin:/home/tester/.local/bin:${PATH}"
