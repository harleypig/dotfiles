---
# On-demand: loads only when a workflow file is edited, since trufflehog's
# whole concern is the `secret-scan.yml` GitHub Actions workflow. The
# security-scan skill reads this rule by name when it runs, so nothing that
# needs it depends on the per-turn tier.
paths:
  - ".github/workflows/**"
---

# trufflehog Rules

**Version:** v1.1.0

## Detection

Active when a repo runs trufflehog — in this repo, the `secret-scan.yml`
GitHub Actions workflow (PR-time secret scanning).

## What it is

trufflehog (`trufflesecurity/trufflehog`, AGPL-3.0) is a secret scanner with
**verification**: for each candidate it authenticates against the provider's
API and reports whether the secret is *live*, eliminating the
revoked-pattern-match false-positive class. It ships 800+ detectors. A hosted
Enterprise tier exists and is **not** used here.

## Lane — layered with gitleaks, not duplicating it

Two secret scanners run, in distinct lanes; keep them there:

- **gitleaks** — the fast, no-network **commit-time** guard (pre-commit Phase
  2) plus the CI pre-commit job. Stays the local/commit gate.
- **trufflehog** — the **PR-time** verified deep scan in CI
  (`secret-scan.yml`, `on: pull_request`). It scans the PR diff and verifies
  hits, which makes outbound API calls — which is exactly why it is **not** a
  pre-commit or dev-local hook.

Run on **`pull_request`**, not every push: under protected-master nothing
reaches the default branch except via a PR, so PR-time gates where it counts
without scanning throwaway branch pushes. Every-push is for continuous,
high-assurance/regulated repos; it is overkill for a personal repo.

## Invocation

Run the **digest-pinned OSS image directly**, never the marketplace action
(the security-scan skill's standing posture — same as semgrep). Pin the tag so
Dependabot's `github-actions` ecosystem bumps it:

```bash
docker run --rm -v "$PWD:/repo:ro" \
  ghcr.io/trufflesecurity/trufflehog:<tag>@sha256:<digest> \
  git file:///repo --since-commit "<pr-base-sha>" \
  --results=verified,unknown --fail --no-update
```

- `--results=verified,unknown` — report verified secrets **and** ones it could
  not verify (so an unverifiable-but-real secret is not silently dropped);
  drops the known-revoked/false class.
- `--since-commit <base>` — scan only the PR's new commits (the diff). Requires
  `actions/checkout` with `fetch-depth: 0`.
- `--fail` — non-zero exit when results are found, so the job gates.
- `--no-update` — never self-update; the pinned image is the version.

The image tag is `MAJOR.MINOR.PATCH` (no `v` prefix); the GitHub *release* tag
is `vMAJOR.MINOR.PATCH`.

## Gating

**Non-required first** (security-scan skill): the check runs on PRs but is not
yet in the branch ruleset's required checks. Promote it to required once it has
a clean track record — a ruleset change needing the OAuth admin token (see
`WORKFLOW.md`).

## Limitations

- Verification makes outbound API calls — never wire it as a commit-time or
  dev-local hook; that lane is gitleaks'.
- AGPL-3.0 licensed.

## Sources

- `trufflesecurity/trufflehog` README — GitHub Actions / CLI usage and the
  `--results=verified,unknown` guidance (fetched 2026-06-18):
  <https://github.com/trufflesecurity/trufflehog>

## Agent Behavior

- Keep trufflehog in its PR-time CI lane; do not add it to pre-commit or
  suggest dev-local runs — gitleaks owns commit-time.
- Run the digest-pinned image directly, never the marketplace action; let
  Dependabot bump the pin.
- Promote to a required check only after a clean track record.
