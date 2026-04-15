<!-- CLAUDE.md v1.0.0 -->
<!-- Source of truth: harleypig/dotfiles -->
<!-- Do not modify in other repositories. Copy updates from dotfiles. -->

# AI Agent Instructions

**Version:** v1.0.0

This file defines normative agent behavior across repositories. It is generic
and versioned. Repository-specific rules live in the imported files at the
bottom of this file and override anything stated here.

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

## General Development Principles

- Keep modules small and focused on a single responsibility.
- Follow DRY (Don't Repeat Yourself).
- Follow the Unix philosophy: do one thing, do it well.
- Use clear, descriptive, intent-revealing names throughout.
- Document complex logic inline; avoid obvious or redundant comments.
- Validate and test all AI-generated code before recommending it.
- **Executables:** fail fast. **Libraries:** surface errors by
  returning/raising, never by calling `exit`.
- Design for graceful degradation; report errors clearly to stderr.
- Optimize based on measurements; avoid premature optimization.

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
- Suggest validation or testing steps for generated code.
- When replacing legacy patterns, prefer modern equivalents and briefly note
  the substitution.

### Documentation

- Prefer inline documentation over separate doc files.
- Create separate files only when explicitly requested.
- Wrap Markdown at 78 columns; wrap code comments at 72 columns.
- Clearly distinguish current best practices from historical examples.

### Testing

- Provide unit tests for all generated code.
- Test both success and failure paths.
- Follow the framework and structure defined in `TESTS.md`.

### Git Workflow

- Use Conventional Commits format for commit messages.
- Keep the subject line under 72 characters; wrap body at 72 columns.
- Reference issues where applicable (`Fixes #123`, `Relates to #456`).
- Do not force-push, amend published commits, or skip hooks without explicit
  user approval.

### Style and Static Analysis

- Maintain consistent formatting as defined in `CONVENTIONS.md`.
- Enforce syntax validity and consistent naming across all resources.

---

@WORKFLOW.md
@CONVENTIONS.md
@TESTS.md
