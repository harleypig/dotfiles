---
paths:
  - "**/docker-compose*.yml"
  - "**/docker-compose*.yaml"
  - "**/compose.yml"
  - "**/compose.yaml"
  - "**/Dockerfile"
---

# OWASP ZAP (DAST) Rules

**Version:** v1.1.0

OWASP ZAP is the **DAST** layer — Dynamic Application Security Testing: it
scans the **running** app over HTTP for issues that static analysis can't see
(missing security headers, injection, XSS, auth/cookie problems, info leaks).
Complements SAST (`semgrep.md`), dependency/image CVE scans (`trivy.md`),
and malicious-package detection (`osv-scanner.md`). Run the **pinned OSS image
directly** — no marketplace action, no SaaS (same posture as the others).

## Two modes

- **Baseline scan** (`zap-baseline.py`) — passive: spider + inspect
  responses. Fast (~1–5 min), low false-positive. Use as a **per-PR gate**.
- **Full active scan** (`zap-full-scan.py`) — actively attacks every
  endpoint/param. Slow and variable (~15 min to hours) — **time-box** it and
  run it **nightly/scheduled**, not per-PR. **API endpoints:** drive coverage
  from the OpenAPI spec with `zap-api-scan.py -f openapi`.

## Time-boxing the active scan (it does NOT resume)

A time-boxed active scan **does not pick up where it left off** — ZAP scans
are stateless per run, so a hard kill at the budget means the next run starts
over from the beginning. On a large app a hard cap can mean you *never* finish.
For complete coverage despite a budget:

- **Scope it, don't open-ended-spider.** Drive the API scan from the
  **OpenAPI spec** (`zap-api-scan -f openapi`): coverage is bounded by and
  complete for the declared endpoints, and it skips slow discovery. This alone
  usually finishes well under an hour, so the cap is just a guardrail.
- **Tune for speed:** lower attack strength, disable slow/low-value active
  rules, raise thread count, set ZAP's own `maxScanDurationInMins` so it ends
  gracefully (reporting what it covered) rather than being killed mid-rule.
- **If it still exceeds the budget,** get completeness another way:
  - **Weekly full + nightly quick** — a long/uncapped full scan weekly
    (hours are fine on a schedule) plus a fast nightly baseline/targeted scan;
    or
  - **Partition & rotate** — split the app by path/context and scan a
    different slice each night, covering everything over a cycle.
- **Session persistence** (save/load ZAP's session as an artifact and scan
  only un-scanned nodes) *can* approximate resuming, but it's fiddly and not a
  first-class flow — avoid it until the app genuinely outgrows the options
  above.

## Running it (needs the app up)

DAST requires a running target, so CI stands up the stack first (e.g.
`docker compose up`), waits for readiness, then runs ZAP against it
(`--network host` so the container reaches the published ports). That
"stack-up-in-CI" harness is **shared with end-to-end testing** — build it once.

```bash
docker run --rm --network host --volume "$PWD/.zap:/zap/wrk:rw" \
  <pinned-zap-image> zap-baseline.py -t http://localhost:8080 -c baseline-rules.tsv
```

`/zap/wrk` **must be writable** (ZAP writes its report there) — a `:ro` mount
makes the run error (exit 3). Exit codes: `0` clean, `1` FAIL-level alert,
`2` WARN, `3` error.

## Allowlisting & reporting

- Reviewed/accepted findings go in a **`baseline-rules.tsv`** allowlist (tab-
  separated `ruleId<TAB>IGNORE<TAB>note`), mounted into `/zap/wrk` — never by
  loosening the gate. Each `IGNORE` needs a justification, same as a
  `nosemgrep` / `.trivyignore` waiver. Gitignore ZAP's other scratch output.
- **Per-PR baseline:** the finding is the failing check + the job log.
- **Nightly active scan:** no PR to attach to — surface findings as an
  **auto-created/updated GitHub Issue** (via `gh`), not a PR (DAST findings
  need triage, not auto-merge). Attach the full report as a workflow artifact.
  (On a private repo without GitHub Advanced Security there's no
  code-scanning UI — the Issue is the surface.)

## Rollout

Like SAST: a first baseline run will flag **missing security headers** (CSP,
X-Content-Type-Options, X-Frame-Options, Permissions-Policy, …). Add it
**non-required first** (visible, not blocking), fix the headers + allowlist
the informational findings, then **promote to a required check**.

## Agent Behavior

- Run/extend the baseline after changes that affect HTTP responses or add
  endpoints. Fix real findings (add the header, fix the endpoint); only
  allowlist informational/deliberate ones, with a reason.
- Keep the active scan time-boxed and scheduled; surface its findings as an
  auto-issue. Run the digest-pinned image directly; never a marketplace action.
