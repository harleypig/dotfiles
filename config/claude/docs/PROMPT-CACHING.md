# Prompt Caching — Why Claude Code Is Built the Way It Is

**Prompt caching** is what makes a long-running agent like Claude Code
affordable: the API remembers the expensive computation for the front of a
request and reuses it on the next turn instead of recomputing it from
scratch. The catch is that reuse is **prefix-matched** — it counts only from
the very start of the request up to each **`cache_control` breakpoint**, and
*any* change inside that prefix throws away everything cached after it.
Because a high **cache hit-rate** funds more generous rate limits and lower
cost — Anthropic runs alerts on it and declares SEVs when it drops — keeping
the shared prefix intact is treated as mission-critical. This document
explains the caching mechanism in plain terms, then the concrete design rules
that fall out of it: order static content first and dynamic last, push state
changes through messages rather than prompt edits, never churn the tool set
or the model mid-conversation, model state as tools, and fork or compact in a
cache-safe way. In short, it is why Claude Code is built the way it is.

## ELI5

Plain-language one-liners that double as a quick summary of everything this
doc covers. Details are in the sections below; every source link is at the
bottom.

*What caching even is:*

- **prompt caching** — Claude saves the work it did on the front of your
  request so it doesn't redo it every turn.
- **prefix match** — the saved work is reused only from the very start of the
  request up to the first thing that differs from last time.
- **`cache_control` breakpoint** — a marked spot in the request saying "cache
  everything up to here so it can be reused."

*Why the whole design obsesses over it:*

- **cache hit-rate** — the share of requests that reuse cached work; keeping
  it high is what pays for generous rate limits and low cost, so Anthropic
  alerts (and SEV-alerts) on it.

*Keep the cache — the do's:*

- **static first, dynamic last** — put what never changes at the top so the
  most requests possible share the same prefix.
- **update via messages** — tell Claude something new in the next *message*,
  not by rewriting its system prompt.
- **state as tools** — change a mode with a tool call (Plan Mode), not by
  editing the prompt or the tool list.
- **deferred tool stubs** — list a tool by name only and load its full schema
  on demand, so the tool set itself never changes.
- **cache-safe fork / compact** — branch or shrink a conversation while
  reusing the parent's *exact* prefix.

*Keep the cache — the don'ts:*

- **don't add/remove tools mid-conversation** — one of the most common ways
  people break prompt caching.
- **don't switch models mid-conversation** — a switch rebuilds the whole
  cache; it can cost more than just answering with the model you're on.

A *different* question — which model to run, and at what reasoning effort — is
its own topic; see [Models & Effort][models-doc].

### Best practices

- **Ask one question of every change: "does this alter the prefix?"** If yes,
  it invalidates the cache from that point on — do it only when the payoff is
  worth the recompute.
- **Layer the request stable → volatile.** Static system prompt and tools
  first, then project context, then session context, then the live
  conversation.
- **Never mutate the system prompt to convey state.** New facts are *data* in
  the next message, not edits to the frame.
- **Fix the tool set and the model for the life of a conversation.** Reach for
  deferred stubs instead of adding tools, and a subagent hand-off instead of
  switching models.
- **Model behavior modes as tools**, so a mode change is a tool call inside a
  stable prefix — not a prompt or tool-list rewrite.
- **Fork and compact by cloning the parent's prefix**, so the child request
  looks nearly identical to the parent and reuses its cache.

## Overview

A request to the model is matched against the cache as a **prefix**: the API
["caches everything from the start of the request up to each `cache_control`
breakpoint"][docs-caching], and reuse stops at the first byte that differs
from a previously cached request. So a cache hit is not "have I seen this
request" — it is "how much of this request's *front* is byte-for-byte
identical to one I already computed." Everything after the first difference
is uncached and paid for in full. That single fact drives every rule below:
*"the order you put things in
matters enormously, you want as many of your requests to share a prefix as
possible."*

**Why the hit-rate is mission-critical.** A high cache hit-rate is not just a
nicety — at Anthropic it is a tracked operational metric. The team "run[s]
alerts on our prompt cache hit rate and declare[s] SEVs if they're too low,"
because a high rate is what funds "more generous rate limits for our
subscription plans" while it "decrease[s] costs." A long-running agent that
recomputed its whole context every turn would be too slow and too expensive to
exist; prompt caching is what makes it feasible.

**The distinction to remember:** every design choice in Claude Code is
downstream of one question — *does this change the cached prefix?* If it does,
it costs a recompute of everything after it. The rest of this doc is the set
of disciplines that keep the answer "no."

### At a glance — the seven prefix disciplines

Each rule protects the shared prefix, but they split into two jobs:
**shaping** the prefix (getting the layout right up front) and
**stabilizing** it (keeping the cached region unchanged once the conversation
is underway).

| Discipline | Keep constant | Cache-break it prevents | Seen in this harness |
|------------|---------------|-------------------------|----------------------|
| **Static-to-dynamic order** | the request's *layering* | volatile data placed early → invalidates all after it | system prompt + tools first, live messages last |
| **Updates via messages** | the system prompt | a mid-session prompt edit rewrites the prefix | new context arrives as a user / tool message |
| **Stable tool set** | the tool list | add/remove a tool → prefix changes | deferred stubs, loaded on demand |
| **Deferred tool stubs** | the tool *prefix* | lazily adding full schemas mid-run | `defer_loading: true` stubs via ToolSearch |
| **Stable model** | the model | a model switch rebuilds the whole cache | one model per conversation; hand off via subagent |
| **State as tools** | the tool *definitions* | mutating defs to change mode | Plan Mode = `EnterPlanMode` / `ExitPlanMode` |
| **Cache-safe fork/compact** | prefix + tools + history | a differently-shaped child request | compaction reuses the parent's prefix |

In table order: **static-to-dynamic order** puts the never-changing content at
the top so requests share it; **updates via messages** keeps new state out of
the system prompt; **stable tool set** forbids adding or removing tools
mid-conversation; **deferred tool stubs** are how you keep that set stable
while still having a large tool library; **stable model** forbids switching
models in place; **state as tools** expresses a mode change as a tool call
rather than a definition edit; and **cache-safe fork/compact** shrinks or
branches a conversation while looking "nearly identical" to its parent.

## The caching contract (API mechanics)

Everything above is a *consequence* of how the API actually caches. Keep the
two halves distinct: the prefix disciplines are Claude Code's **design
patterns** (from the engineering post), while the constraints they bend
around are the API's **published contract** for
[prompt caching][docs-caching]. Claude Code leans on that contract
automatically — it [optimizes costs through prompt caching][cc-costs] for
repeated content like the system prompt. The mechanics that make the patterns
necessary:

**Breakpoints are explicit, and there are at most four.** You mark what to
cache by attaching `"cache_control": {"type": "ephemeral"}` to a content
block; [`ephemeral` is currently the only cache type][docs-caching]. A
request may carry up to **four** breakpoints, on blocks in the `tools`,
`system`, or `messages` arrays. The cache is *written* only at the
breakpoint, and a hit requires the prompt to be **100% identical** up to and
including that block — the byte-for-byte prefix match every discipline above
exists to protect.

**A prefix has to be big enough to cache.** Below the model's minimum,
nothing is cached: the [minimum cacheable prefix][docs-caching] is roughly
**1,024 tokens** for Sonnet 5 / Opus 4.8 and **2,048–4,096** for other models
(the API docs carry the authoritative per-model table). This is one more
reason the large, stable content — system prompt and tool definitions — sits
at the front: it clears the threshold, so caching it is worthwhile.

**The cache has two lifetimes, and reads keep it warm for free.** The default
entry lives **5 minutes** and is [refreshed at no cost each time it is
read][docs-caching], so an active conversation keeps its prefix warm on its
own. An optional **1-hour** TTL (`{"type": "ephemeral", "ttl": "1h"}`)
survives longer idle gaps, at a higher write price.

**Reads are cheap; writes cost a premium.** Against the base input-token
price, a cache **read** (a hit) is **0.1×**, a **5-minute write** is
**1.25×**, and a **1-hour write** is **2×** — see [cache
pricing][docs-caching]. That is the entire economic case for the disciplines:
the hit at one-tenth price is the payoff, and a broken prefix forces a fresh
write at 1.25×, so you pay *more* than the uncached baseline to rebuild what
you just discarded.

**Invalidation cascades down a hierarchy.** Changes propagate `tools` →
`system` → `messages`: a change at any level [invalidates that level and every
level after it][docs-caching]. Editing a tool definition is therefore the
most expensive possible change — it invalidates the tools cache and with it
the system and messages caches, i.e. the whole request. That is why "don't
add or remove tools" and "model state as tools, not definition edits" are
*hard* rules and not mere preferences: tool changes sit at the top of the
cascade, so they cost the most.

## Shaping the prefix — get the layout right

These two rules govern how you *lay a request out* so the largest possible
share of requests begin with the same bytes.

### The static-to-dynamic layering

Order content from the least likely to change to the most likely, so the
stable part is a long shared prefix:

1. **Static system prompt & tools** — cached *globally*, across every session.
2. **Project-specific context** — cached *within a project*.
3. **Session context** — cached *within a session*.
4. **Conversation messages** — the live, per-turn tail.

The point of the ordering is to "maximize how many sessions share cache hits":
a byte that never changes belongs at the very front, where every request on
earth can reuse it, and the churny per-turn content belongs at the very back,
where it invalidates nothing above it. Put a volatile value early — a
timestamp, a changing file list, a per-turn counter in the system prompt — and
you have moved the first-difference point to the top of the request, throwing
away the cache for *everything after it*. Layout is the cheapest lever you
have; spend it before anything else.

### Push updates through messages, not the system prompt

When new information appears mid-conversation — a file changed, a new
instruction, a fresh piece of context — the tempting move is to edit the
system prompt to include it. That is the wrong move: the system prompt lives
in the cached prefix, so rewriting it invalidates the cache from that point
down. The guidance is to "pass in this information via messages in the agent's
next turn instead." A message appended to the end of the conversation lands
*after* the entire cached prefix, so it costs nothing already cached — the
prefix is untouched and fully reused. The rule of thumb: **new state is data
in the conversation, never a rewrite of the frame.**

## Stabilizing the prefix — no mid-conversation churn

Getting the layout right is not enough; the cached region also has to stay
*byte-for-byte constant* for the life of the conversation. These rules forbid
the changes that quietly rewrite it turn to turn.

### Don't add or remove tools

Tool definitions live in the cached prefix, so the tool set is part of what a
request shares with its predecessors. "Changing the tool set in the middle of
a conversation is one of the most common ways people break prompt caching" —
adding a tool, removing one, even reordering them shifts the prefix and forces
a recompute of everything after the tool block. Decide the tool set up front
and hold it fixed. When you think you need to add a tool mid-run, you actually
want the next rule.

### Deferred tool stubs (`defer_loading: true`)

A large tool library creates a real tension: you don't want every tool's full
schema in every request (it bloats the prefix and the context), but you also
can't add tools lazily without breaking the cache. The resolution is to keep
the *set* constant while deferring the *weight*. Send "lightweight stubs (just
the tool name, with `defer_loading: true`)" in the stable prefix up front; the
full schema loads only when "the model can 'discover' [it] via tool search
when needed." The list of stubs never changes — so the prefix stays stable —
while the expensive schemas materialize on demand, off the cached path. You
get a big toolbox and a stable prefix at the same time.

### Don't switch models

A cached prefix is specific to the model that computed it, so switching models
mid-session rebuilds the entire cache from nothing. This inverts naive
intuition about cost: for a simple sub-question it is "more expensive to
switch to Haiku than to have Opus answer," because the switch pays to
re-establish the whole context on the new model. If a conversation genuinely
needs a different model, don't switch in place — hand off. You "could deploy
a subagent that prompts Opus to prepare a 'hand-off' message to another
model," keeping each conversation on one model and its cache intact.
(Choosing the model and effort level in the first place is [its own
topic][models-doc].)

### Model state as tools, not prompt edits (Plan Mode)

The general trick for changing the agent's *behavior* without touching the
cached prefix: express the state transition as a **tool**, not as an edit to
the system prompt or the tool definitions. **Plan Mode** is the canonical
example — rather than swapping the tool set when the agent should stop editing
and start planning, "we keep *all* tools in the request at all times and use
`EnterPlanMode` and `ExitPlanMode` as tools themselves." Because the tools
never change, "the model can autonomously enter plan mode when it detects a
hard problem, without any cache break." The mode is now a value the model sets
with a tool call inside a stable prefix, not a reshaping of that prefix. (Plan
Mode as a permission state is covered in [Permission Modes][perm-doc].)

### Cache-safe forking and compaction

When a conversation approaches the context limit, Claude Code **compacts**
it — summarizes the history — and does so by **forking**: the compaction
request uses "the *exact same* system prompt, user context, system context,
and tool definitions as the parent conversation." The payoff is that "from
the API's perspective, this request looks nearly identical to the parent's
last request—same prefix, same tools, same history—so the cached prefix is
reused."
Forking is cache-cheap for the same reason: a branch that preserves the
parent's prefix pays nothing to re-establish it, where a fresh call with a
differently-shaped prefix would recompute the entire (often enormous)
conversation history from scratch. Compaction and forking are the same move —
keep the parent's prefix, change only the tail.

## Bringing it together

Every rule above collapses to one question asked of any change: **does this
touch the cached prefix?** Shape the prefix once (static first, dynamic last),
then never disturb it — state goes in messages, the tool set and model stay
fixed, mode changes are tool calls, and branches clone the parent. This
harness is a live instance of all of it:

- **Deferred tools via ToolSearch.** The system-reminder lists some tools by
  *name only*; their schemas are absent until fetched with `ToolSearch`. That
  is the `defer_loading: true` stub pattern in action — a big toolbox behind a
  stable tool prefix, schemas pulled onto the context only when a tool is
  actually selected.
- **Plan Mode as tool-modeled state.** Entering and leaving plan mode is a
  tool call, not a prompt rewrite, so the agent can switch posture mid-task
  with no cache break — see [Permission Modes][perm-doc].
- **Compaction / forking.** When the conversation grows long, it is compacted
  by reusing the parent's exact prefix rather than rebuilt — the same
  cache-safe fork the blog describes.
- **One model per conversation.** Delegating a differently-modeled sub-task to
  a [subagent][subagents-doc] (rather than switching the main model in place)
  keeps this conversation's cache intact — context isolation and cache
  stability are the same discipline.

The through-line: the ergonomics that feel like ordinary product choices —
stubbed tools, a plan mode, automatic compaction, subagents — are *cache*
decisions first. Prompt caching is everything.

## See also — adjacent, out of scope

This doc is about the caching mechanism and the prefix disciplines. Three
neighboring topics each get their own reference:

- **Permission Modes** — Plan Mode appears here as the example of state
  modeled as a tool; *as a permission gate* (what it allows, how auto-mode
  decides) it is a separate subject. See [Permission Modes][perm-doc].
- **Models & Effort** — this doc says *don't switch models mid-conversation*;
  *which* model to pick and at what reasoning effort is a different decision.
  See [Models & Effort][models-doc].
- **Subagents** — the cache-safe alternative to a model switch, and the
  consumer of deferred tools / isolated context. How subagents actually work
  is its own topic. See [Subagents][subagents-doc].

The last two are tracked in the backlog where not yet written; this doc stays
on caching.

## Resources

Distilled from the "prompt caching is everything" blog post and the official
Claude documentation:

- [Prompt caching is everything][blog] — the source blog post
- [prompt caching (API docs)][docs-caching] — `cache_control` breakpoints, the
  `ephemeral` type, the 5-minute / 1-hour TTLs, minimum prefix sizes, the
  invalidation hierarchy, and read/write pricing
- [Claude Code costs][cc-costs] — how Claude Code applies caching
  automatically to repeated content
- [Permission Modes][perm-doc] — Plan Mode as a permission state
- [Models & Effort][models-doc] — choosing a model / reasoning effort
- [Subagents][subagents-doc] — hand-offs, deferred tools, context isolation

[blog]: https://claude.com/blog/lessons-from-building-claude-code-prompt-caching-is-everything
[docs-caching]: https://docs.claude.com/en/docs/build-with-claude/prompt-caching
[cc-costs]: https://code.claude.com/docs/en/costs
[perm-doc]: PERMISSION-MODES.md
[models-doc]: MODELS-AND-EFFORT.md
[subagents-doc]: SUBAGENTS.md
