<!-- CLAUDE.md v1.1.0 -->

# AI Agent Instructions

This file defines normative agent behavior across repositories. It is generic
and versioned. Repository-specific rules live in each project's `.claude/`
directory and override anything stated here.

**Precedence:** `WORKFLOW.md` > `CONVENTIONS.md` > `TESTS.md` > this file

## Behavioral Requirements

1. **Interpret instructions literally and hierarchically.** More specific
   rules override general ones.
2. **Repository-specific files override this file.** Treat `WORKFLOW.md`,
   `CONVENTIONS.md`, and `TESTS.md` as authoritative for this repository.
3. **If a referenced file is missing,** suggest creating it when appropriate;
   do not create it automatically.
4. **Operate autonomously within defined boundaries.** Act without confirmation
   unless a rule explicitly requires it.

## Pre-Implementation

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them; do not silently choose.
- If a simpler approach exists, say so before implementing the requested one.
- If the task is unclear, stop and name what is confusing before proceeding.

## Handling Feature Requests

Before implementing a requested feature or resolving an issue:

- **Scan for prior deferred decisions first.** Run `grep -rn "ICEBOX:"`
  across the codebase — an `ICEBOX:` marker (see `rules/code-style.md`)
  records a considered "not now" with the context for revisiting. Surface a
  relevant hit instead of silently re-deciding.
- **When the feature depends on an external API / service / library, verify
  it is actually supported** against *current* official docs before committing
  to build it (Context7 if available, otherwise the official reference).
  Capabilities and limits change — do not assume from memory.
- **If it is unsupported, say so with evidence** (what the API does expose
  versus what is missing) and offer the nearest feasible alternative.
- **Record the limitation so it is not re-attempted:** an `ICEBOX:` note at
  the nearest relevant code (dated, keyword-dense) **and** an entry in that
  dependency's *Limitations* list — its `rules/<tool>.md` when the limit is a
  generic fact about the dependency, or the repo's `.claude/` when it is a
  repo-specific constraint.

## Scope Discipline

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that was not requested.
- No error handling for scenarios that cannot occur.
- When editing existing code: do not improve adjacent code, comments, or
  formatting; do not refactor code that is not broken.
- If unrelated dead code is noticed, mention it; do not delete it without
  permission.
- Clean up only orphans your own changes created (unused imports, variables,
  functions). Leave pre-existing dead code alone.
- Every changed line must trace directly to the user's request.

## Verification

- Define verifiable success criteria before implementing.
- For multi-step tasks, state the plan and the verification check for each
  step before beginning.
- Prefer criteria that can be checked automatically (tests, types, build
  success) over criteria that require manual review.
- Weak criteria ("make it work") force clarification cycles; strong criteria
  enable autonomous execution.

## Tool Detection and Policy

Do not assume a tool is in use unless a detection signal is present in the
repository. Tool-specific agent rules are resolved in this order:

1. `.claude/rules/<tool>.md` — project-level, takes precedence
2. `$CLAUDE_CONFIG_DIR/rules/<tool>.md` — user-level (default:
   `~/.claude/rules/<tool>.md`)

If neither exists, do not invent behavior for the tool.

| Tool       | Detection signal                   | Rules file          |
|------------|------------------------------------|---------------------|
| pre-commit | `.pre-commit-config.yaml` at root  | `pre-commit.md`     |

Additional tool detection signals and rules are defined in `WORKFLOW.md`.

## Configuration Migration

When converting or consolidating repo-level configuration (e.g., extracting
`AGENTS.md` / `WORKFLOW.md` content into `.claude/` files, or migrating one
repo to match another's pattern), evaluate each item against three scopes
before placing it:

1. **Language- and repo-agnostic** (78-col Markdown wrap, intent-revealing
   names, library-vs-executable error policy, git/gh conventions) → global
   `CLAUDE.md` or `rules/code-style.md`.
2. **Language-specific, repo-agnostic** (Python uses pydantic + type hints;
   Bash uses shellcheck) → global `rules/<language>.md`.
3. **Truly repo-specific** (this repo's API contract, this repo's module
   layout, business rules) → repo's `.claude/CONVENTIONS.md` or
   `.claude/WORKFLOW.md`.

Do not assume content is repo-specific just because it currently lives in
the repo. When in doubt, prefer promotion (tier 1 or 2) over duplication
per repo. Surface candidates and ask before duplicating.

## Missing or Conflicting Tool Rules

**Concrete trigger.** Treat these events as a checkpoint to verify rule
coverage, and act *as they happen* — do not wait to be asked:

- Adding a dependency to a manifest (`package.json`, `pyproject.toml`,
  etc.) for a library that has no `rules/<name>.md`.
- First authoring a file in a language/framework that has no
  `rules/<language>.md`.
- Adding, modifying, or removing a **rule, skill, or hook** →
  update `config/claude/STRUCTURE.md` (the hand-maintained reference
  map; see *When to Propose a Skill* for the skill threshold).

A `PostToolUse` hook (`~/.claude/hooks/rule-coverage.py`) also flags these
as a backstop, but the hook is a reminder — the responsibility to surface
and propose the rule is the agent's regardless of whether it fires.

When working with a tool or language and the global config has no
corresponding rules file (no `rules/<tool>.md`), or the existing rule
conflicts with how the repo actually uses the tool, or the rule has
gone stale relative to current best practice:

- Stop and surface the gap before silently working around it.
- Ground the new or updated rule in official docs / man pages and cite the
  source, never memory (see `EXTENDING.md` *Grounding & sourcing*).
- Propose creating or updating the rule, and decide its scope using the
  three-tier model in *Configuration Migration*:
  - Generally useful across repos → new or updated global
    `rules/<tool>.md` (or `rules/<language>.md`).
  - Only meaningful in this repo → an override in the repo's
    `.claude/CONVENTIONS.md` or `.claude/WORKFLOW.md`.
- For conflicts: do not edit the global rule unilaterally to satisfy a
  single-repo need. The repo override belongs in `.claude/`; the global
  rule changes only when the new behavior is genuinely better for all
  consumers.
- Consider a **plugin** too: before authoring, check whether an installed or
  available plugin already provides the capability (or should be added) —
  decide adopt-vs-build per `EXTENDING.md` *Build vs adopt* and `rules/mcp.md`
  (plugins are global-only and always-on, so only a good global fit earns
  one).

## When to Propose a Skill

Rules describe policy and reference; skills package multi-step
procedures with branches and decisions (see *Tool Detection and Policy*
for the rule home). Propose creating a new skill when, in the course of
work, you find yourself:

- Executing the same multi-step sequence (three or more steps with
  decisions or branches) more than once.
- Coordinating multiple tools to achieve a single user-visible outcome
  (e.g., bump version → build → tag → push → release-create; or scaffold
  a Poetry project → wire pre-commit → seed tox envs).
- Repeatedly making the same judgment calls about which flag, group,
  env, or branch to use based on repo state.

When the pattern shows up, surface the candidate to the user with a
proposed name, trigger conditions, and step outline. Decide its scope
using the three-tier model in *Configuration Migration*:

- Generally useful across repos → propose a global skill.
- Repo-specific workflow → propose a repo-level skill (or a script).

Before building one, also check whether a **plugin** already packages this (a
marketplace skill/command) — adopt-vs-build per `EXTENDING.md` *Build vs
adopt*; prefer our own lean skill when the plugin is bloated for the context
it costs.

Do not invent skills for one-shot tool invocations — those belong in a
rule. The threshold is "this is a procedure I would write up for a new
contributor," not "this is how a flag works."

**Rules and skills suggest commands; they cannot call them.** When a
built-in slash command (`/code-review`, `/security-review`, `/simplify`,
…) is the right tool for a step in a rule or skill you author, **name it**
at that step — the model invokes skill-backed commands via its Skill tool,
so naming is enough to get it run (a suggestion, not a guarantee; for a
must-run gate, use a hook). Do not reimplement what a command already does.

## Resource Validity

- Before recommending a tool, library, or pattern, verify it is actively
  maintained and reflects current security practices.
- Treat patterns from the pre-2010 era as presumed obsolete unless explicitly
  justified for historical or educational reasons.

## Responsibilities by Task Type

### Code Generation

- Check for similar existing code before generating new files.
- Follow existing repository structure and naming conventions.
- Include inline comments for non-trivial logic.
- Validate and test all AI-generated code before recommending it.
- Suggest validation or testing steps for generated code.
- When replacing legacy patterns, prefer modern equivalents and briefly note
  the substitution.

### Documentation

- Prefer inline documentation over separate doc files.
- Create separate files only when explicitly requested.
- Clearly distinguish current best practices from historical examples.

### Testing

- Provide unit tests for all generated code.
- Test both success and failure paths.
- Follow the framework and structure defined in `TESTS.md`.

### Git Workflow

- Do not force-push, amend published commits, or skip hooks without explicit
  user approval.

### Style and Static Analysis

- Maintain consistent formatting as defined in `CONVENTIONS.md`.
- Enforce syntax validity and consistent naming across all resources.
