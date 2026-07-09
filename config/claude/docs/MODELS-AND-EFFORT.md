# Claude Models & Effort Levels

Claude Code exposes two independent knobs for any task: which **model**
runs it, and how much **effort** that model spends. They are *orthogonal* —
the model dial is roughly *how capable* (which brain you hand the job to),
the effort dial is roughly *how thorough* (how hard that brain works before
it answers). Turning one does not substitute for the other, and most real
work needs a deliberate setting of both. This document is a plain-language
reference for the two dials: the model tier ladder from fast-and-cheap to
frontier, what effort actually controls and why it is "all just tokens from
one loop," and the single heuristic for picking each — difficulty chooses
the model, thoroughness chooses the effort.

## ELI5

Plain-language one-liners that double as a quick summary. Details are in the
sections below; every source link is at the bottom.

*Pick a brain (the **model** — how capable):*

- **Haiku** — the quick, cheap one; hand it trivial, mechanical, high-volume
  work.
- **Sonnet** — a strong generalist; the default for routine edits you can
  describe precisely.
- **Opus** — the expert; reach for it on genuinely hard problems.
- **Fable** — the rare specialist; long, open-ended, multi-step jobs the
  others can't finish at any effort.
- **Mythos** — the frontier tier above Fable (named in the ladder, not yet
  detailed).

*Set the thoroughness (the **effort** — how hard it works):*

- **lower effort** — do the obvious thing fast; would rather ask you for
  more context than spend tokens digging.
- **higher effort** — read more files, verify, run tests, plan deeper, and
  push through a multi-step task, spending more tokens to build confidence.

*Decide which knob to turn when it gets something wrong:*

- it didn't **know** enough (had all the context, clearly tried, still wrong)
  → move up a **model**.
- it didn't **try** enough (skipped a file, didn't run the tests, didn't
  double-check) → raise the **effort**.

Choosing model + effort *per helper agent*, and the cache cost of switching
models mid-conversation, are their own topics — see [SUBAGENTS.md][subagents]
and [PROMPT-CACHING.md][caching].

### Best practices

- **Set both dials on purpose** — capability and thoroughness are separate
  needs; a hard task done carelessly and an easy task overthought both waste
  something.
- **Pick the model by task difficulty** — routine, describable, in-context
  work takes a small model; subtle bugs, unfamiliar domains, and
  architecture decisions take a large one.
- **Pick the effort by how much verification the task deserves** — low when
  the change is obvious, high when it must read widely and check itself.
- **Drop to a smaller model for routine stretches** — it saves real money at
  no quality cost; reserve the big models for the genuinely hard parts.
- **When it fails, diagnose *try* vs *know* before re-running** — raising the
  wrong dial burns tokens without fixing the cause.
- **Give a capable model a scoped problem** — the bigger the model, the more
  the bottleneck shifts to how well *you* surfaced the unknowns; define the
  scope up front, or commit to iterating on discovery.

## Overview

The two settings answer two different questions. **Model** answers *which
brain* — capability, scaled by how hard the problem is. **Effort** answers
*how hard that brain works* — thoroughness, scaled by how much reading,
verifying, and multi-step persistence the task deserves. In the blog's own
framing: *"the model setting is roughly how capable; the effort setting is
roughly how thorough. Most real tasks need some of both."*

Because they are orthogonal, every combination is meaningful. *Opus at low
effort* is five minutes with an expert — deep knowledge, but rushed. *Sonnet
at high effort* is a generalist given all afternoon — no special expertise,
but a thorough understanding of your actual code. Neither dial can stand in
for the other: a small model at maximum effort still lacks the knowledge a
hard problem needs, and a large model at minimum effort still skips the files
a careful one would read.

**The distinction to remember:** *difficulty* is a property of the problem
and sets the **model**; *thoroughness* is a property of how the work is done
and sets the **effort**. The three sections below take the model ladder, the
effort dial, and the selection heuristic in turn.

### At a glance — the model ladder

The tiers run from fastest-and-cheapest to most-capable-and-costly. The axis
that varies is raw capability — what class of problem the tier can reach —
and, with it, speed and cost move the other way.

| Tier | Strength | Reach for it when |
|------|----------|-------------------|
| **Haiku** | fast, cheap, lightweight | the work is trivial and mechanical, or high-volume where speed and cost dominate |
| **Sonnet** | "a really good generalist" | edits you can describe precisely, mechanical changes, or questions about code already in context |
| **Opus** | "the expert" with deep experience | genuinely hard problems — subtle bugs, unfamiliar domains, architecture decisions |
| **Fable** | "a specialist who's seen problems almost no one else has" | long, multi-step work; jobs Opus and Sonnet can't reach at any effort |
| **Mythos** | the frontier tier above Fable | named in the ladder but not yet detailed — the top of the reach |

In table order: **Haiku** is the speed tier for work with no real judgment in
it; **Sonnet** is the generalist default that handles most routine coding;
**Opus** is the expert you escalate a genuinely hard problem to; **Fable** is
the specialist for long, open-ended work the others stall on; and **Mythos**
sits above Fable as the frontier the ladder names but the blog does not yet
elaborate. Capability climbs down the rows; speed and cost climb back up.

## The model ladder — how capable

**The model is the difficulty dial.** Match the tier to how hard the problem
is: a small model does routine work at a fraction of the cost, and a large
model earns its price only on problems that genuinely need it. Each tier
below is one rung.

**Selecting a model.** Claude Code takes a model as either a *family alias* —
`haiku`, `sonnet`, `opus`, `fable`, or the meta-aliases `default`, `best`,
and `opusplan` — or a full model name, and gives four ways to set it, in
priority order: `/model <alias|name>` switches mid-session (with no argument
it opens a picker); `claude --model <alias|name>` sets it at launch; the
`ANTHROPIC_MODEL` environment variable sets it per shell; and the `model`
field in a settings file sets it persistently. The [model-configuration
reference][model-config] documents all four. Aliases track the latest version
of each family and move over time, so pin a full model name (for example
`claude-opus-4-8`) or set a per-family override such as
`ANTHROPIC_DEFAULT_OPUS_MODEL` when you need a fixed version.

### Haiku — the speed tier

The fastest and cheapest option, for work with little or no judgment in it:
trivial mechanical edits, or high-volume batches where throughput and cost
matter more than depth. The blog names Haiku in the ladder but does not
elaborate it — treat it as the floor you drop to when a task is clearly
below Sonnet's pay grade.

### Sonnet — the generalist default

*"A really good generalist."* Sonnet is the everyday workhorse: it handles
*"edits you can describe precisely, mechanical changes, or questions about
code that's already in context."* When the task is well-specified and the
relevant code is in front of it, Sonnet does not need a bigger brain — and
choosing one wastes money for no quality gain.

### Opus — the expert

*"The expert,"* with *"deep experience."* Reach for Opus on problems that are
genuinely hard rather than merely tedious: *"subtle bugs, unfamiliar domains,
or architecture decisions."* Opus knows things a generalist does not; that
knowledge is what you are paying for, so spend it where knowledge — not just
thoroughness — is the bottleneck.

### Fable — the specialist, where scoping becomes the skill

*"A specialist who's seen problems almost no one else has."* Fable excels at
*long, multi-step work* and can complete *"jobs Opus and Sonnet can't reach
at any effort level"* — a capability step, not just an effort one. It is
never the default: a session reaches it only when you choose it, with
`/model fable` [(model configuration)][model-config].

Fable also changes *where the bottleneck sits*. With a model this capable,
the field guide's thesis is that *"the quality of the work is bottlenecked by
my ability to clarify its unknowns"* — and that *"reducing and planning for
your unknowns is the skill of agentic coding."* The model is rarely the limit
now; how thoroughly you surfaced what you *don't* know about the problem,
requirements, and constraints is. So Fable is at its best in two situations:

- **Scope is clearly defined** — you have surfaced the unknowns up front
  (planning, prototyping, reference examples) before implementation begins.
- **You will iterate on discovery** — you are ready to implement while
  documenting deviations, then refine the understanding afterward.

The inverse is the guidance for the rest of the ladder: when scope is narrow,
well-established, or straightforwardly mechanical, a smaller model suffices —
Fable's edge is complex, open-ended work where rigorous unknowns-mapping is
the differentiator.

### Mythos — the frontier

Named in the ladder above Fable as the top of the reach. The blog does not
yet detail it; treat it as the frontier tier and describe it by role — the
most capable rung — rather than by any fixed specification. Claude Code
exposes no dedicated `mythos` alias; reach the frontier through `fable`, the
`best` alias (which resolves to the most capable model your account can run),
or by naming a frontier model in full [(model configuration)][model-config].

## Effort — how thorough (and why it's all tokens)

**Effort is the thoroughness dial**, and it is independent of which model you
picked. In the blog's words, *"effort level controls how much work Claude
does on your request overall."* That is more than think-time; it includes:

- *how long the model thinks*,
- *how many files it reads*,
- *how much it verifies*,
- *how far it pushes through a multi-step task*.

### It's all tokens from one loop

The mental model that makes effort intuitive: *"All of Claude's output is
tokens. Thinking, tool calls, and text to you are all generated from the same
loop."* Reasoning, reading a file, running a test, and writing the reply are
not separate budgets — they are the *same* stream of generated tokens. So
"more effort" is literally "more tokens spent," and those extra tokens buy
**confidence**: deeper plans, more verification, and hypothesis-testing. A
harder task at high effort can generate on the order of *7x more tokens* than
the same task at low effort, all of it going toward reaching a
higher-confidence answer. It is also, literally, how you are billed: Claude
Code charges by API token consumption, and thinking tokens are billed as
output tokens (see [managing costs][costs]) — so the two dials are levers on
cost as much as on quality.

The two ends of the dial behave distinctly:

- **Lower effort** — Claude *"would rather ask you for more context than spend
  tokens figuring something out on its own."* Fast, cheap, and best when the
  next step is obvious.
- **Higher effort** — Claude plans more deeply, verifies more, and tests
  hypotheses before concluding. Slower and costlier, and best when the task
  must read widely and check its own work.

The blog frames effort as a *continuum* rather than a fixed set of named
steps — a low-to-high slider you turn up in proportion to how much
verification and persistence the task deserves. Claude Code exposes that
slider as named **effort levels** — `low`, `medium`, `high`, and `xhigh`,
plus a session-only `max` — which drive the model's *adaptive reasoning* (it
decides whether and how much to think on each step); `high` is the default on
current models. The [model-configuration reference][model-config] documents
the levels and their tradeoffs.

Set the level the same ways you set the model, plus frontmatter: `/effort`
(no argument opens a slider, or name a level to set it directly) and the
`--effort <level>` launch flag change it for the session; the
`CLAUDE_CODE_EFFORT_LEVEL` environment variable sets it and takes precedence
over the rest; the `effortLevel` setting persists it across sessions
(`low`/`medium`/`high`/`xhigh` only — `max` is session-only); and a skill's
or subagent's `effort` frontmatter overrides the session level while that
unit runs. For a one-off without changing the session level, put `ultrathink`
anywhere in the prompt.

Extended thinking itself is a separate toggle from effort — turn it on by
default in `/config` (saved as `alwaysThinkingEnabled`) or off with
`MAX_THINKING_TOKENS=0` — but on current adaptive-reasoning models the effort
level is the primary control, and thinking cannot be disabled on the top
tier. [Settings][settings] lists these keys.

## Choosing: difficulty picks the model, thoroughness picks the effort

The two dials share one diagnostic question, asked whenever Claude gets
something wrong: *"did it not try hard enough, or did it not know enough?"*
The answer routes you to exactly one dial.

- **It didn't *know* enough → move up a model.** The signal is precise: *"if
  Claude has all the pertinent context and clearly tried and still got it
  wrong, that's a signal to pick a larger model."* Context was present, effort
  was spent, the answer was still wrong — that is a *capability* gap, and only
  a bigger brain closes it.
- **It didn't *try* enough → raise the effort.** *"Pick a higher effort level
  if Claude got it wrong by skipping a file, not running the tests, or not
  double-checking its work."* The knowledge was reachable; it just wasn't
  reached — that is a *thoroughness* gap, and more tokens on the same model
  closes it.

Going the other direction is just as valuable: **drop to a smaller model for
routine stretches** to *"save real money at no quality cost,"* and lower the
effort when a task is obvious enough that extra verification only burns
tokens. Right-sizing *down* is as much the skill as escalating up.

## Bringing it together

The two dials *compose* — every model pairs with every effort level, and the
pairing is what you actually choose per task. This compact map turns the pair
into a task shape:

| | Lower effort | Higher effort |
|---|---|---|
| **Haiku** | trivial mechanical edits; high-volume batches | rarely worth it — raise the *model* instead of grinding a small one |
| **Sonnet** | routine, precisely-describable edits on code already in context | thorough work on familiar code — read and verify across many files (a generalist given all afternoon) |
| **Opus** | a quick expert read on a hard question you'll steer yourself (five minutes with an expert) | a hard problem worked end-to-end — a subtle bug, an architecture call, an unfamiliar domain |
| **Fable / Mythos** | seldom the right pairing — reach-tier models earn their cost on sustained work | long, multi-step, open-ended work where you've scoped the unknowns or will iterate on discovery |

Read it as two independent moves. First place the task on the **model**
column by difficulty: is this routine (Sonnet), genuinely hard (Opus), or a
long open-ended reach (Fable)? Then set the **effort** by thoroughness: is
the next step obvious (lower), or must it read widely and verify (higher)?
The diagonal is where most work lands — small model / low effort for the
routine, big model / high effort for the hard — but the *off-diagonal* cells
are the useful ones to remember: Opus-low for a fast expert opinion you'll
drive, and Sonnet-high for exhaustive work on code that needs diligence more
than genius.

Claude Code even ships this compose as a built-in: the `opusplan` alias runs
Opus while you plan and switches to Sonnet for execution, automating the
"reason hard, then implement efficiently" split of the two dials
[(model configuration)][model-config].

## See also — adjacent, out of scope

The two dials set *one* agent's capability and thoroughness. Two adjacent
topics extend that:

- **Per-subagent selection** — when you delegate to helper agents, each can
  run on its own model and effort, so the dials become a *per-agent* choice
  rather than a session-wide one. See [SUBAGENTS.md][subagents].
- **Prompt caching** — switching models mid-conversation **breaks the cache**
  (the cached prefix is model-specific), so the cost of changing the model
  dial is more than the new model's rate. See [PROMPT-CACHING.md][caching].

## Resources

Distilled from two Claude blog posts and the official Claude Code
documentation:

- [Model & effort level in Claude Code][blog-model] — the two dials, the tier
  ladder, effort as one token loop, and the try-vs-know heuristic
- [A field guide to Claude Fable][blog-fable] — Fable's positioning and the
  thesis that with a capable model the bottleneck shifts to scoping your
  unknowns
- [Model configuration][model-config] — the official reference for selecting a
  model (`/model`, `--model`, `ANTHROPIC_MODEL`, the `model` setting), the
  alias ladder, and the named effort levels
- [Claude Code settings][settings] — the `model`, `effortLevel`, and
  `alwaysThinkingEnabled` keys and the `MAX_THINKING_TOKENS` environment
  variable
- [Manage costs effectively][costs] — token-based billing (thinking billed as
  output tokens), the authority behind "it's all tokens"

[blog-model]: https://claude.com/blog/claude-model-and-effort-level-in-claude-code
[blog-fable]: https://claude.com/blog/a-field-guide-to-claude-fable-finding-your-unknowns
[model-config]: https://code.claude.com/docs/en/model-config
[settings]: https://code.claude.com/docs/en/settings
[costs]: https://code.claude.com/docs/en/costs
[subagents]: SUBAGENTS.md
[caching]: PROMPT-CACHING.md
