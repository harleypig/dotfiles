---
name: deps-update
description: Run a deliberate dependency-update sweep — inventory what's outdated, triage by risk and security-urgency, read the changelogs, apply updates in safe batches, and compat-gate each batch with qa-check. The proactive, considered counterpart to Dependabot's automated PRs. Use for "update the dependencies", "are my deps outdated", "upgrade the packages", "bump dependencies", "get the deps current", "update the lockfile". Subject-/ecosystem-agnostic; takes concrete commands from the ecosystem's rule. Composes security-scan (vuln urgency) and qa-check (compat gate). qa / dependency maintenance.
---

# deps-update

**Version:** v1.0.0

The **on-demand, human-driven** dependency-currency sweep: audit what's
behind, decide what to move, read what changed, and prove compatibility with
the test/type/build pipeline — in safe batches. It keeps dependencies from
drifting into a forced big-bang upgrade.

## When to reach for it

You want to **proactively** get dependencies current — a deliberate sweep, a
batch of bumps, or a careful major-version upgrade — rather than react to a
stream of bot PRs. Also the home for "are we behind, and what would it take to
catch up?"

## Type / composition

A **skill** (a maintenance procedure you invoke and watch), in the qa /
dependency-maintenance orbit — **no new category, no rule**. It composes
`security-scan` (which updates are *security*-urgent — don't re-derive vuln
data), `qa-check` (the compatibility gate), and `debug-assistant` (when a
batch goes red, to find which bump broke it). Concrete per-ecosystem commands
come from that ecosystem's rule (`poetry.md`, …) — generic procedure,
specific tooling (the layering principle).

## Boundaries — what this is *not*

- **Not vuln scanning.** Finding/gating *vulnerable* deps (CVEs, SCA) →
  `security-scan`. This skill consults it for urgency but is about
  **currency**, not vulns.
- **Not Dependabot config.** The automated, scheduled, one-PR-per-bump bot →
  `dependabot.md`. This is its **proactive, considered counterpart** — they
  complement each other; a repo can use both.

## Procedure

1. **Inventory the outdated.** For each ecosystem in the repo, list the
   outdated **direct** dependencies with current → latest and the jump type
   (patch / minor / major), using that ecosystem's own command (e.g. `poetry
   show --outdated`, `npm outdated`, `cargo outdated`). Get the exact command
   from the ecosystem rule.
2. **Triage by risk × urgency.** **Security-urgent first** — consult
   `security-scan` for which bumps close a known vuln. Then split the rest:
   patch/minor (low-risk) vs **major** (potentially breaking) — pin each major
   for individual handling.
3. **Read the changelog.** For every non-patch bump, read the release
   notes/changelog and flag breaking changes, deprecations, and required
   migrations. Never bump a major blind.
4. **Apply in safe batches.** Patch + minor together; **each major alone**.
   Update the lockfile, and keep direct-dependency version constraints
   intentional — don't silently widen ranges.
5. **Compat-gate with `qa-check`.** Run the full pipeline (tests, type-check,
   build) **after each batch** — green is the compatibility proof. A red batch
   → use `debug-assistant` to isolate which bump broke it, then fix or hold
   that one.
6. **Record.** Add a changelog entry; note any code changed to accommodate a
   major; if a bump changes how a library is *used*, update that library's
   `rules/<name>.md` (the governing-docs layer, `documentation.md`). **Surface
   what was held back** (and why — a transitive constraint, a costly
   migration) rather than silently skipping it.

## Output

A sweep summary: **updated** (by batch), **held** (with the reason),
**code changed** for any major, and the `qa-check` result per batch. Call out
anything needing a human decision — a major whose migration is non-trivial —
rather than forcing or skipping it.

## Provenance

Adapted (idea-level) from the mining census — `claude-tools` `deps-update`
(dependency auditor with compatibility testing + changelog review). No
upstream code reused. See `SOURCE.md`.
