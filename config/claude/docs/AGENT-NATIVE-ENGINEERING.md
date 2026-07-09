# Agent-Native Engineering

**Agent-native engineering** is the practice of building deliberately *for*
an AI coding agent rather than merely pointing one at an existing setup and
hoping. It treats the agent's tools, its context, and the workflow around it
as *intentional infrastructure you design and maintain* — not as unmaintained
magic that either works or doesn't. This document synthesizes three altitudes
of that practice into one model: you build for the agent at the level of the
**tools it sees**, the **context you onboard it with**, and the **workflow
you run around it**. Each altitude has a governing lesson and — crucially —
concrete evidence in this repo, so the advice reads as best-practice *with a
worked example*, not abstraction.

## ELI5

Plain-language one-liners that double as a quick summary. Details are in the
sections below; every source link is at the bottom.

*Shape what the agent can see and do (its tools):*

- **watch it, don't guess** — decide what tools it needs by reading what it
  actually does, not by imagining what would help.
- **retire tools that aged out** — a crutch the old model needed can trip the
  new one; a smarter model wants fewer, more general tools.
- **hide detail until asked** — a searchable pile of context beats twenty
  bespoke buttons cluttering every turn.

*Give it the knowledge to start (its context):*

- **write it down, and version it** — the agent forgets between sessions;
  `CLAUDE.md` and friends are its onboarding binder, maintained like code.
- **package your expertise as skills** — a "how we debug here" note that
  loads itself the moment a bug appears.
- **plug it into the real data** — let it read the actual test results and
  logs, not a description of them.
- **grow its remit as it earns it** — start on a contained task, widen the
  blast radius once it shows it understands.

*Change how the team works around it (its workflow):*

- **the new hard part is checking, not typing** — cheap code makes review
  and verification the bottleneck; build the gate.
- **plan just in time** — a prototype with real users beats a year-long
  roadmap that's stale in a month.
- **spend human judgment where it's scarce** — security, trust boundaries,
  product sense; let the machine own style and tests.
- **kill dead process** — dogfood relentlessly, stay flat, delete the
  workflow that no longer earns its keep.

### Best practices

- **See like the agent, not like yourself.** Design a tool from how the model
  perceives and calls it — "even the best-designed tool doesn't work if Claude
  doesn't understand how to call it."
- **Revisit tool decisions every model bump.** What *enabled* the model last
  quarter can *constrain* it this quarter; a tool is a hypothesis, not a
  monument.
- **Prefer progressive disclosure to more tools.** Nested, searchable context
  and a documentation subagent keep the main context clean; treat a growing
  tool count as a smell.
- **Version the context layer separately from the code.** It grows at a
  different rate and applies across every branch and point in time.
- **Give critical skills explicit triggers.** "ALWAYS load when investigating
  bugs" beats hoping the agent remembers to consult it.
- **Bridge to real data, but keep it second-class.** MCP connects the agent to
  live systems; never let a rule or skill *depend* on one being up.
- **Onboard, don't dump.** "You wouldn't hand a new hire a 700,000-line
  codebase and expect results on day one" — start small, expand on evidence.
- **Build the verification gate first.** Once codegen is cheap, an ungated
  change is a liability; make "is it correct/safe" the enforced step.
- **Recalibrate trust continuously.** The right trust-vs-verify balance keeps
  moving as models improve — re-tune it, don't set it once.
- **Delete process that stopped serving you.** Find the noisiest workflow and
  ask whether it still earns its place or can be automated away.

## Overview

The three source posts sit at three different altitudes, but they are one
idea: **an agent's effectiveness is bounded by what you build around it**, and
you build at three levels that stack. Lowest is the **tool surface** — what
the model can perceive and invoke each turn. On top of that sits the
**context layer** — what the model knows before it takes its first action.
Around both runs the **workflow** — the human process that plans, reviews, and
ships what the agent produces. Neglect any layer and the ones above it inherit
the weakness: perfect tools with no onboarding context flail; a well-onboarded
agent with no verification gate ships fast and wrong.

**The organizing sentence:** you are not *using* an agent, you are
*engineering an environment* for one — and that environment has three
altitudes, each of which you design, version, and revisit as the model
underneath it changes.

### At a glance — the three altitudes

Each altitude shapes a different thing, carries a governing lesson from one
source post, and — the point of this doc — has concrete evidence already in
this repo.

| Altitude | You shape… | Governing lesson | This repo's evidence | The shift it forces |
|----------|-----------|------------------|----------------------|---------------------|
| **Tools** | what the agent perceives and can call each turn | *see like an agent; revisit as the model improves* | the `EXTENDING.md` primitive taxonomy, the ~20-tool ceiling, `ToolSearch` deferral, subagents | design from the model's view, not yours; retire aged-out tools |
| **Context** | what it knows before its first action | *onboard it like a new developer* | `CLAUDE.md` / `WORKFLOW.md` / `CONVENTIONS.md`, triggered skills in `skills/`, the `mymcp` MCP bridge | version the context layer; encode expertise as self-loading skills |
| **Workflow** | the human process around its output | *verification is the new bottleneck* | `qa.md` + the `qa-check` skill, required CI checks, `push-pr`'s CI-watch, `plan-review`, `resolve-task` | move the scarce human effort from typing to checking |

In table order: the **Tools** altitude is the model's sensory surface — you
size and shape it from observation, and you *revisit* it, because a tool that
helped a weaker model can hinder a stronger one. The **Context** altitude is
the agent's onboarding binder — deliberately written, versioned, and expanded
as competence shows, the way you'd bring on a new hire. The **Workflow**
altitude is the org around the agent — once the agent makes code cheap, the
binding constraint moves to verification, so the process reshapes to put human
judgment where it is now scarce. The three sections below take each in turn.

## Design tools the way the agent sees them

*Governing lesson (from [Seeing like an agent][seeing-like-an-agent]): the
tool surface is the model's sensory world, so design it from the model's
perspective — empirically, and re-examined every time the model improves.*
"You pay attention, read its outputs, experiment. You learn to see like an
agent."

### Observe, don't assume

The first move is not to design tools — it is to *watch the agent use the ones
it has*. Which calls does it fumble? Where does it re-read the same thing?
What does it wish it could see? Tool design that starts from the developer's
mental model ("obviously it needs an X tool") tends to miss, because the model
does not experience the codebase the way its author does. The discipline is
empirical: read the transcripts, run experiments, and let the *actual* failure
modes — not imagined ones — drive what you build. The load-bearing constraint
underneath all of it: "even the best-designed tool doesn't work if Claude
doesn't understand how to call it." A tool the model cannot reliably invoke is
worse than no tool, because it fails *silently and confidently*.

### Revisit tools as the model improves

A tool is a hypothesis about what the model needs *right now* — and the model
does not stand still. The post's canonical example is `TodoWrite`: an
early-generation todo-list tool that kept the model honest when it could not
hold a multi-step plan in its head. As the model got better, that same tool
became a *constraint* — its reminders pinned the model to a rigid list instead
of letting it adapt strategy mid-task. The fix was not to tweak it but to
*replace* it with a Task tool built around subagent coordination — a design
that only became possible once the model was strong enough to manage the
complexity itself. The rule of thumb: **what once enabled the model may now
constrain it**, so audit the tool set on every model bump rather than treating
it as settled.

This repo lives that idea in its extension taxonomy.
[`EXTENDING.md`][extending] does not enumerate a frozen tool set; it lays out
the *kinds* of extension — memory, rule, skill, subagent, hook, command, MCP
server, plugin — and, for each, *when to reach for it and when it has stopped
fitting*. That "choose the right primitive, re-choose as things change"
framing is exactly the revisit-don't-monument discipline applied to our own
config, and the periodic `claude-audit` is its forcing function.

### Progressive disclosure over tool proliferation

The tempting answer to "the agent needs to do more" is "add more tools." The
post argues the opposite: past roughly **twenty tools** the surface itself
becomes noise the model has to wade through every turn, and the better lever
is **progressive disclosure** — keep the common surface small and let the
model *reach for* detail only when it needs it. Their example is the Claude
Code Guide: instead of stuffing the documentation into the system prompt
(paid for on every turn, whether relevant or not), they put it behind a
*documentation subagent* the main agent queries on demand — detail available,
context clean.

This repo's tool surface is built the same way, on two mechanisms:

- **`ToolSearch` deferral.** Most tools are not loaded up front; their schemas
  are fetched on demand by keyword. The idle cost of a rarely-used tool is a
  name in a reminder, not a full schema in every prompt — progressive
  disclosure as a harness primitive.
- **Subagents for isolation.** Broad searches and self-contained reviews are
  delegated to a [subagent][cc-subagents] that reads widely in *its* context
  and returns only the conclusion — the documentation-subagent pattern
  generalized. Officially a subagent "runs in its own context window with a
  custom system prompt, specific tool access, and independent permissions,"
  handing back just its result; the [`EXTENDING.md`][extending] guidance to
  reach for an agent "to keep heavy intermediate work out of the main thread"
  is the same clean-context move. A subagent is a Markdown file in
  `.claude/agents/` (project) or `~/.claude/agents/` (user) whose YAML
  `description` frontmatter tells the main agent when to delegate.

The through-line: **more capability should usually mean deeper disclosure, not
a wider always-on surface.** A rising tool count is a design smell to
investigate, not a milestone to celebrate.

## Onboard the agent like a new developer

*Governing lesson (from [Onboarding Claude Code like a new developer]
[onboarding-claude]): an agent facing your codebase is a new hire facing your
codebase — "you wouldn't hand a new hire a 700,000-line codebase and expect
results on day one." Introduce it incrementally, through deliberately
maintained context.*

### Build a deliberate, versioned context layer

Context does not persist across sessions — [each Claude Code session begins
with a fresh context window][cc-memory], and `CLAUDE.md` files are the
mechanism that carries knowledge across that gap: Claude loads them *in full*
at the start of every session, discovering them by walking up the directory
tree from the working directory. So the layer has to be *authored and
maintained on purpose*. The post's sharpest structural insight is that this
context layer deserves its own versioning discipline — the author keeps AI
context in a dedicated repo that versions *independently* of the code,
"because it grows at a different speed than the code and applies to all
branches and time points." The context layer is a first-class artifact, not a
scratch file.

This repo *is* that principle instantiated. The onboarding binder is a
layered, individually-versioned set of documents:

- [`CLAUDE.md`][extending] — the always-loaded foundation: who the user is,
  hard conventions, the normative behavior every turn inherits.
- `WORKFLOW.md` — the repo's operational procedure, explicitly declared to
  *override* the global `CLAUDE.md` where they differ.
- `CONVENTIONS.md` — the repo's coding standards, layered under `WORKFLOW.md`.

Each file carries its own `**Version:**` header and an explicit precedence
chain (`WORKFLOW.md` > `CONVENTIONS.md` > global) — the "grows at a different
speed, applies across branches" property made concrete. The stack is wired
with the official mechanism, too: the project `.claude/CLAUDE.md` pulls the
others in with [`@path` imports][cc-memory] (`@WORKFLOW.md`, `@CONVENTIONS.md`,
`@TESTS.md`), which Claude expands and loads at launch, and it rides on the
built-in scope order — user (`~/.claude/CLAUDE.md`), then project, then a
gitignored local `CLAUDE.local.md` — so the repo binder layers cleanly over
the personal one. The context layer here is not one dumped file; it is a
maintained, versioned, precedence-ordered stack, exactly the shape the post
prescribes.

### Encode domain expertise as triggered skills

Beyond static context, the post encodes *expertise* — how this team debugs,
how it does version control, how it orients a newcomer — as
[**skills**][cc-skills]: a `SKILL.md` file whose YAML `description`
frontmatter tells Claude when to pull it in, so it — critically — **loads
itself on the right trigger** instead of sitting in context every turn. That
is the mechanism's whole economy: a skill's body "loads only when it's used,
so long reference material costs almost nothing until you need it." The post's
debugging skill declares "ALWAYS load when investigating bugs, failures, or
unexpected behavior" and "forces root cause analysis over 'guess and test'."
The expertise is not something the agent has to *remember* to consult; the
trigger pulls it in the moment it becomes relevant.

This repo's [`skills/`][extending] directory is that library, and
`debug-assistant` is the near-exact analog of the post's debugging skill. Its
frontmatter carries the trigger phrasing verbatim in spirit — it fires on
"why is this failing", "track down this bug", "find the root cause" — and its
procedure enforces the same discipline: reproduce first, capture real
evidence, isolate by bisection, fix the *root cause*, and lock it with a
regression test. The skill *is* the "how we debug here" expertise, packaged so
it self-loads on the failure it addresses. The `description`-as-trigger
contract is a house standard, guarded by a frontmatter test in the suite — the
trigger is not decoration, it is load-bearing.

### Bridge to real data via MCP

A well-onboarded developer still needs access to the *live* systems — the
test dashboard, the exception reports, the support threads. The post bridges
the agent to those through [**MCP servers**][cc-mcp] — the Model Context
Protocol, an open standard for AI-tool integrations — that pull real data
(daily summaries from a LabKey server, GitHub, email) so the agent reasons
over actual results, not a stale description of them. The official guidance
names the exact trigger: connect a server "when you find yourself copying data
into chat from another tool."

This repo's bridge is [`bin/mymcp`][extending] — a single launcher for local
MCP servers (the **stdio** transport, each a local process), every one reading
its own narrowly-scoped credential directly from the private key store rather
than the shared shell environment. The design matches
the post's intent (connect the agent to real systems) while honoring this
repo's standing rule that **MCP is second-class**: a convenience the agent can
use, never a dependency a rule or skill is allowed to *require*. The bridge is
there for live data; the config never assumes it is up.

### Expand scope gradually

The final onboarding move is *graduated trust*: start the agent on a
contained, demonstrable win, and widen its remit only as it shows it
understands — "expand scope gradually … across branches and broader codebase
sections." Competence earns scope; scope is not granted up front.

This repo's [`resolve-task`][extending] skill embeds that graduation. It does
not fling the agent at arbitrary work — it takes *one* chosen item, and its
first move is *reconcile against current code* (skip if already done, route
WONTFIX/ICEBOX), then classify, branch, investigate, change, and land via a
gated PR. The scope is deliberately one well-specified unit at a time, with
the riskier autonomy (skipping the human ask gate) behind an explicit,
default-off opt-in sentinel. That is graduated trust as config: the default is
narrow-and-checked, and wider autonomy is a decision you make on purpose, not
the starting posture.

## Restructure the workflow around the agent

*Governing lesson (from [Running an AI-native engineering org]
[ai-native-org]): once the agent makes code generation cheap, the bottleneck
moves — "verification, code review, and security took their place." The
workflow must reshape around the new scarce resource: human judgment.*

### Verification is the new bottleneck

When typing code stops being the constraint, *ensuring it is correct and
maintainable* becomes the binding one. An AI-native workflow therefore invests
its engineering where it now matters most: the gate that proves a change is
sound. This repo's entire QA apparatus is that investment, in layers:

- [`qa.md`][qa-rule] defines the pipeline as *dimensions and ordering* —
  format, lint, type-check, complexity, security, tests, build, docs, review,
  CI — cheap-and-fast stages first, fail fast. It is deliberately
  tool-agnostic; the concrete commands live in the repo's own QA doc.
- The **`qa-check`** skill is the forcing function that actually runs those
  dimensions against the repo's declared commands.
- **Required CI status checks** (`bats`, `meta`, `perl`, `pre-commit`) gate
  merges server-side — the verification is *enforced*, not advisory, so an
  ungated change physically cannot land.
- **`push-pr` watches CI to green** after pushing and only then proceeds —
  the loop closes on *verified*, not merely *submitted*.

The shape is the post's thesis made mechanical: codegen is cheap, so the
process spends its rigor on the check. And the post's corollary — "the right
balance of trust vs. verify will keep changing as the models improve" — is why
that gate is versioned and audited rather than frozen: it gets *recalibrated*,
not set once.

### Just-in-time planning over long roadmaps

The post found traditional roadmaps went stale almost immediately and switched
to **just-in-time (JIT) planning**: "prototype, get a lot of internal users on
it, and start acting on their feedback" — deliver the right scope at the right
moment rather than specify everything up front. Planning shrinks to the
horizon you can actually see, and evidence from real use replaces speculation.

This repo's counterpart is the [`plan-review`][extending] skill — the
pre-implementation gate that reviews a *plan* before it is built, surfacing
unverified assumptions, missing failure modes, and simpler alternatives. It is
JIT planning's quality control: rather than a heavyweight design doc defended
for months, you form the *nearest* plan, poke holes in it, build, and learn
from real use. Plan the next step well; do not over-specify a future that will
have moved by the time you reach it.

### Refocus human review on security and product sense

If the machine reliably handles style, linting, and test generation, then
spending human review on those is waste. The post moves human attention to
where domain expertise is irreplaceable: "legal review, trust boundaries and
security-sensitive code," and product judgment — is this the *right* thing to
build, and is it *safe*. Team composition shifts to match: hire "creative
builders with product sense" and deep-systems engineers; roles blur as raw
coding velocity stops being the differentiator.

This repo encodes the same division of labor. Mechanical style is delegated to
the machine — formatters and linters in the pipeline, a whole `code-style.md`
audit the `qa-check` skill runs — while the human-owned reviews are the ones
that need judgment: the `/security-review` and `/code-review` commands, the
`arch-review` and `test-review` skills for whole-codebase health, and the
standing insistence that a human owns the merge decision. Let the agent own
the mechanical slice; reserve the person for security and product sense.

### The non-negotiables

The post anchors the whole reorganization on three immovable principles, which
translate directly:

- **Dogfood relentlessly.** This entire config *is* dogfooding — the agent's
  own rules, skills, and workflow are built, used, and refined by using them,
  with a `retrospective` skill that evaluates tooling friction as the last
  step before merging.
- **Stay flat.** Keep the process and the hierarchy minimal; the extension
  taxonomy exists precisely so a capability lives at the *lightest* layer that
  works (a rule, not a skill; a skill, not a subagent) — no ceremony a simpler
  primitive would carry.
- **Delete process that stopped working.** "Don't hesitate to kill processes
  that no longer work" — the same instinct as the Tools altitude's *retire
  aged-out tools*, applied to the workflow. The starting move the post
  recommends — find your **noisiest workflow** and ask whether it still serves
  its purpose — is the audit posture this whole config is built around.

## Bringing it together

The three altitudes are not independent checklists — they **compose down a
single change**, each layer resting on the one below. Trace one change through
them:

1. **Tools** decide what the agent can even perceive of the change — a clean,
   progressively-disclosed surface (a subagent for the broad search, deferred
   tool schemas) means it reads the *relevant* slice of the repo without
   drowning in an always-on tool wall.
2. **Context** decides whether it acts *correctly* — `CLAUDE.md`'s
   conventions, `WORKFLOW.md`'s procedure, and the self-loading
   `debug-assistant` skill mean it fixes the root cause the house way, from
   real data via `mymcp`, rather than guessing.
3. **Workflow** decides whether the result *ships* — `plan-review` vets the
   approach, `resolve-task` scopes it to one gated unit, `qa-check` and the
   required CI checks verify it, and `push-pr` watches it green before a human
   owns the merge on the judgment that still needs a person.

Weakness at any altitude leaks upward: an aged-out tool starves the context
layer of the right inputs; a stale `CLAUDE.md` makes a perfect verification
gate reject good work for the wrong reasons; a missing gate ships a
well-onboarded agent's confident mistake at speed. The payoff of treating all
three as *maintained infrastructure* — versioned, revisited on every model
bump, audited when it goes noisy — is an environment where the agent's cheap
code is matched by cheap *confidence* in it. That is the whole game: not a
smarter prompt, but a better-engineered place for a smart agent to work.

## See also — adjacent, out of scope

This doc is about engineering the *environment* around an agent. Two adjacent
references go deeper on pieces it only gestures at:

- **Steering an agent's behavior in the moment** — the tactical layer of
  directing a single session (prompting, corrections, mid-task steering), as
  opposed to this doc's standing-infrastructure altitude. See
  [STEERING.md][steering].
- **Loops & workflows** — running work *over time* and *across many agents*
  (the `/loop`, `/goal`, workflow, and subagent-fan-out family). This doc
  shapes the environment; that one drives many passes through it. See
  [LOOPS-WORKFLOWS.md][loops].
- **The extension primitives themselves** — the full build-vs-adopt,
  keep-lean reference for *which* kind of artifact (rule / skill / agent /
  hook / MCP / plugin) to reach for. See [EXTENDING.md][extending].

## Resources

Distilled from three Claude blog posts and this repo's own config docs:

- [Seeing like an agent][seeing-like-an-agent] — designing the tool surface
  from the model's perspective; revisit as the model improves; progressive
  disclosure over tool proliferation.
- [Onboarding Claude Code like a new developer][onboarding-claude] — the
  versioned context layer, expertise as triggered skills, MCP data bridges,
  and graduated scope.
- [Running an AI-native engineering org][ai-native-org] — verification as the
  new bottleneck, just-in-time planning, refocused human review, and the
  dogfood / stay-flat / delete-dead-process non-negotiables.
- [EXTENDING.md][extending] — this repo's extension-primitive taxonomy and
  keep-lean placement philosophy.
- [qa.md][qa-rule] — the language-agnostic QA pipeline the verification
  altitude is built on.
- **Official Claude Code docs** for the mechanisms named above —
  [memory / `CLAUDE.md`][cc-memory] (the versioned context layer),
  [skills][cc-skills] (self-loading expertise), [MCP][cc-mcp] (the live-data
  bridge), and [subagents][cc-subagents] (delegated, isolated context).
- [LOOPS-WORKFLOWS.md][loops] · [STEERING.md][steering] — the adjacent
  over-time / in-the-moment references.

[seeing-like-an-agent]: https://claude.com/blog/seeing-like-an-agent
[onboarding-claude]: https://claude.com/blog/onboarding-claude-code-like-a-new-developer-lessons-from-17-years-of-development
[ai-native-org]: https://claude.com/blog/running-an-ai-native-engineering-org
[extending]: ../EXTENDING.md
[qa-rule]: ../rules/qa.md
[loops]: LOOPS-WORKFLOWS.md
[steering]: STEERING.md
[cc-memory]: https://code.claude.com/docs/en/memory
[cc-skills]: https://code.claude.com/docs/en/skills
[cc-mcp]: https://code.claude.com/docs/en/mcp
[cc-subagents]: https://code.claude.com/docs/en/sub-agents
