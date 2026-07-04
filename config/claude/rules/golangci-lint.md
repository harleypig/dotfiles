---
paths:
  - "**/*.go"
  - ".golangci.yml"
  - ".golangci.yaml"
  - ".golangci.toml"
---

# golangci-lint Rules

**Version:** v1.1.0

The Go meta-linter (and, in v2, formatter). Pairs with `go.md` (language
policy) and `pre-commit.md` (how it is gated). golangci-lint is currently
**v2** — v1 config is **not** compatible.

## Invocation

- **Lint:** `golangci-lint run ./...`
- **Format:** `golangci-lint fmt` — runs the enabled *formatters* (v2's
  dedicated formatting pass; see below).
- Auto-fix fixable lint findings: `golangci-lint run --fix`.
- Verify a config parses: `golangci-lint config verify`.

## v2 config — two independent sections

`.golangci.yml` splits into **`linters:`** and **`formatters:`**, each with its
own `settings` and `exclusions`:

```yaml
version: "2"

formatters:
  enable:
    - gofumpt      # stricter gofmt (see go.md)
    - goimports    # or gci, for import grouping

linters:
  enable:
    - errcheck
    - govet
    - ineffassign
    - staticcheck
    - unused
    # the five above are the default set; add more as the repo needs
```

- **Formatters** (v2): `gofmt`, `gofumpt`, `goimports`, `gci`, `golines`,
  `swaggo` — all auto-fix, run via `golangci-lint fmt`. This is the single
  entry point for Go formatting; there is **no** first-party gofumpt
  pre-commit hook (see `go.md`).
- **Default linters** (enabled without config): `errcheck`, `govet`,
  `ineffassign`, `staticcheck`, `unused`. **`govet` subsumes `go vet`** — do
  not run `go vet` separately.

### Recommended additions beyond the defaults

The default five cover correctness; add these where the repo warrants — they
supply `qa.md`'s **security (SAST)** and **complexity** dimensions inside the
one lint pass:

- **`gosec`** — Go SAST (hardcoded creds, weak crypto, unhandled `Close`,
  tainted file paths). Its common false positives — notably **G107** ("HTTP
  request with a variable URL", normal for an API client building
  `baseURL + path`) — are already silenced by the **`common-false-positives`**
  exclusion preset, so keep that preset enabled.
- **`gocyclo`** — a cyclomatic-complexity guardrail. Set
  `settings.gocyclo.min-complexity` **just above the repo's current ceiling**
  (≈ 20–30) so it flags *new* tangled functions without forcing a refactor of
  existing branchy-but-fine code (provider CRUD, request handlers). It catches
  regressions, not the status quo.
- Other low-noise correctness/clarity linters worth enabling: `misspell`,
  `unconvert`, `unparam`, `predeclared`, `forcetypeassert`, `godot`.

Vulnerability scanning is **not** a golangci-lint linter — `govulncheck` runs
separately (see `go.md` *Security scanning*).

## pre-commit

golangci-lint ships its own `.pre-commit-hooks.yaml`. Pin the repo at a
**verified** latest release (never guess the rev — `pre-commit.md`):

```yaml
- repo: https://github.com/golangci/golangci-lint
  rev: v2.12.2   # verify latest before pinning
  hooks:
    - id: golangci-lint-fmt            # `golangci-lint fmt` — put in the FIX config
    - id: golangci-lint-full           # `golangci-lint run --fix` (whole module) — CHECK config
    - id: golangci-lint-config-verify  # `golangci-lint config verify` — CHECK config
```

- Hook IDs: **`golangci-lint`** (changed files, `--new-from-rev HEAD`),
  **`golangci-lint-full`** (whole module — prefer for CI), **`golangci-lint-fmt`**
  (formatting), **`golangci-lint-config-verify`**.
- Split per `pre-commit.md`: the modifying **`-fmt`** hook goes in the fix
  config; the check/verify hooks in the check config.
- These hooks install via `language: golang`, which is fine in a Go repo (Go
  is present). The `docker_image` preference in `pre-commit.md` matters most
  for non-Go repos; a Go project's contributors already have the toolchain.

## Agent Behavior

- After any `*.go` change, run `golangci-lint run ./...` (or via pre-commit)
  and fix all findings; format with `golangci-lint fmt` — not a standalone
  gofmt/gofumpt.
- Do **not** run `go vet` separately; `govet` covers it.
- Beyond the default five, enable **`gosec`** (SAST) and **`gocyclo`**
  (complexity, `min-complexity` set just above the repo's current ceiling);
  keep the `common-false-positives` preset so gosec's G107 stays silenced.
- Pin the pre-commit `rev` to a verified latest release (`pre-commit.md`).
- Prefer pre-commit when configured: `pre-commit run --files <f>` to check,
  the fix config to format.

## Sources

Verified 2026-07-03:

- Config file (v2 `linters` / `formatters` split) —
  <https://golangci-lint.run/docs/configuration/file/>
- Formatters (`golangci-lint fmt`) — <https://golangci-lint.run/docs/formatters/>
- Default linters / `govet` —
  <https://golangci-lint.run/docs/linters/configuration/>
- `gosec` (Go SAST) — <https://github.com/securego/gosec>
- `gocyclo` (cyclomatic complexity) — <https://github.com/fzipp/gocyclo>
- Latest release — <https://github.com/golangci/golangci-lint/releases/latest>
- pre-commit hooks —
  <https://github.com/golangci/golangci-lint/blob/main/.pre-commit-hooks.yaml>
