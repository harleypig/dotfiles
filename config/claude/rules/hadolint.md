---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/*.dockerfile"
---

# hadolint Rules

**Version:** v1.0.0

hadolint lints Dockerfiles against best practices (and the inline shell in
`RUN` via shellcheck). It is the enforcement arm of the policy in
[`docker.md`](docker.md); read that for the *why* behind the findings.

## Invocation

```bash
hadolint <Dockerfile>
```

Run after creating or modifying any Dockerfile matched by the paths above.
The global config sets `failure-threshold: warning`, so warnings and errors
fail; style/info findings inform but do not block. Fix everything at or above
the threshold before committing.

## Inline Disables

`# hadolint ignore=DLxxxx` on the line **immediately above** the instruction
disables a rule for that instruction only. Allowed when:

- The flagged construct is intentional and correct.
- A comment explains why (same line or adjacent).

```dockerfile
# hadolint ignore=DL3008  # base image pins apt versions in a vendored list
RUN apt-get update && apt-get install -y ca-certificates
```

Never suppress a code without a reason. Project-wide ignores belong in the
config (`ignored:`), not scattered inline.

## Configuration File

hadolint searches the working directory first
(`.hadolint.yaml` / `.hadolint.yml`), then falls back to
`$XDG_CONFIG_HOME/hadolint.yaml` / `~/.config/hadolint.yaml`.

Global config lives at `config/hadolint.yaml` in this repo, which resolves to
`$XDG_CONFIG_HOME/hadolint.yaml` since `$DOTFILES/config/` is
`$XDG_CONFIG_HOME`. It sets `failure-threshold: warning` and restricts `FROM`
to `docker.io` / `ghcr.io` (`trustedRegistries`, DL3026). A repo-local
`.hadolint.yaml` at the repo root overrides it for that repo.

## Docker Wrapper

`bin/hadolint` is a Docker wrapper (image pinned by digest, per `docker.md`).
It mounts `$PWD` as `/mnt` and runs there, so all file arguments must be
relative to `$PWD`; passing a file outside `$PWD` exits before docker runs.
The global config is mounted in as the in-container fallback. Run from the
repo root or the directory holding the Dockerfile.

## Agent Behavior

- Run `hadolint <Dockerfile>` after any Dockerfile change; fix all findings
  at or above `warning` before continuing. Inline ignores require a reason.
- Honour the best-practice policy in `docker.md` (pinning, layer hygiene,
  non-root, secrets) — hadolint catches most of it, but not all.
- In pre-commit context: `.pre-commit-config.yaml` checks only; there is no
  auto-fix variant for hadolint (it is check-only).
