---
paths:
  - "**/.github/dependabot.yml"
  - "**/.github/dependabot.yaml"
---

# Dependabot Rules

**Version:** v1.0.0

Dependabot (native GitHub) opens PRs for dependency and version updates. It
is the **durable** counterpart to scanning: scanners (trivy, semgrep) find
problems; Dependabot keeps dependencies current so they don't appear. Config
lives at `.github/dependabot.yml`.

## Coverage

Declare an `updates` entry for **every** manifest the repo ships, not just
the language deps — gaps are where drift hides:

- Language deps — `pip` (also covers Poetry), `npm`, `cargo`, `gomod`, etc.,
  one entry per manifest directory.
- **`docker`** — bumps `FROM` pins in each Dockerfile's directory. This is
  the durable fix for base-image CVEs (otherwise patched by stopgap
  `apt`/`apk` upgrade layers).
- **`github-actions`** — keeps workflow action pins current (and patched;
  relevant after the 2026 action-supply-chain incidents).

## Conventions

- `version: 2`.
- **Schedule weekly** (daily is noisy; monthly lags security fixes).
- **Group minor/patch** updates into one PR per ecosystem to cut PR volume;
  let **major** bumps come as individual PRs so they get individual review.
- Conventional commit messages: `commit-message: { prefix: "chore", include:
  "scope" }` → `chore(deps): ...`.
- A modest `open-pull-requests-limit` (the default 5 is usually fine once
  grouping is on).

## Interaction with CI / branch protection

- Dependabot PRs run through the repo's normal required checks (build, lint,
  scans). That is the safety net — a bump that breaks the build or trips a
  scanner fails its own PR.
- Dependabot cannot read repo/org secrets by default. If a required check
  needs a secret, grant it via a `dependabot` environment/secret or the
  job will fail on Dependabot PRs.

## Agent Behavior

- When adding or editing `dependabot.yml`, ensure **all** manifests are
  covered, including `docker` and `github-actions`.
- Reviewing Dependabot PRs: a green grouped minor/patch PR is normally safe
  to merge; **review major bumps individually** (changelogs, breaking
  changes) — never blanket-auto-merge majors.
- Do not silence a Dependabot security alert by ignoring the advisory;
  prefer the bump, or document why it is not applicable.
