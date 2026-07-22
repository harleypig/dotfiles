# Integration-test harness for bin/xdg-audit.
#
# xdg-audit is core-only Perl, but its `--update-db` mode shells out to
# `git clone`, so this image carries git (+ ca-certificates) alongside a full
# perl (Debian's `perl` package includes the core modules xdg-audit uses:
# JSON::PP, Digest::SHA, File::Copy / File::Path / File::Basename, File::Temp,
# Errno, ...). The repo under test is mounted read-only at /dotfiles at run
# time; tests copy the vendored database to a writable path (xdg-audit builds
# its index there) and use throwaway $HOME dirs so a real --remove / --migrate
# mutation can never touch the host. Tests run a plain bash command; a
# --tmpfs mount at run time provides a genuinely separate filesystem for the
# cross-filesystem --migrate cases (see tests/helpers/common.bash xdg_audit_run).
#
# Separate from the vmgr harnesses: those carry download/build toolchains this
# one does not need, and this one carries git, which they do not.

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       bash ca-certificates git perl \
  && rm -rf /var/lib/apt/lists/*

ENV PATH="/dotfiles/bin:${PATH}"
WORKDIR /root
