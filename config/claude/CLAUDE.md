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
