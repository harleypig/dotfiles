# Claude Code Skills

A **skill** is not a markdown file — it is a *folder* of instructions,
scripts, resources, and optional config and hooks that Claude discovers and
uses on its own. The one required file, `SKILL.md`, is the entry point; a
`description` on it tells the model *when* to reach for the skill, and the
rest of the folder holds everything the procedure needs. This document is a
plain-language reference for skills as one mechanism on Claude's steering
surface: what a skill really is under the hood, the nine kinds of skill teams
build in practice, the authoring rules of thumb (and anti-patterns) that
separate a high-signal skill from context bloat, and how skills get
distributed and measured. It closes on where Anthropic's general guidance
lines up with — and where it goes beyond — this repo's own leaner skill
conventions.

## ELI5

Plain-language one-liners that double as a quick summary of everything this
doc covers. Details are in the sections below; every source link is at the
bottom.

*What a skill is:*

- **a skill** — a labeled folder Claude opens when a task matches it, holding
  the steps plus any scripts, examples, and data those steps need.
- **`SKILL.md`** — the one required file: a short "what this is and when to
  use it" up top, then the instructions.
- **the `description`** — the line the model reads to decide "is this skill
  for the job in front of me?" — written for the model, not for you.
- **progressive disclosure** — the skill names its other files so Claude only
  reads the deep detail when it actually needs it.

*Making a skill do more than talk:*

- **scripts** — ship reusable code so Claude composes instead of re-typing
  boilerplate every run.
- **`${CLAUDE_PLUGIN_DATA}`** — a stable folder the skill can write to, so it
  remembers things between runs (a log, some JSON, a small database).
- **on-demand hooks** — guardrails that switch on *only* while the skill is
  active (e.g. block destructive commands when you're touching prod).
- **`AskUserQuestion`** — ask the user for setup input as a tidy
  multiple-choice prompt, not a free-text guessing game.

*Sharing and checking on skills:*

- **plugin marketplace** — an internal store where people install the skills
  they want and skip the ones they don't (so context stays lean).
- **a `PreToolUse` hook** — quietly logs each time a skill fires, so you can
  see which skills earn their keep.

Skills are one primitive among several on the steering surface; subagents
(delegated workers) are the adjacent family — see [STEERING.md][steering] and
[SUBAGENTS.md][subagents].

### Best practices

- **Write the `description` for the model's routing decision, not for a
  human.** It is not a summary — it is a statement of *when to trigger this
  skill*, trigger keywords included. The model scans every skill's
  description to pick one; optimize for that scan.
- **Lead with a Gotchas section — it is the highest-signal content.** Capture
  the edge cases and failure points Claude can't infer (e.g. "the
  `subscriptions` table is append-only — the row you want is the highest
  *version*, not the newest `created_at`").
- **Don't restate what Claude already knows.** It can code and read the repo;
  a skill that describes the default path only adds context without value.
  Aim to *push Claude out of its normal way of thinking*.
- **Don't railroad.** Because skills are so reusable, over-specific
  step-by-step instructions backfire — give information and latitude, not a
  rigid script.
- **Keep concerns unmixed — one skill, one category.** The best skills fit
  cleanly into a single kind; ones that straddle several confuse the model.
- **Use progressive disclosure.** Tell Claude what files the skill contains
  and let it read them at the right moment; organize `references/`,
  `scripts/`, `examples/`, `assets/`.
- **Prefer scripts for deterministic work.** Shipping helper code lets Claude
  spend its turns *composing* rather than reconstructing boilerplate.
- **Persist state deliberately** via `${CLAUDE_PLUGIN_DATA}` when a skill must
  remember across runs; take setup input via `AskUserQuestion`, not prose.

## Overview

A skill packages a *procedure the model invokes inline* — Claude reads its
steps in the current context and follows them, no separate process. Per the
[official skills reference][docs-skills], Claude loads a skill automatically
when its `description` matches the task, or you invoke it by hand with
`/skill-name`; either way the body loads only when used, so its reference
material costs almost nothing until then. The
common misconception is that a skill is "just a markdown file"; in truth it
is a **folder**, and everything past the `SKILL.md` — scripts, reference
docs, examples, a `config.json`, even hooks — is what lets a skill do things
plain instructions cannot. Two axes organize the whole topic: *what a skill
is made of* (its anatomy) and *what job it does* (its category). Get the
category clean and the description model-facing, and the model routes to it
correctly; that routing is the single thing most skill quality hinges on.

### At a glance — the nine kinds of skill

The source post [catalogs nine recurring skill categories][blog] teams build
in practice. The strongest ones fit exactly one row; a skill that spans
several is a smell.

| Category | What it's for | Example |
|----------|---------------|---------|
| **Library / API reference** | Correct use of a library, CLI, or SDK, with gotchas | `billing-lib`, `sandbox-proxy` |
| **Product verification** | Drive and verify that code actually works | `signup-flow-driver`, `checkout-verifier` |
| **Data fetching & analysis** | Query patterns against a data / monitoring stack | `funnel-query`, `grafana`, `datadog` |
| **Business process / team automation** | Fold a repetitive workflow into one command | `standup-post`, `weekly-recap` |
| **Code scaffolding & templates** | Generate boilerplate from a natural-language ask | `new-migration`, `create-app` |
| **Code quality & review** | Enforce standards, assist review | `adversarial-review`, `code-style` |
| **CI/CD & deployment** | Fetch, push, ship, cherry-pick | `babysit-pr`, `deploy-<service>` |
| **Runbooks** | Map symptoms → investigation tools → a report | `<service>-debugging`, `oncall-runner` |
| **Infrastructure operations** | Routine ops and maintenance, with guardrails | `<resource>-orphans`, `cost-investigation` |

In table order: **library/API reference** skills encode the correct,
gotcha-aware way to call a dependency; **product verification** skills
actually exercise the running product to prove a change works — the category
with *the most measurable impact on output quality* internally; **data
fetching** skills carry the query patterns for a metrics/monitoring stack;
**business-process** skills collapse a recurring chore into one invocation;
**scaffolding** skills turn a described requirement into framework
boilerplate; **quality/review** skills apply standards and adversarial
review; **CI/CD** skills own the fetch-push-ship path; **runbooks** turn a
symptom into a guided investigation and a structured report; and
**infrastructure-ops** skills run routine maintenance behind guardrails.

## What a skill really is — the folder anatomy

The misconception worth killing first: a skill is *not* "just markdown." It
is a directory the agent can discover and use, and the file it opens first is
only the tip. The parts, from required to optional:

| Part | Role | Required? |
|------|------|-----------|
| `SKILL.md` | Entry point: YAML frontmatter (all fields optional; only `description` is recommended) then the instruction body | yes |
| `references/` | Deep docs Claude reads on demand (progressive disclosure) | no |
| `scripts/` | Reusable executables/helpers Claude composes rather than re-types | no |
| `examples/`, `assets/` | Worked examples and data files the steps draw on | no |
| `config.json` | Setup input, gathered via `AskUserQuestion` | no |
| Hooks | Behavior that activates *only while the skill runs* | no |
| `${CLAUDE_PLUGIN_DATA}` dir | A stable path for state that outlives a single run | no |

The `SKILL.md` format is the cross-vendor [Agent Skills open
standard][agentskills]. The [official reference][docs-skills] makes every
frontmatter field optional — only `description` (what the skill does *and
when* to reach for it) is recommended, and `name` defaults to the directory
name. Beyond those two, the fields that most change behavior are
`allowed-tools` (pre-approve tools the skill may call without a permission
prompt — it grants, it does not restrict), `disable-model-invocation: true`
(only *you* may trigger it, via `/name`), and `user-invocable: false` (only
Claude may, as background knowledge). The combined description text is
truncated at 1,536 characters in the skill listing, so lead with the key use
case. Where a skill lives sets who can use it: `~/.claude/skills/<name>/`
(personal, all your projects), `.claude/skills/<name>/` (this project only),
`<plugin>/skills/<name>/` (wherever the plugin is enabled), or an enterprise
managed-settings path; on a name clash enterprise beats personal beats
project, and any of them overrides a bundled skill of the same name.

Four of these carry most of the leverage:

- **Progressive disclosure through the filesystem.** You don't paste every
  detail into `SKILL.md`; you *tell Claude what files exist* and it reads
  them at the appropriate time. A `references/` file of edge cases costs no
  context until the moment it's relevant.
- **Scripts turn tokens into composition.** Handing Claude libraries and
  helper scripts lets it spend its turns deciding *what to do next* instead
  of reconstructing boilerplate — the same "use scripts for deterministic
  steps" discipline that applies inside any procedure.
- **State via `${CLAUDE_PLUGIN_DATA}`.** This env var resolves to a stable
  directory the skill owns, for an append-only log, a JSON blob, or a SQLite
  file. A `standup-post` skill keeps a `standups.log` so each run reads its
  own history and reports the delta rather than starting cold.
- **On-demand hooks for opinionated, scoped behavior.** A hook bundled in the
  skill fires only when the skill is invoked — e.g. a `/careful` skill whose
  `PreToolUse` matcher blocks destructive commands. You want that *only* when
  you know you're touching prod; always-on it "would drive you insane."

## The nine categories in depth

The at-a-glance table names them; a few carry lessons worth spelling out.

- **Library / API reference** (`billing-lib`, `internal-platform-cli`,
  `sandbox-proxy`) — the correct-usage-plus-gotchas skill. Its value lives in
  the Gotchas section: the append-only-table trap, the rate-limit quirk, the
  "this parameter looks optional but isn't." This is the category where
  "don't restate the obvious" bites hardest — document only what Claude can't
  read off the code.
- **Product verification** (`signup-flow-driver`, `checkout-verifier`,
  `tmux-cli-driver`) — skills that *drive the running product* to confirm a
  change works. Called out as having **the most measurable impact on output
  quality** internally: giving Claude a repeatable way to see its own work
  run is worth more than most instructions.
- **Data fetching & analysis** (`funnel-query`, `cohort-compare`, `grafana`,
  `datadog`) — the query patterns and workflows for a monitoring/analytics
  stack, so Claude asks the data the right way.
- **Business process / team automation** (`standup-post`,
  `create-<ticket-system>-ticket`, `weekly-recap`) — repetitive team
  workflows compressed to one command; the natural home for
  `${CLAUDE_PLUGIN_DATA}` state (a standup log, a recap history).
- **Code scaffolding & templates** (`new-<framework>-workflow`,
  `new-migration`, `create-app`) — turn a described requirement into
  framework boilerplate.
- **Code quality & review** (`adversarial-review`, `code-style`,
  `testing-practices`) — enforce standards and run review passes.
- **CI/CD & deployment** (`babysit-pr`, `deploy-<service>`,
  `cherry-pick-prod`) — own the fetch/push/deploy path.
- **Runbooks** (`<service>-debugging`, `oncall-runner`, `log-correlator`) —
  map a symptom to the right investigation tools and emit a structured
  report.
- **Infrastructure operations** (`<resource>-orphans`,
  `dependency-management`, `cost-investigation`) — routine maintenance behind
  guardrails (a strong pairing with on-demand hooks).

## Authoring — best practices and anti-patterns

The authoring rules split into what to *do* and what to *avoid*. The
do-column is in *Best practices* above; the three anti-patterns are the ones
worth naming outright, because each is a failure mode that *looks* like good
skill-writing:

| Anti-pattern | Why it fails | The fix |
|--------------|--------------|---------|
| **Restating the obvious** | Claude already codes and reads the repo; describing the default path adds context with no value | Write only what *pushes Claude out of its normal thinking* — gotchas, non-obvious constraints |
| **Railroading** | Over-specific step-by-step instructions make a reusable skill brittle across contexts | Give information + latitude, not a rigid script |
| **Mixing concerns** | A skill spanning several categories confuses the model's routing and its execution | One skill, one category; split the rest out |

Two positive rules do the most work. First, the **`description` is a routing
decision, not a summary** — the model reads every skill's description to pick
one, so it must say *when to trigger*, keywords and all. Second, **the
Gotchas section is the highest-signal content in any skill** — the concrete,
actionable warnings are exactly what Claude can't infer, so they earn their
context many times over.

## Distribution and measurement

### Distributing skills

Two paths, by team size:

- **Check into the repo** under `.claude/skills/` (or `~/.claude/skills/` for
  a personal skill that follows you across projects) — see the [skills
  reference][docs-skills]. Simplest; the skill travels with the code and works
  well for a small team.
- **Publish to a plugin marketplace.** A skill ships inside a plugin as a
  `skills/<name>/SKILL.md` folder alongside a `.claude-plugin/plugin.json`
  manifest (the [plugins guide][docs-plugins]); a `marketplace.json` then
  catalogs the plugins, users add the catalog with `/plugin marketplace add`,
  and install individual plugins with `/plugin install` (the [marketplace
  guide][docs-marketplace]). Plugin skills are namespaced
  `plugin-name:skill-name`, so they never clash with local skills. An internal
  marketplace lets each user install the plugins (and thus skills) they want
  and *skip the rest* — directly countering the context bloat that a
  check-everything-in monorepo of skills would cause. Anthropic's own flow is
  organic: an author drops a skill in a sandbox folder, shares it via
  Slack/forums to see if it gets traction, and only then PRs it into the
  marketplace proper.

Skills **compose by name** — a skill can reference another, and the model
will invoke it *if it is installed*. There is no native dependency manager
yet; naming is the mechanism.

### Measuring skill usage

You can't improve what you can't see. Because an invoked skill surfaces as an
ordinary tool call, a **`PreToolUse` hook** — which [fires before every tool
call][docs-hooks] and can simply inspect it and exit 0 — logs each invocation
without blocking it, surfacing which skills are popular, which are underused,
and whether a skill fires as often as expected. That usage signal
is what tells you a skill is worth keeping, needs a better description, or
should be retired.

## Bringing it together — how this repo's skills compare

This repo already runs on skills, so map Anthropic's guidance onto its
conventions rather than restating them (they live in
[EXTENDING.md][extending] *Skill*, guarded by
`tests/shell/test_skill_frontmatter.bats`):

- **Aligned — description written for the model.** Anthropic's "the
  description is a routing decision, not a summary" is exactly this repo's
  required `description` ("what it does *and* when to use it") plus the
  **skill-creator** description-trigger optimizer that tunes a skill to fire
  on the right requests. The frontmatter test enforces the field's presence;
  the guidance explains *why it must be model-facing*.
- **Aligned — one skill, one concern.** "The best skills fit cleanly into one
  category" is the same instinct as this repo's rule/skill/agent layering in
  EXTENDING.md — a skill is one procedure, not a grab bag.
- **Aligned — check-in vs marketplace.** The repo's global skills deploy to
  `~/.claude/`; repo-local ones live under `.claude/skills`. That mirrors the
  "check into the repo for small teams" path, with plugins as the packaging
  layer EXTENDING.md already names.
- **Diverges — leaner by intent.** The post leans on optional machinery —
  `config.json`, bundled on-demand hooks, `${CLAUDE_PLUGIN_DATA}` state — that
  these internal skills deliberately **skip by default** (optional standard
  fields like `license`/`allowed-tools` are added only when they earn their
  place). Reach for that machinery here only when a specific skill genuinely
  needs it, not as a default.

The takeaway for authoring a skill in *this* repo: follow EXTENDING.md and
`skill-creator` for the mechanics and frontmatter, and borrow the post's
judgment calls — Gotchas-first, model-facing description, no railroading, one
category — for the *content*.

## See also — adjacent, out of scope

Skills are one primitive on Claude's steering surface; the neighbors this doc
does not cover:

- **The steering surface as a whole** — the umbrella over skills, rules,
  memory, hooks, and the rest, and when to reach for each. See
  [STEERING.md][steering].
- **Subagents** — *delegated workers* that run a task in their own isolated
  context and report back, versus a skill's procedure that runs inline in the
  current context. A skill can invoke a subagent, but they are different
  animals. See [SUBAGENTS.md][subagents].

## Resources

Distilled from the "How we use skills" blog post and this repo's own skill
conventions:

- [Lessons from building Claude Code: how we use skills][blog] — the source
  blog post
- [skills][docs-skills] — the official skills reference
- [Agent Skills open standard][agentskills] — the cross-vendor `SKILL.md`
  format
- [plugins][docs-plugins] — how skills ship inside a plugin (the `skills/`
  directory + `.claude-plugin/plugin.json` manifest)
- [plugin marketplaces][docs-marketplace] — installing/publishing skills as
  plugins
- [hooks][docs-hooks] — the `PreToolUse` hook mechanism (on-demand
  guardrails, usage logging)
- [EXTENDING.md][extending] — this repo's extension-primitive reference (Skill
  section)
- [STEERING.md][steering] — the steering-surface umbrella
- [SUBAGENTS.md][subagents] — the delegated-worker family

[blog]: https://claude.com/blog/lessons-from-building-claude-code-how-we-use-skills
[docs-skills]: https://code.claude.com/docs/en/skills
[agentskills]: https://agentskills.io/specification
[docs-marketplace]: https://code.claude.com/docs/en/plugin-marketplaces
[docs-plugins]: https://code.claude.com/docs/en/plugins
[docs-hooks]: https://code.claude.com/docs/en/hooks
[extending]: ../EXTENDING.md
[steering]: STEERING.md
[subagents]: SUBAGENTS.md
