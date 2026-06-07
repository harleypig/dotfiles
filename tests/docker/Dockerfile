# Integration-test harness for dotfiles startup.
#
# This image is only the *runtime* — the repo under test is mounted read-only
# at /dotfiles at run time (so the tests exercise the current checkout, not a
# baked-in copy). The default entrypoint deploys the minimal dotfiles entry
# points and runs a login shell; tests that need a clean environment (e.g.
# check-dotfiles) override the entrypoint and invoke the script directly.

FROM debian:bookworm-slim

# bash + the few tools shell-startup needs to come up: gettext-base provides
# envsubst (used by bin-dirs/dotlinks), git for the prompt, locales so the
# en_US.UTF-8 LC_ALL shell-startup sets is actually available.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       bash ca-certificates gettext-base git less locales \
  && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen \
  && rm -rf /var/lib/apt/lists/*

# A non-root user with a writable HOME — startup (XDG dirs) and check-dotfiles
# (ln -fs) write there.
RUN useradd --create-home --shell /bin/bash tester

COPY entrypoint.sh /usr/local/bin/dotfiles-entrypoint
RUN chmod +x /usr/local/bin/dotfiles-entrypoint

USER tester
WORKDIR /home/tester
ENTRYPOINT ["/usr/local/bin/dotfiles-entrypoint"]
