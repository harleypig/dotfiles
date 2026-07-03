---
paths:
  - "**/*.go"
  - "go.mod"
  - "go.sum"
---

# Go Rules

**Version:** v1.0.0

Go language conventions. The generic rules in `code-style.md` (naming,
paragraph spacing, 72-col comments, library-vs-executable error posture, Rule
of Three) apply here too; this file records the Go-specific specifics, defers
tool invocation to `golangci-lint.md`, and the test bar to `testing.md`.

## Formatting

- **`gofumpt`** (a stricter superset of `gofmt`) is the formatter. Do not
  hand-format and do not fight it.
- Deliver it through **golangci-lint v2's `fmt`** rather than a separate step
  — `formatters.enable: [gofumpt]` in `.golangci.yml`, run `golangci-lint fmt`
  (see `golangci-lint.md`). There is no first-party gofumpt pre-commit hook,
  so this is the single pinnable entry point for both format and lint.
- gofmt does not wrap lines — leave code line length to the formatter; keep
  **comments** wrapped at 72 cols per `code-style.md`.

## Naming & doc comments

- **`MixedCaps` / `mixedCaps`, never underscores**, for multiword names.
  Exported identifiers start uppercase; unexported lowercase.
- **Every exported top-level name has a doc comment, and the comment begins
  with the name** it documents ("`Parse` returns…", "`A Reader` implements…").
- Getters omit `Get`: `Owner()`, not `GetOwner()`.
- Package name matches its directory's last path component: short, lowercase,
  no underscores. Name it for what it provides — avoid `util` / `common`.

## Error handling

Follows the library-vs-executable posture in `code-style.md` (libraries
return/raise; `main` / CLI may exit). Go specifics:

- **Wrap with `%w`** to expose an error to callers:
  `fmt.Errorf("decompress %s: %w", name, err)`. Do **not** wrap when it would
  leak implementation detail — use `%v` to deliberately obscure the chain.
- Inspect with **`errors.Is(err, ErrSentinel)`** (sentinel) and
  **`errors.As(err, &target)`** (type) — never string-match an error.
- Export a sentinel `var ErrX = errors.New("…")` when callers must branch on
  it.
- Handle every error; an ignored `_ =` needs a reason comment.

## Project layout

Follow the Go team's **"Organizing a Go module"**, not the community
`golang-standards/project-layout` (which the official doc pointedly does not
endorse):

- **`internal/`** for packages that must not be importable outside the module
  — the compiler enforces it. Implementation packages live here.
- **`cmd/<name>/`** for command entry points in a mixed repo; a single-binary
  repo may keep `main.go` at the root.
- One package per directory; the import path is the module path + directory.

## Modules & versioning

- `go.mod` declares the `module` path, the `go` version directive, and
  `require`s. Commit `go.sum`.
- **Semantic import versioning:** at **v2+** the module path takes a matching
  `/vN` suffix (`example.com/mod/v2`) and the `module` line must carry it;
  v0/v1 need no suffix. A breaking change is a major bump (`git.md`).

## Testing

Meets the bar in `testing.md` (success + failure paths, a regression test per
bug). Go idioms:

- **Table-driven tests** with `t.Run(name, …)` subtests; `t.Parallel()` where
  tests are independent.
- `_test.go` beside the code — same package (white-box) or `<pkg>_test`
  (black-box, exercising the exported API).
- Coverage via `go test -cover ./...`.
- **Assertions:** prefer plain `go test` with **`google/go-cmp`** (`cmp.Diff`)
  for deep comparison — Google's Go style discourages assertion libraries.
  `stretchr/testify` is acceptable where it genuinely reads better; if used,
  prefer `require` (fails fast) over `assert`, and don't mix both in one file.

## Static analysis

- **`go vet`** is the baseline and is **subsumed by golangci-lint's `govet`**
  linter (default-enabled) — run golangci-lint, not both. The full linter set
  and config live in `golangci-lint.md`.

## Sources

Verified 2026-07-03:

- Effective Go (naming, testing, idioms) — <https://go.dev/doc/effective_go>
- Error wrapping (`%w`, `errors.Is` / `As`) —
  <https://go.dev/blog/go1.13-errors>
- Organizing a Go module (`internal/`, `cmd/`) —
  <https://go.dev/doc/modules/layout>
- Modules reference (semantic import versioning) — <https://go.dev/ref/mod>
- Google Go Style Decisions (MixedCaps, no assertion libraries) —
  <https://google.github.io/styleguide/go/decisions>
- gofumpt — <https://github.com/mvdan/gofumpt>

## Agent Behavior

- After creating or modifying any `*.go` file, run the format+lint pipeline in
  `golangci-lint.md` (prefer pre-commit where configured) and fix all
  findings.
- Match `code-style.md` and the idioms above; give every exported name a
  name-leading doc comment.
- Wrap errors with `%w`; inspect with `errors.Is` / `errors.As`; never
  string-match an error.
- Put non-exported implementation in `internal/`; do **not** adopt
  `golang-standards/project-layout`.
- Meet the `testing.md` bar with table-driven tests; prefer `go-cmp` over an
  assertion library.
