---
name: perf-review
description: Assess the runtime performance of code — find hotspots, algorithmic-complexity problems, N+1/query issues, needless allocation/copying, sync-in-async, missing caching, and resource leaks — measure-first, ranked by measured impact. Use for "is this slow", "where's the bottleneck", "profile this", "performance review", "will this scale", "why is this endpoint slow". The tool for qa.md's Performance & load dimension. Distinct from arch-review (structure) — this is runtime behavior.
---

# perf-review

**Version:** v1.0.0

Assess **runtime performance** and return findings ranked by *measured*
impact. Subject-agnostic. This is the tool for `qa.md`'s **Performance & load**
dimension, and it follows `qa.md`'s **measure-first** stance to the letter:
premature optimization is itself a smell.

## Measure first — the rule that governs this skill

> Do **not** call something slow, or change it for speed, without evidence.

Establish a **baseline** (profile, benchmark, or a measured latency / memory /
throughput number) before claiming a problem or proposing a fix. A finding
without a measurement behind it is a hypothesis, and must be labelled as one.

## Type / agent use

A **skill** you invoke. The measurement/profiling step can be **read- and
output-heavy** (profiler dumps, large traces) — delegate that to a
**subagent** that runs/reads the profile and returns just the hotspots,
keeping the noise out of this conversation.

## What to look for

Once you have a baseline, hunt — hottest path first:

- **Algorithmic complexity** — accidental O(n²) (nested scans), work repeated
  per-iteration that could be hoisted out of the loop.
- **Data access** — N+1 queries, missing indexes, fetching more than used,
  chatty round-trips.
- **Allocation/copying** — buffering a whole collection when streaming would
  do, copies that aren't used (the efficiency-by-default rule in
  `code-style.md`).
- **Concurrency** — blocking calls on an async path; serial work that could be
  parallel; lock contention.
- **Caching** — recomputation of stable results; absent memoization at a hot,
  pure boundary.
- **Resource lifecycle** — leaks (unclosed handles/connections), unbounded
  growth, missing back-pressure under load.

## Output

Lead with the measured baseline, then findings by impact:

```markdown
## Performance review — <scope>

**Baseline:** <the measurement — p95 latency / mem / throughput, and how taken>

1. 🔴 `path` — <hotspot>, measured <evidence> → <direction> (est. <impact>)
2. 🟡 <hypothesis, NOT yet measured> — <how to confirm>
```

Separate **measured** findings from **hypotheses**. **Assess and recommend —
do not optimize** in this pass; an actual change is a separate, measured
before/after step (`qa.md`). Flag anything sampled rather than measured in
full.

## Provenance

Adapted (idea-level) from the mining census — `claude-tools` `perf-check` /
`performance-engineer` (+ `database-optimizer` for the data-access lens). No
upstream code reused. See `SOURCE.md`.
