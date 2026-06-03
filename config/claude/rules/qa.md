# Quality Assurance Rules

**Version:** v2.2.0

QA is the full pipeline that takes a change from "written" to
"release-ready." This rule is **language- and tool-agnostic**: it defines the
QA *dimensions*, their *ordering*, and the *discipline*. It does **not**
mandate specific tools — the concrete toolchain and commands for a given repo
live in **that repo's own `.claude/` QA doc** (e.g. a "Quality assurance"
section in its `CONVENTIONS.md`), and the detection-activated per-tool rules
(`biome.md`, `semgrep.md`, …) own each tool's invocation/config. Any tool
named here is an **illustrative example, never a requirement.**

The **qa-check** skill is the forcing function: it reads the current repo's
QA doc for the concrete commands and runs the pipeline below against them.

Not every dimension applies to every repo (a library has no UI or e2e; a
script repo may have no build step). Apply the ones that fit; treat a
dimension that *should* exist but doesn't as a **gap to surface**, not to
skip silently.

## Pipeline (cheap/fast stages first; fail fast)

1. **Format** *(auto-fix)* — run the repo's formatter(s) (e.g. a JS/TS
   formatter, a Python formatter, `shfmt`).
2. **Lint** — static analysis for correctness/style (e.g. an ES/TS linter,
   `flake8`/`ruff`, `shellcheck`, doc/YAML linters).
3. **Type-check** — where the language is typed (e.g. `tsc`, a Python type
   checker).
4. **Code smell / complexity** — smell/complexity rules. Some linters include
   them; some stacks need a dedicated tool. If nothing covers it, **name the
   gap.**
5. **Security** — the layered set: **SAST** (static), **SCA** (dependencies/
   supply-chain — vulns *and* licenses), **DAST** (runtime scan of the
   running app, for services/web apps), IaC/image scanning, and secrets.
   Delegate to the **security-scan** skill.
6. **Tests** — unit/integration; cover success **and** failure paths; track
   coverage. Per the repo's `TESTS.md`.
7. **UI/UX & accessibility** *(repos with a UI)* — visual correctness,
   layout, responsiveness, and a11y (semantic markup, keyboard nav, focus
   order, contrast). Often manual; do the manual pass **even when no tooling
   exists yet.**
8. **End-to-end** *(apps)* — real user flows through the running system
   (e.g. a browser-driver), exercised **across the target browser/device
   matrix**. Distinct from unit tests. Exercise the critical flow even before
   an automated suite exists; flag the missing automation.
9. **Compatibility** *(multi-target products)* — behaves across the targets it
   claims to support. Its **device/browser/OS** facet is largely *verified
   through* UI/UX (responsive layout across viewports) and End-to-end (flows
   across the target matrix) — track it there, don't duplicate. What is
   distinct here is **interoperability/coexistence**: APIs, data formats, and
   shared resources working with other systems. N/A for a single-target
   product with no external contracts.
10. **Performance & load** *(where it matters)* — responsiveness, throughput,
    and resource use under expected and peak load (load/stress/soak). Pairs
    with the measure-first stance below — premature here is as wrong as
    absent; document which it is.
11. **Reliability & observability** — graceful failure/recovery, health
    checks, and the monitoring/alerting that surfaces issues. Largely
    runtime/post-deploy, so often **outside** the pre-merge gate —
    acknowledge it (status it) rather than pretend it's covered.
12. **Build** — the artifact actually compiles/bundles, and images build
    (the **containerize** skill) when containers change. Note size deltas.
13. **Code review** — human peer review of the change. A gate, not a tool;
    state whether/how it is required (e.g. PR approvals) or, for a solo repo,
    that it is informal.
14. **CI** — the applicable stages above run in CI and gate merges via the
    repo's required checks; watch CI to green after pushing.

## Fix-then-check discipline

- Auto-fixers run **once** as a final prep step; a check-only pass then
  confirms clean (`pre-commit.md`). Do **not** fix-and-recommit mid-session
  in response to individual failures.
- Checks (lint, type, test, scan) never mutate — they gate.

## Idioms — consistency is a QA property

- Match the surrounding code's idioms (`code-style.md`): naming, structure,
  comment density, paragraph spacing. Correct-but-foreign code fails
  QA-by-consistency.
- The repo's own conventions win over general habits. Idioms serve
  readability, not themselves — clarity first.

## Optimization — measure first; premature optimization is a smell

- Do **not** optimize without evidence. Establish a baseline (profile,
  benchmark, measured latency / memory / artifact size) before changing code
  for speed or size.
- Premature optimization is itself a code smell QA should flag.
- When you do optimize: measure before/after, keep it isolated and
  reviewable, prefer the simplest approach that hits the target.

## Completeness lens: ISO/IEC 25010

This pipeline is **activity-based** ("what checks we run"). Periodically audit
it against **ISO/IEC 25010** (the product-quality standard), which is
**attribute-based** ("what qualities the product has") — the two are
complementary, since activities *assure* attributes. Its characteristics:
functional suitability, performance efficiency, compatibility, usability
(incl. accessibility), reliability, security, maintainability, portability,
safety. A characteristic with **no assuring activity** is a candidate gap
(e.g. performance efficiency with no perf test; reliability with only a
health check). Use ISO 25010 as a checklist to confirm coverage — not as a
reason to restructure this doc.

## Where the specifics live

| Layer | Holds | Example |
|-------|-------|---------|
| This rule (`qa.md`) | dimensions, ordering, discipline (generic) | "run a formatter, then lint, then type-check" |
| Repo `.claude/` QA doc | the repo's concrete tools + commands + required checks | "`npm run check` then `tsc -b` then `npm test`" |
| Per-tool rules (detection-activated) | each tool's invocation/config | `biome.md`, `semgrep.md`, … |
| Skills | forcing functions that run it | **qa-check**, composing **security-scan** + **containerize** |

## The repo QA doc covers every dimension, with a status

A repo's QA doc must document **every** dimension above — including the ones
it does **not** do — each with an explicit **status**, so the QA picture is
complete and auditable (no silent absences). Status vocabulary:

- **Active** — in place and enforced; document the command/gate.
- **Planned** — intended but not built yet; **link** the `TODO.md` /
  `docs/ROADMAP.md` item.
- **Off** — deliberately not done; **state the reason** (e.g. "no linter for
  this language yet", "format-only, no separate linter").
- **N/A** — does not apply to this repo type (e.g. UI/UX and e2e for a
  headless library or CLI).

So "we don't lint X" is a documented decision, not a gap someone discovers
later. A dimension with no entry at all is itself a QA defect.

## Agent Behavior

- Run QA via the **qa-check** skill (or the stages manually) in order,
  fail-fast, before finishing a change or opening a PR.
- Get the concrete commands from the **repo's QA doc**, not from this rule —
  tools named here are examples only.
- Report each stage's outcome **and its documented status**; never claim
  "clean" without running it.
- When authoring/updating a repo QA doc, give **every** dimension a status
  (Active / Planned+link / Off+reason / N/A) — never omit one.
- For **Planned**/**Off**/undocumented dimensions, surface the status and,
  when appropriate, suggest concrete options for implementing it.
