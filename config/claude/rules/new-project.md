---
# Setup activity has no single file type; scope to the manifest and
# scaffolding files a project init / conversion actually touches, so this
# policy loads then but never joins the always-on tier.
paths:
  - "pyproject.toml"
  - "package.json"
  - "Cargo.toml"
  - "go.mod"
  - "Gemfile"
  - ".pre-commit-config.yaml"
  - ".pre-commit-config-fix.yaml"
  - "DEVELOPER.md"
---

# New Project Setup Rules

**Version:** v1.0.0

Standing policy for **initializing a new repository** *or* **converting an
existing one** to these conventions. This is the passive policy that should
shape setup decisions even when the procedure isn't explicitly invoked; the
**procedure** is the **`new-project` skill** (`skills/new-project/`) — reach
for it to actually run a setup. It composes the existing rules
(`git.md`, `gh.md`, `pre-commit.md`, `testing.md`, the per-language rules)
rather than restating them; defer to each on its specifics.

## Policy

- **Language bootstrapping lives in the per-language rule**, not here. Poetry
  (`poetry.md`), npm, cargo, a NeoForge MDK, etc. each own their own
  `<tool> init` / scaffold steps. This rule and the skill stay
  stack-agnostic and **delegate** to them — keep one language's specifics out
  of the generic layer (`EXTENDING.md` *Layer the generic over the
  specific*). A language with no bootstrapping coverage in its rule is a gap
  to capture (`CLAUDE.md` *Missing or Conflicting Tool Rules*), not to inline
  here.

- **Defer the `.claude/` scaffold** until repo-specific conventions actually
  emerge. Phase-0 setup rarely produces enough repo-specific content
  (CONVENTIONS / WORKFLOW / TESTS, local rules) to justify it — the global
  config already covers the generic case. Create it when the repo has
  something to say that the global layer doesn't.

- **Editor config belongs in the editor's own config repo, not the project.**
  `DEVELOPER.md` may *note* the maintainer's editor; it must not prescribe
  editor setup. When wiring a formatter/linter, match any committed
  editor/format settings (`.editorconfig`, indent width) to **the formatter's
  output**, not language-community defaults — e.g. `google-java-format` emits
  2-space, not the traditional 4-space Java style. Record the rationale for a
  non-obvious choice (an `adr`, or a `DEVELOPER.md` note) so a later session
  doesn't relitigate it.

- **Pin tool versions to current stable at setup** — pre-commit hook `rev`s
  especially — and note that they need periodic review as the tools release
  updates (the `deps-update` skill).

- **Investigate actual storage / file formats before designing around them.**
  Official docs may describe an outdated format (e.g. a tool that switched
  from per-record JSON to a binary blob without updating its docs). Verify
  against the real artifact, not memory.

- **Check for already-cloned sibling repos** (`$PARENT_DIR/<repo-name>/`)
  before suggesting a clone location for a related/foreign dependency — see
  `git.md` *Related/Foreign Repositories*.

- **Capture gaps, don't block on them.** Setup frequently exposes gaps in the
  global config (missing docs, redundant settings, stale paths). Capture each
  as a follow-up `- [ ]` in the relevant repo's `TODO.md` (or the dotfiles
  audit backlog for agent-config gaps) rather than letting it stall the
  setup.

- **Never author on a protected branch.** A conversion lands through the
  repo's normal workflow — branch first, PR, approval — never direct commits
  to a protected default (`git.md` *Never Work Directly on a Protected
  Branch*).

## Sources

House convention — no external source. Grounded in this repo's own setup
practice and the rules it composes (`git.md`, `gh.md`, `pre-commit.md`,
`testing.md`, the per-language rules); recorded in
`config/claude/audit/decisions-log.md`.

## Agent Behavior

- When starting a new repo, or converting an existing one to these
  conventions, **invoke the `new-project` skill** and apply the policy above
  throughout.
- Bootstrap a language via **its** rule; never inline language-specific
  scaffold steps into the generic setup.
- Defer the `.claude/` scaffold until the repo has repo-specific content;
  capture global-config gaps as TODO follow-ups instead of blocking.
