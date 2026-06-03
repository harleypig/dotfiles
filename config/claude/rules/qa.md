# Quality Assurance Rules

**Version:** v1.0.0

QA is the full pipeline that takes a change from "written" to
"release-ready." This rule is the **orchestrating policy** — it defines the
stages, their order, and the discipline, and **routes** to the per-tool
rules for the *how* (it never restates them). The **qa-check** skill is the
forcing function that actually runs the pipeline.

Not every dimension applies to every repo or every change; run the ones the
repo has, and treat the ones it lacks as **known gaps to surface**, not to
silently skip.

## Pipeline (run cheap/fast stages first; fail fast)

1. **Format** *(auto-fix)* — biome (js/ts/css), black + isort (py), shfmt
   (bash). Rules: `biome.md`, `black.md`, `isort.md`, `shfmt.md`.
2. **Lint** — biome, flake8 (py), shellcheck, markdownlint, yamllint, hadolint
   (Dockerfiles). Rules: `biome.md`, `python.md`, `shellcheck.md`,
   `markdownlint.md`, `yamllint.md`, `hadolint.md`.
3. **Type-check** — `tsc` (`typescript.md`), pyright (`python.md`).
4. **Code smell / complexity** — partly covered by the linters above plus
   semgrep; most stacks have **no dedicated complexity tool** by default.
   Prefer a consolidated linter that adds smell rules where the stack allows
   (e.g. **ruff** for Python — format + import-sort + lint + many smell rules
   in one). Name the gap when there isn't one.
5. **Security scan** — SAST (`semgrep.md`), dependency/supply-chain
   (`dependabot.md`, `trivy fs`), image CVEs (`trivy.md`). Orchestrated by the
   **security-scan** skill.
6. **Tests** — unit/integration (pytest, `vitest.md`); cover success **and**
   failure paths; track coverage. Per the repo's `TESTS.md` and language
   testing rules.
7. **UI/UX review** — visual correctness, layout, responsiveness, and
   **accessibility** (semantic HTML, keyboard nav, focus order, contrast,
   ARIA). Largely manual today; partially automatable (axe, Lighthouse). This
   is a real QA stage — at minimum a deliberate visual check — **even when no
   tooling exists yet.**
8. **End-to-end** — real browser flows (**Playwright** preferred; WebdriverIO
   alt). Distinct from unit tests (Vitest is *not* e2e). Include as a
   dimension and check the critical flows **even before an automated suite
   exists**; flag the missing automation.
9. **Build** — compile + bundle (e.g. `tsc -b && vite build`) and image build
   (`docker.md` / the **containerize** skill) when containers change. A QA
   pass confirms the artifact actually builds (and note bundle-size deltas).
10. **CI** — the above run in GitHub Actions (`github-actions.md`); required
    status checks gate merges. After pushing, watch CI to green.

## Fix-then-check discipline

- Auto-fixers (format, import-sort) run **once** as a final prep step; the
  check-only pass then confirms clean (`pre-commit.md`). Do **not**
  fix-and-recommit mid-session in response to individual hook failures.
- Checks (lint, type, test, scan) never mutate — they gate.

## Idioms — consistency is a QA property

- Match the surrounding code's idioms: the paragraph code-style
  (`code-style.md`), naming, structure, comment density. A change that is
  correct but stylistically foreign fails QA-by-consistency.
- Repo-specific conventions (`CONVENTIONS.md` / `WORKFLOW.md`) win over
  general habits.
- Idioms are not a licence for cleverness; clarity first. Idioms are not a
  panacea — they serve readability, not themselves.

## Optimization — measure first; premature optimization is a smell

- Do **not** optimize without evidence. Establish a baseline (profile,
  benchmark, measured latency / RSS / bundle size) before changing code for
  speed or size.
- Premature optimization is itself a code smell QA should flag: complexity
  added for unmeasured gains.
- When you *do* optimize: measure before/after, keep the change isolated and
  reviewable, and prefer the simplest approach that hits the target.
  Optimization is not a panacea — most code is not hot.

## Routing table

| Dimension     | Tool(s)                                  | Rule / skill           |
|---------------|------------------------------------------|------------------------|
| Format        | biome, black, isort, shfmt               | `biome.md` etc.        |
| Lint          | biome, flake8, shellcheck, yamllint, …   | per-tool rules         |
| Type-check    | tsc, pyright                             | `typescript.md`, `python.md` |
| Code smell    | flake8/ruff, semgrep                     | `semgrep.md` (+ ruff)  |
| Security      | semgrep, trivy, dependabot               | **security-scan** skill |
| Tests         | pytest, vitest                           | `vitest.md`, repo `TESTS.md` |
| UI/UX, a11y   | manual; axe/Lighthouse (future)          | repo `TESTS.md`        |
| End-to-end    | Playwright (planned)                     | repo `TESTS.md`        |
| Build / image | tsc+bundler, docker build                | **containerize** skill |
| CI            | GitHub Actions                           | `github-actions.md`, `pre-commit.md` |

## Agent Behavior

- Before finishing a change or opening a PR, run the QA pipeline (via the
  **qa-check** skill, or the stages manually) in order, fail-fast.
- Route to the per-tool rules for invocation/config; do not restate them.
- Report each stage's outcome; never claim "clean" without having run it.
- Include **UI/UX** and **end-to-end** as checklist items even when no
  automated tooling exists — do the manual check and flag the missing
  automation.
- Treat absent dimensions (no e2e suite, no a11y tooling, no complexity
  linter) as **gaps to surface**, not to skip silently.
