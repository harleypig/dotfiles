# Integration-test harness for bin/xdg-audit.
#
# xdg-audit is core-only Perl, but its `--update-db` mode shells out to
# `git clone`, so this image carries git (+ ca-certificates) alongside a full
# perl (Debian's `perl` package includes the core modules xdg-audit uses:
# JSON::PP, Digest::SHA, File::Copy / File::Path / File::Basename, File::Temp,
# Errno, ...). It also carries gettext-base for `envsubst`, which the sibling
# check-dotfiles (driven by `--migrate symlink` / `--fix`) uses to expand the
# dotlinks lines. The repo under test is mounted read-only at /dotfiles at run
# time; tests copy the vendored database to a writable path (xdg-audit builds
# its index there) and use throwaway $HOME dirs under /tmp so a real --remove /
# --migrate mutation can never touch the host. Tests run a plain bash command;
# a --tmpfs mount at run time (mode 1777) provides a genuinely separate
# filesystem for the cross-filesystem --migrate cases (see
# tests/helpers/common.bash xdg_audit_run).
#
# Runs as a NON-ROOT user, because that is how xdg-audit is actually used —
# it operates on a real user's $HOME, not root's. Tests therefore keep their
# throwaway dirs under writable, non-root-creatable paths (/tmp, the tmpfs).
#
# Separate from the vmgr harnesses: those carry download/build toolchains this
# one does not need, and this one carries git, which they do not.

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       bash ca-certificates gettext-base git perl \
  && rm -rf /var/lib/apt/lists/*

# A non-root user with a writable HOME (xdg-audit runs as the user, not root).
RUN useradd --create-home --shell /bin/bash tester

USER tester
WORKDIR /home/tester
ENV PATH="/dotfiles/bin:${PATH}"
