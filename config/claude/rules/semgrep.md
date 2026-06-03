---
paths:
  - "**/*.py"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# Semgrep Rules

**Version:** v1.0.0

Semgrep is the SAST layer: pattern-based static analysis for security bugs
across languages. It complements dependency scanning (`dependabot.md`) and
image scanning (`trivy.md`) — those find *known-vulnerable components*;
semgrep finds *insecure code you wrote*.

## In-house, no cloud

- Run the **pinned `semgrep/semgrep` OSS image directly** (no marketplace
  action, no Semgrep Cloud). Pin by digest, per the supply-chain posture in
  `trivy.md`.
- Use **explicit public registry rule packs** — `p/python`, `p/typescript`,
  `p/react`, `p/security-audit`, `p/secrets`, etc. (fetched anonymously, no
  account).
- Do **not** use `semgrep ci` (needs a Semgrep App token) or `--config auto`
  (phones home to tailor rules). Both pull the project toward the SaaS.

## Invocation

```bash
semgrep scan --config p/python --config p/security-audit \
  --severity ERROR --error
```

`--severity ERROR` limits to high-confidence rules; `--error` makes the exit
code non-zero when there are findings (the gate). Drop `--severity` once the
codebase is clean enough to widen to WARNING.

The image has no entrypoint (`CMD` is `semgrep --help`), so invoke `semgrep`
explicitly after the image name in a `docker run`.

## Gating rollout

SAST is noisier than dependency/image scans, so introduce the gate gradually:

1. **Non-required, ERROR-only** — the job runs and fails on ERROR findings
   but is **not** in branch protection, so it is visible without blocking.
2. **Promote** to a required check once it runs clean.
3. Optionally widen severity (WARNING) later.

No code-scanning/SARIF on private repos without GitHub Advanced Security —
gate via exit code and read findings from the CI log.

## Triage

- Fix the root cause. A genuine false positive gets an inline
  `# nosemgrep: <rule-id>` **with a reason comment** (never a bare
  `# nosemgrep`, which disables every rule on the line).
- Path-level exclusions go in `.semgrepignore` (semgrep already skips
  git-ignored files and common vendor dirs).

## Agent Behavior

- After non-trivial source changes, run the relevant `p/...` packs for the
  languages touched; fix ERROR findings before continuing.
- Keep semgrep CI-only (it is slower than a formatter) — do not add it as a
  blocking pre-commit hook.
- Inline `# nosemgrep` requires a rule id + reason. Do not silence findings
  wholesale to make the gate pass.
