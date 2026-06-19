---
name: security-scan
description: Run and wire up source/dependency security scanning (SAST + dependency/supply-chain), routing through the security rules so they get consulted. Use whenever the user works on code or dependency security: "run a security scan", "scan for vulnerabilities", "SAST", "set up Semgrep", "check/audit dependencies for CVEs", "enable Dependabot", "triage this Dependabot PR", "review the Semgrep findings", "are there known vulns in our deps", or any request to find, gate, or fix security issues in source or dependencies. For container image / Dockerfile scanning specifically, use the containerize skill instead (it owns trivy/hadolint).
---

# Security Scan

**Version:** v1.2.0

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
- **`rules/trufflehog.md`** — PR-time **verified** secret scanning in CI (the
  digest-pinned image, run directly). Distinct lane from the commit-time
  `gitleaks` pre-commit guard — keep them separate; don't make trufflehog a
  dev-local/pre-commit hook (it makes network calls to verify).

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
2. **Dependencies / supply chain** — **reconcile `.github/dependabot.yml` to
   full coverage** per `rules/dependabot.md` (the source of truth for ecosystems
   + conventions): scan the repo for every manifest / Dockerfile / workflow, map
   each to its ecosystem, **consult current official Dependabot docs before
   authoring** (schema keys + supported ecosystems change), add an `updates`
   entry for each (incl. `docker` + `github-actions`), apply the conventions
   (weekly, group minor/patch, `chore(deps)` messages), then **verify**
   (yamllint). This is dependabot *setup* — triaging the resulting PRs is the
   next step. For an ad-hoc check, `trivy fs .` surfaces dependency CVEs +
   secrets now.
3. **Triage Dependabot PRs** — green grouped minor/patch is usually safe to
   merge; review **major** bumps individually. Never blanket-auto-merge
   majors or silence an advisory without justification.
4. **Wire into CI (when setting up)** — add the scan as a job. **Default:
   run the digest-pinned OSS image directly** — no marketplace action, no
   vendor cloud, no token. It is reproducible, free, offline-capable, and
   Dependabot-bumpable, so it is the first choice wherever good OSS covers the
   dimension. Introduce a new gate **non-required first**, promote to required
   once clean (see `semgrep.md`).

   **Exception — a hosted SaaS / marketplace scanner, per repo, recorded.**
   The OSS-pinned default is a strong preference, not an absolute ban. A repo
   *may* adopt a hosted scanner (Snyk, CodeFactor, …) when it clears this bar:
   - it delivers results the OSS lane genuinely can't for *that* repo — a real
     dependency tree with curated vuln intel / reachability / one-click fix
     PRs, or a public maintainability grade/badge that signals repo health;
   - overlap with existing tools is acceptable — *some is fine; the test is
     whether the added results are worthwhile*, not whether they are unique;
   - the owner accepts the costs: a managed token/secret, an external account,
     engine versions outside the pin, SaaS read access, and (for token
     actions) that GitHub withholds secrets from fork PRs;
   - it is recorded in **that repo's** `.claude/` QA doc (per tool: what it
     adds, why the overlap is justified) and starts **non-required**, promoted
     only after a clean track record.

   An untraditional repo with no real dependency tree (e.g. this dotfiles
   repo) typically won't clear the bar — its dimensions are already covered by
   the OSS lane, so a hosted scanner only adds overlap without worthwhile
   results. A conventional app repo (a genuine Python / Ruby / JS dependency
   tree) is where the exception earns its place.

## Report

State what ran and the result: semgrep findings by severity (and any
`nosemgrep` waivers + why), dependency-scan CVE counts, and which Dependabot
ecosystems are covered. Don't call a repo "clean" without having run the scan.
