---
# No paths — the QA pipeline applies to every change regardless of
# file type.
---

# Quality Assurance Rules

**Version:** v2.6.0

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
   `flake8`/`ruff`, `shellcheck`, doc/YAML linters). Linters enforce only the
   mechanical slice of style; conventions they cannot enforce are covered by
   the **Code style audit** (below).
3. **Type-check** — where the language is typed (e.g. `tsc`, a Python type
   checker).
4. **Code smell / complexity** — smell/complexity rules. Some linters include
   them; some stacks need a dedicated tool. If nothing covers it, **name the
   gap.**
5. **Security** — the layered set: **SAST** (static), **SCA** (dependencies/
   supply-chain — vulns *and* licenses), **DAST** (runtime scan of the
   running app, for services/web apps), IaC/image scanning, and secrets.
   Delegate to the **security-scan** skill. Keeping dependencies *current* —
   proactive, considered upgrades beyond vuln-patching — is the
   **deps-update** skill (which compat-gates each batch with `qa-check`).
6. **Tests** — unit/integration; cover success **and** failure paths; track
   coverage. Test-suite structure/conventions live in `testing.md`; the
   concrete layout and policy in the repo's `TESTS.md`.
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
13. **Documentation** — runs the **documentation bar** (`documentation.md`,
    which owns it): the docs are **current** and **accurate** across every
    layer that rule names (user-facing incl. the **changelog**, in-repo
    planning, the governing rules/skills it affects — global *and* local, and
    inline); prose is linted (e.g. a Markdown linter) with no stale or broken
    references; a change that alters behaviour but not its docs is incomplete.
    The **`write-documentation`** skill authors/refreshes a doc; the `adr`
    skill records decisions. When a repo's **changelog is generated** (from
    git history or commit metadata), regenerating it **mutates the tree**, so
    it is a **prep step in the same class as Format** (dimension 1) — run it
    once just before opening the PR and **commit the result**; never in CI,
    which gates and must not commit. The concrete command lives in the
    repo's QA doc.
14. **Code review** — human peer review of the change. A gate, not a tool;
    state whether/how it is required (e.g. PR approvals) or, for a solo repo,
    that it is informal.
15. **CI** — the applicable stages above run in CI and gate merges via the
    repo's required checks; watch CI to green after pushing.

## Fix-then-check discipline

- Auto-fixers run **once** as a final prep step; a check-only pass then
  confirms clean (`pre-commit.md`). Do **not** fix-and-recommit mid-session
  in response to individual failures.
- Checks (lint, type, test, scan) never mutate — they gate.

## Code style audit — consistency is a QA property

Format and Lint (dimensions 1–2) enforce only the *mechanical* slice of
style; the rest of `code-style.md` is a judgment audit no tool runs for you.
Audit the change against `code-style.md` (plus any repo override in
`.claude/`), checking the conventions tools cannot:

- **Naming** — intent-revealing, matching the language's and the surrounding
  code's casing.
- **Paragraph spacing** — blank lines between distinct statements/blocks;
  condense only tightly-related groups.
- **Section & function separators** — thick for sections, thin for functions,
  with any exception noted at the file/repo level.
- **Comments** — wrapped (72 cols, or the repo's limit), explaining *why* not
  restating code; public APIs documented.
- **Abstraction (Rule of Three)** — genuine repetition extracted; no
  premature or wrong abstraction.
- **Efficiency by default** — prefer the efficient idiom when it is no less
  clear; avoid needless pessimization (and premature optimization — see
  below).

Match the surrounding code's idioms; correct-but-foreign code fails
QA-by-consistency. The repo's own conventions win over general habits —
idioms serve readability, not themselves, so clarity comes first.

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
| Skills | forcing functions that run it | **qa-check**, composing **security-scan**, **containerize**, and the per-dimension review skills below |

Several dimensions have a global, cross-language **review skill** that
`qa-check` composes (these *assess* a whole codebase — distinct from the
diff-level `/code-review` · `/simplify`, and from *running* the suite):
**arch-review** (4 — code-smell/complexity/maintainability), **test-review** (6
— test-suite *quality*, vs executing), **a11y-review** (7 — UI/UX &
accessibility), **perf-review** (10 — performance). Python implementation depth:
**pytest-patterns**, **typing-patterns**. These are *our* tools, named here as
the standing ones; per-repo concrete tools still live in the repo's QA doc.

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
- Run the **Code style audit** against `code-style.md` (plus any repo
  override) for the conventions formatters/linters cannot enforce — naming,
  paragraph spacing, section/function separators, comment wrap/density, Rule
  of Three, efficiency by default — and report deviations.
- When authoring/updating a repo QA doc, give **every** dimension a status
  (Active / Planned+link / Off+reason / N/A) — never omit one.
- For **Planned**/**Off**/undocumented dimensions, surface the status and,
  when appropriate, suggest concrete options for implementing it.
