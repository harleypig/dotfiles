---
paths:
  - "**/poetry.lock"
  - "**/package-lock.json"
  - "**/pnpm-lock.yaml"
  - "**/yarn.lock"
  - "**/go.sum"
  - "**/Cargo.lock"
  - "**/requirements*.txt"
---

# osv-scanner Rules

**Version:** v1.0.0

osv-scanner (Google, OSS) scans dependency lockfiles against **OSV.dev** —
which aggregates GHSA/PYSEC/etc. advisories **and** the OpenSSF
malicious-packages feed (`MAL-` IDs). It is the **supply-chain /
malicious-package** layer that CVE scanners miss: a typosquat or backdoored
release has no CVE, but it does get a `MAL-` advisory.

It overlaps the image/dep CVE scanner (`trivy.md`) on plain vulns — that
duplication is intentional (the two databases differ and one is sometimes
fresher); its **unique** value is the `MAL-` feed.

## Invocation

```bash
osv-scanner scan source --lockfile=<path> [--lockfile=<path> ...]
# or recursive (auto-discovers lockfiles, respects .gitignore):
osv-scanner scan source -r <dir>
```

Exit code is non-zero when any advisory matches, so a CI step that runs it
**hard-gates** on findings (malicious packages **and** vulns). Run it from
the pinned OSS image directly — no marketplace action, no SaaS (same posture
as `trivy.md` / `semgrep.md`).

## False positives & allowlisting

The `MAL-` feed has had false positives (OSV has withdrawn bad reports), so a
**reviewed** finding gets allowlisted in an **`osv-scanner.toml`** at the repo
root — never by loosening the gate:

```toml
[[IgnoredVulns]]
id = "MAL-2026-XXXX"        # or GHSA-…/PYSEC-…
reason = "reviewed false positive; <why>"
# optional: ignoreUntil = 2026-12-31
```

Pass it with `--config=<path>` (or rely on auto-discovery next to the
lockfile). Treat each entry like a `nosemgrep` / `.trivyignore` waiver: a
justification is mandatory, and a real malicious finding is fixed (remove the
dependency), not ignored.

## Relationship to the others

- **Dependabot** keeps deps current (prevents knowns); **trivy**/**osv-scanner**
  detect them; **semgrep** is SAST on your own code. osv-scanner adds the
  malicious-package detection none of the others specialize in.
- **Socket.dev** is the stronger *behavioral* alternative (catches new/
  zero-day malicious packages pre-publication) but is a third-party SaaS;
  note it as an option where an in-house OSS gate is preferred.

## Agent Behavior

- Run osv-scanner after dependency changes (or wire it as a CI gate). Surface
  any `MAL-` finding as **critical** — a malicious dependency must be removed,
  not waived.
- Plain-vuln findings: fix (bump) where possible; a deliberate waiver goes in
  `osv-scanner.toml` with a reason.
- Run the **digest-pinned image directly** in CI; never a marketplace action.
