# TODO

- [ ] Document the "symlink trick" for manually verifying `shell-startup`
      end-to-end outside the bats/docker harness. `DOTFILES` only resolves
      to the real checkout when `${BASH_SOURCE[0]}` is a **symlink**
      (`shell-startup`'s own `[[ -L ${BASH_SOURCE[0]} ]]` check) — directly
      `source`-ing the file from a worktree path silently falls back to
      `DOTFILES=$HOME` and every module load silently no-ops. The fix:
      `ln -sf /path/to/worktree/shell-startup /tmp/some-name && source
      /tmp/some-name`. Note this in `.claude/TESTS.md` near the
      `tests/docker/` harness section (which already gets this right via
      `dotfiles_login`'s container entrypoint) so a future ad hoc host-side
      manual check doesn't rediscover it the hard way. Also note that the
      docker harness image has no `mise` installed, so it can't exercise
      the mise-specific PROMPT_COMMAND path — host-side (with the symlink
      trick) is the only way to verify a real tool's activation today.
      (Surfaced during PR #411's manual verification, 2026-09-16.)
- [ ] Re-point `bin/docker_wrapper`'s `image[perltidy]`/`image[perlcritic]`
      and the perltidy/perlcritic pre-commit hooks
      (`.pre-commit-config.yaml`, `.pre-commit-config-fix.yaml`) to the new
      combined `ghcr.io/harleypig/perl-tools:1.0.0` image once it's
      published (its digest is only known after this PR merges and CI
      publishes it — `docker pull ghcr.io/harleypig/perl-tools:1.0.0` then
      `docker inspect --format '{{index .RepoDigests 0}}'`), then remove
      the now-redundant `perltidy`/`perlcritic` matrix entries and delete
      their ghcr packages. Part of #362.
- [ ] Add `bats-support`, `bats-assert`, and `bats-file` to `WORKFLOW.md`'s
      *Prerequisites* list alongside `bats-core` — they are separate apt
      packages `common.bash`'s `load_bats_libs` assumes are already at
      `/usr/lib/bats`, and a fresh environment with only `bats-core`
      installed has no way to run the suite until someone notices and
      vendors them by hand. Surfaced running PR #419 (issue #402) in a
      sandbox with `bats-core` present but none of the three support libs
      and no `sudo` to `apt-get install` them — worked around by
      `git clone`-ing `bats-core/bats-support`, `bats-core/bats-assert`,
      and `bats-core/bats-file` into a scratch dir and pointing
      `BATS_LIB_PATH` at it for that one run, 2026-09-16.
