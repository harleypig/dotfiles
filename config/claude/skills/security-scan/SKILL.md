---
name: security-scan
description: Run and wire up source/dependency security scanning (SAST + dependency/supply-chain), routing through the security rules so they get consulted. Use whenever the user works on code or dependency security: "run a security scan", "scan for vulnerabilities", "SAST", "set up Semgrep", "check/audit dependencies for CVEs", "enable Dependabot", "triage this Dependabot PR", "review the Semgrep findings", "are there known vulns in our deps", or any request to find, gate, or fix security issues in source or dependencies. For container image / Dockerfile scanning specifically, use the containerize skill instead (it owns trivy/hadolint).
---

# Security Scan

**Version:** v1.0.0

Drive source and dependency security through its rules. Security tooling is
periodic, so the rules are easy to forget — this skill is the forcing
function. It is tool- and repo-agnostic: it detects what a repo actually has
and applies the matching rules. It orchestrates; the rules are the source of
truth.

## Read first (load the rules that apply)

- **`rules/semgrep.md`** — SAST (insecure code you wrote). In-house: pinned
  OSS image, public rule packs, no Semgrep Cloud.
- **`rules/dependabot.md`** — dependency + base-image + action updates (keeps
  known-vulnerable components from accumulating).
- **`rules/trivy.md`** — dependency/secret scanning of the source tree
  (`trivy fs`) and the supply-chain pinning posture. (Image scanning lives in
  the **containerize** skill.)

## Scope to the repo

First detect what exists, then act only on those:

- Source languages (`*.py`, `*.ts/tsx`, `*.js`, …) → semgrep packs for each.
- Dependency manifests (`pyproject.toml`/`poetry.lock`, `package.json`,
  `go.mod`, …), Dockerfiles, and `.github/workflows` → Dependabot ecosystems.
- A private repo without GitHub Advanced Security has **no code-scanning /
  SARIF** — gate via exit code + CI logs, not the security UI.

## Workflow

Match steps to the request — a "triage this Dependabot PR" ask is just the
triage step; "set up scanning" is the wiring steps.

1. **SAST (semgrep)** — run the `p/...` packs for the languages present,
   gating on `--severity ERROR --error` (widen later). Fix ERROR findings;
   a true false positive gets `# nosemgrep: <rule-id>` + reason.
2. **Dependencies / supply chain** — ensure `.github/dependabot.yml` covers
   every manifest (incl. `docker` + `github-actions`), weekly + grouped. For
   an ad-hoc check, `trivy fs .` surfaces dependency CVEs + secrets now.
3. **Triage Dependabot PRs** — green grouped minor/patch is usually safe to
   merge; review **major** bumps individually. Never blanket-auto-merge
   majors or silence an advisory without justification.
4. **Wire into CI (when setting up)** — add the scan as a job running the
   **digest-pinned image directly** (never a marketplace action / vendor
   cloud). Introduce a new SAST gate **non-required first**, promote to
   required once clean (see `semgrep.md`).

## Report

State what ran and the result: semgrep findings by severity (and any
`nosemgrep` waivers + why), dependency-scan CVE counts, and which Dependabot
ecosystems are covered. Don't call a repo "clean" without having run the scan.
