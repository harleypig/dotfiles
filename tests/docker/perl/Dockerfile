# Integration-test harness for bin/vmgr's perl (perlbrew) manager.
#
# perlbrew COMPILES Perl from source, so this image carries a build toolchain:
# perl (to run the fat-packed perlbrew self-install script), build-essential +
# patch (compile Perl), curl + ca-certificates (download the pinned perlbrew
# script and the Perl source tarball). The manager (perlbrew) is deliberately
# NOT preinstalled - the point is to prove vmgr installs it.
#
# This is a SEPARATE image from tests/docker/vmgr/ (the node/python harness):
# that one lacks a C toolchain, which perlbrew needs. The repo under test is
# mounted read-only at /dotfiles at run time, and /dotfiles/bin is on PATH so
# `vmgr` resolves directly. Tests run a plain bash command (no login shell).

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       bash ca-certificates curl perl build-essential patch \
  && rm -rf /var/lib/apt/lists/*

# A non-root user with a writable HOME - vmgr writes perlbrew into the XDG data
# dir under $HOME.
RUN useradd --create-home --shell /bin/bash tester

USER tester
WORKDIR /home/tester
ENV PATH="/dotfiles/bin:/home/tester/.local/bin:${PATH}"
