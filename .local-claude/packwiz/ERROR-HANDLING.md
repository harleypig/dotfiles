# Error-Handling Audit

Inventory of sites where the current error-handling behavior is
ambiguous enough to warrant an explicit policy decision. Feeds the
"Audit and improve error handling" TODO. Companion artifact, not a
plan — each item below is a question, not a fix.

## Why this exists

PR #384 (*Exit on download failure during modrinth pack export* by
@jackwilsdon) is the canonical example: `packwiz modrinth export`
silently produces an incomplete `.mrpack` when a mod download fails.
The author flagged it himself — *"it's not clear if this is the
intended behaviour"*. That ambiguity is the real problem. The
codebase has no documented error posture, so every failure path is
an ad-hoc decision.

Goal: establish, per site, whether the path should
- **fail fast** (stop the operation, non-zero exit),
- **surface with context** (print a clear, structured warning and
  continue, but exit non-zero at the end so callers can detect it),
- **skip-and-warn** (print and continue, succeed overall), or
- **stay silent** (current behavior is genuinely fine).

## Branching and sequencing

This work is split into topically-grouped `pr/<name>` branches.
**All of them stack on `pr/testing`, not on `upstream/main`.**
The error-handling changes depend on test infrastructure — helpers,
behavioral coverage, expected-failure cases — that lives in
`pr/testing` and does not exist on `upstream/main` yet.

```
upstream/main
    └── pr/testing  (PR #402)
            ├── pr/error-handling-exports
            ├── pr/error-handling-library-exits
            └── pr/error-handling-...
```

**Syncing these branches:** when `pr/testing` is rebased (upstream
review feedback, `upstream/main` advancing), do a cascade rebase
of every stacked error-handling branch onto the new `pr/testing`
tip — not `upstream/main`.

**After `pr/testing` merges upstream:** rebase each remaining
error-handling branch directly onto `upstream/main` (the
`pr/testing` commits disappear from their diffs cleanly) and
resume the normal single-base sync from that point.

**Candidate groups** (scope decided at implementation time):
- Export-pipeline silent failures (`modrinth export`,
  `curseforge export`, `AddNonMetafileOverrides`) — includes
  PR #384 merge or equivalent.
- Library-code fatal exit (`cmdshared/mcversion.go`,
  `core/indexfiles.go`, `curseforge/request.go`).
- Cobra `Run` error-posture normalisation (stdout → stderr,
  `RunE` vs helper).
- Resource cleanup (`Close` on writers, partial-file handling).

Resolve the cross-cutting questions below before splitting into
groups — the answers may collapse or split candidates differently.

## How to read this file

For each finding:

- **Location** — `file:line` against the working tree at the time
  of audit. Verify the line range before acting; numbers will
  drift.
- **Today** — one-sentence summary of current behavior.
- **Why it matters** — user-visible consequence.
- **Decision** — pick one of:
  - **leave** — current behavior is correct; document the
    intent inline (one-line comment, no docstring novella).
  - **handle elsewhere** — the right fix lives in a different
    layer (caller, validator, config loader); record where.
  - **modify** — change behavior here; sketch the new posture in
    one line.
  - **other** — something else (split the function, change the
    API, file a separate TODO, etc.). State what.

Don't sweep through and answer all of these in one session. The
TODO entry explicitly expects this to be *iterative with the test
work* — each silent-failure path uncovered while writing a test
becomes a decision here.

---

## Cross-cutting questions

Before deciding individual sites, the following policy questions
shape the answers. Resolve these first; they collapse a lot of
per-site decisions into one ruling each.

1. **Should CLI commands ever exit zero on partial failure?**
   Today: `update --all`, `rehash`, `modrinth export`,
   `curseforge export` all can exit 0 after logging "Download of X
   failed" mid-loop. Choices: (a) any failed item ⇒ exit non-zero
   at the end; (b) status code reflects whether the *operation*
   completed (e.g., export wrote a file, even if incomplete); (c)
   status quo, document explicitly.
   **Decision:** (c) status quo for now. Ideal end-state is
   differentiated exit codes (success / partial failure / total
   failure), but that requires its own design pass. Tracked in
   TODO.md. All items in the "Silent failure / swallow" section
   are deferred until that design lands.

2. **Where do errors go — stdout or stderr?**
   Today: nearly every `fmt.Println(err)` / `fmt.Printf` for
   errors goes to stdout. This breaks any pipeline that consumes
   structured output. Choices: (a) all error/warning output to
   stderr, all data output to stdout, no exceptions; (b) status
   quo; (c) hybrid (specific commands move first).
   **Decision:** _______

3. **Is library code allowed to call `os.Exit` / `panic`?**
   Today: `cmdshared/mcversion.go::CheckValid`,
   `core/indexfiles.go::markedFound`/`IsMetaFile`,
   `curseforge/request.go::decodeDefaultKey`, and others bail
   from library layers. Per the global `code-style.md` rule:
   *libraries surface errors by returning or raising; never call
   `exit` / `panic`.* Choices: (a) enforce the rule project-wide
   (return error, callers exit); (b) carve out exceptions and
   document them; (c) status quo.
   **Decision:** (a) — enforce project-wide. `CheckValid` fixed on
   `pr/error-handling-library-exits` (2026-05-15) as the first
   instance. Remaining sites tracked in the Library uses fatal
   exit section below.

4. **Standard pattern for cobra `Run` bodies.**
   Today: every command repeats `fmt.Println(err); os.Exit(1)`
   inline, ~90 sites across `cmd/`. Choices: (a) introduce a
   `cmdshared.Die(err)` / `cmdshared.Bail(format, args...)`
   helper; (b) switch to `RunE` returning error and let cobra
   handle exit; (c) status quo. Note: (b) is the idiomatic Go
   choice but is a wider refactor and changes some output
   formatting.
   **Decision:** _______

5. **Deferred / unchecked `Close()` on writers.**
   Today: `_ = f.Close()` is common, including on `*os.File`
   writers and `*zip.Writer` where a failed Close means lost
   data on disk. Choices: (a) every Close on a writer is
   checked, named-return + defer pattern; (b) explicit Close
   only on the success path, errors propagate; (c) status quo.
   **Decision:** _______

---

## Silent failure / swallow

The PR #384 family — error logged or ignored mid-loop, execution
continues, command exits zero. The original-source PR #384 should
be evaluated and merged (or re-implemented) as part of this work.

- `modrinth/export.go:104-119` — download-loop continues past
  `dl.Error != nil` (line 106-108) and past `RelIndexPath` failure
  (line 114-118, *literal `// TODO: exit(1)?` comment in source*).
  Why it matters: incomplete `.mrpack` shipped silently; this is
  PR #384's case.
  **Decision:** _______

- `modrinth/export.go:149-153` — `ReencodeURL` failure prints and
  falls back to the un-encoded URL. Why it matters: produces a
  manifest with an invalid URL the Modrinth launcher can't fetch.
  **Decision:** _______

- `modrinth/export.go:168-174` — `_ = cmdshared.AddToZip(...)`
  three times; bool return discarded. Why it matters: override
  file silently missing from the zip; user has no signal.
  **Decision:** _______

- `curseforge/export.go` (analogous `_ = AddToZip` site) — same
  pattern as above.
  **Decision:** _______

- `cmdshared/downloadutil.go:68-95` — `AddNonMetafileOverrides`
  loop: three `continue` branches (zip-create, file-open,
  io.Copy), each with a literal `// TODO: exit(1)?` comment.
  Why it matters: silently omits files from the export overrides;
  the upstream authors flagged the uncertainty themselves.
  **Decision:** _______

- `cmd/update.go:51,72,78,83,112-123` — `update --all` loops
  continue past `CheckUpdate`, `DoUpdate`, pin-check, and
  `RefreshFileWithHash` errors; some sites carry "do we return
  err code 1?" TODO comments. Why it matters: user can't tell
  which mods actually updated.
  **Decision:** _______

- `cmd/rehash.go:56-65` — download loop logs and continues
  before the next stage exits on its own errors. Why it matters:
  rehash reports success even when some files weren't hashed.
  **Decision:** _______

- `github/updater.go` (CheckUpdate loop, multiple continue
  sites) — per-mod failures logged, overall result returns nil.
  Why it matters: caller can't distinguish "no updates" from
  "some checks failed".
  **Decision:** _______

- `modrinth/updater.go` (CheckUpdate, multiple continue sites)
  — same shape as github.
  **Decision:** _______

- `core/download.go` (cache-corruption fallback path) — invalid
  cache entry removed and refetched without notifying the user.
  Why it matters: low-stakes, but masks systemic cache problems
  that should surface during diagnosis.
  **Decision:** _______

---

## Library uses fatal exit

Library code (anything outside `cmd/`) calling `os.Exit` or
`panic`. Conflicts with the global rule in `~/.claude/rules/
code-style.md`: *libraries surface errors by returning or
raising; never call `exit` / `panic` from library code.*

- `cmdshared/mcversion.go:26-34` — `CheckValid` calls
  `fmt.Println` + `os.Exit(1)` from a library method. Why it
  matters: callers can't unit-test or programmatically recover.
  **Decision:** modify — fixed on `pr/error-handling-library-exits`
  (2026-05-15). Now returns `error`; callers handle exit.

- `core/indexfiles.go:82,89` — `markedFound()` and `IsMetaFile()`
  on `indexFileMultipleAlias` panic on empty input. Why it
  matters: a zero-entry alias is "should not happen" today, but
  the panic is unrecoverable if the invariant ever breaks.
  **Decision:** leave — the empty-map case is unreachable by
  construction (`updateFileEntry` never stores an empty map).
  Changing the interface to return `(bool, error)` would cascade
  into all call sites for a condition that cannot occur. Added
  invariant comments to both panic sites on
  `pr/error-handling-library-exits` (2026-05-16) to document
  intent.

- `curseforge/request.go:27` — `panic("failed to read API key!")`
  on base64 decode failure. Why it matters: build-time-validated
  constant, but panicking from library init is a sharp edge.
  **Decision:** modify — fixed on `pr/error-handling-library-exits`
  (2026-05-16). `decodeDefaultKey` now returns `(string, error)`;
  both `makeGet`/`makePost` callers propagate it. Failure path not
  directly testable (constant is hardcoded); success path covered
  by existing `TestDecodeDefaultKey`.

- `core/pack.go:43` — `mustParseConstraint(...)` panics at init
  on bad constraint. Build-time only; arguably correct.
  **Decision:** leave — string literal `"~1.1"` cannot be wrong
  at runtime; same reasoning as `core/indexfiles.go` invariant
  panics.

- `modrinth/export.go:126` — `panic(err)` if `length-bytes`
  hash entry won't `ParseUint`. Why it matters: malformed entry
  takes down the whole export with a stack trace instead of a
  clear error.
  **Decision:** modify — fixed on `pr/error-handling-library-exits`
  (2026-05-16). Now prints a clear error and continues the loop,
  matching the `RelIndexPath` failure pattern above it. No test
  added — `Run` body is not unit-testable without export refactor;
  deferred to the cobra posture normalisation group.

- `cmd/serve.go:63` — `panic(fmt.Errorf(...))` from template
  exec inside a cobra `Run`. Acceptable location, unusual style.
  **Decision:** leave for now — cobra `Run` is an acceptable
  location; style will normalize when cobra posture group is
  tackled (cross-cutting question #4).

---

## Lost context

Error returned or printed without wrapping; root cause hard to
trace.

- `curseforge/import.go:46-86` — fallback chain tries multiple
  paths; accumulated "Also attempted..." messages obscure which
  attempt was actually the primary failure.
  **Decision:** leave — primary failure is the first line; "Also
  attempted" labels are clear enough. Restructuring would be
  churn in an untestable Run body.

- `cmd/init.go:82` — `CheckValid()` exits without the validation
  context (which version was bad, which manifest was checked).
  Folds into the library-fatal-exit question above.
  **Decision:** resolved by the `CheckValid` library-exit fix
  (2026-05-15) — the error now includes the bad version via `%q`,
  e.g. `"1.99.0" is not a valid Minecraft version`.

- `cmdshared/prompt.go:19` — `ReadString` error printed without
  context. Low-stakes (interactive prompt).
  **Decision:** leave — interactive prompt failure; adding context
  provides negligible value.

---

## Inconsistent CLI error posture

Different commands handle similar failures differently.
Whatever the answer to the "standard pattern" cross-cutting
question, this category gets normalized after that decision.

- `cmd/update.go` — same loop body mixes `fmt.Println; os.Exit(1)`
  and `fmt.Printf; continue`. Reader can't predict which errors
  are fatal without reading the code.
  **Decision:** _______

- `cmd/rehash.go:50-99` — early errors exit, mid-loop errors
  continue, late errors exit again. Same command, three
  postures.
  **Decision:** _______

- `cmd/pin.go`, `cmd/remove.go`, `cmd/init.go`, `cmd/list.go`,
  `cmd/refresh.go` — every error site is `fmt.Println(err);
  os.Exit(1)`. ~30+ sites across these files. Boilerplate, but
  consistent. Candidate for the `cmdshared.Die` helper if the
  cross-cutting question lands there.
  **Decision:** _______

- `migrate/loader.go:54,61,72,76` — `_ = updatePackToVersion(...)`
  discards bool failure; `os.Exit(0)` on "LiteLoader unable to
  update" exits clean despite not completing the action.
  **Decision:** _______

- `cmd/serve.go:99-102` — HTTP handler prints refresh error and
  serves stale data anyway. Client gets 200 with a possibly-
  stale response.
  **Decision:** _______

---

## Resource cleanup

Failed or unchecked `Close()` on writers, partial files on
error mid-write.

- `core/download.go:130,135,472-483` — `_ = file.Close()` on
  error paths during hash computation and import file moves.
  Why it matters: close errors on writers can mean truncated
  files on disk.
  **Decision:** _______

- `core/index.go:94,98,270-283` — `_ = f.Close()` in
  `UpdateIndexHash`; close return only checked on success path.
  Same risk shape.
  **Decision:** _______

- `core/pack.go:124,128,145-153` — same pattern on pack-file
  writes.
  **Decision:** _______

- `curseforge/export.go:151-168`, `modrinth/export.go:191-235`
  — multiple `_ = exp.Close(); _ = expFile.Close()` on error
  paths. Why it matters: zip writer not flushed, output file
  may be corrupted on disk while the command exits non-zero —
  user re-runs and overwrites, but a partial file may be left
  on disk if the second `Close` also fails.
  **Decision:** _______

- `cmdshared/downloadutil.go:80,87,93` — `_ = src.Close()` on
  read side. Lower stakes (reads), but inconsistent with
  writer policy.
  **Decision:** _______

- `cmd/serve.go:74,116,126,137` — `_, _ = w.Write(...)` in HTTP
  handlers. Client write failures swallowed; arguably acceptable
  for an HTTP responder (TCP will retry, client may have just
  disconnected) but worth a one-line "intentional" comment if
  so.
  **Decision:** _______

---

## Validation gap

Input validated at the wrong layer, or after work has begun.

- `cmdshared/mcversion.go:26-34` — also a validation-layering
  question: this validator lives in `cmdshared` but exits the
  process. Should be a plain `error`-returning validator called
  from the cobra layer.
  **Decision:** fixed — see Library uses fatal exit entry above.

- `cmd/list.go:44-48` — side parameter validated inline in the
  command body; could move to flag-parsing layer for
  consistency.
  **Decision:** leave — cosmetic refactor, no user-visible
  improvement.

---

## Other

Cases that don't fit the buckets above.

- `core/pack.go` (auto-migration site) — pack format migrated
  silently from 1.0.0 → 1.1.0 with no user notification. Why
  it matters: user sees a modified `pack.toml` they didn't
  ask for. **Verify line number before acting** — the audit's
  cited line may have drifted.
  **Decision:** leave — audit was wrong; line 62 already prints
  `"Automatically migrating pack to packwiz:1.1.0 format..."`.
  No silent migration.

- `migrate/loader.go:54-72` — `_ = updatePackToVersion(...)`
  loses the bool return in the loop; pack write proceeds even
  if the update step said "no".
  **Decision:** three sub-cases:
  - Line 54 (auto-update loop): bool IS checked (`if !... {
    continue }`). Audit was confused. Leave.
  - Line 72 (Forge/NeoForge explicit): bool discarded, write
    proceeds regardless. Harmless (same content written). Leave.
  - Line 80 (Fabric/Quilt explicit): `os.Exit(1)` when
    `updatePackToVersion` returns false (already on requested
    version). **Genuine bug** — "already at desired state" is
    success, not failure. Deferred: bring up as an upstream
    issue after `pr/testing` merges and we have standing as a
    contributor. Do not fix unilaterally.
  - Line 76 (LiteLoader `os.Exit(0)`): deferred pending
    exit-code design (cross-cutting question #1).

- `cmd/serve.go:99-102` — same site as above under cleanup;
  also fits here as "request succeeded but operation didn't".
  **Decision:** deferred with the Inconsistent CLI posture group
  (cross-cutting questions #2 and #4).

---

## PR framing

Every PR that touches error-handling behavior must include a note near
the top of the body:

> These changes haven't been discussed with the maintainer beforehand.
> If you have a different approach in mind or prefer to handle this
> differently, I'm happy to adjust to fit your requirements.

The maintainer may have undocumented design intent that conflicts with
changes that look obviously correct from the outside. Signaling openness
upfront reduces review friction.

---

## Notes and caveats

- Line numbers reflect the working tree at audit time
  (2026-05-14). Spot-check before acting; the file index above
  also captures the surrounding function names so finds remain
  locatable even after drift.
- Routine `if err != nil { return err }` returns from library
  functions are *not* listed here; they're already correct.
- Trivial `_ = viper.BindPFlag(...)` wiring in `cmd/*.go::init()`
  is not listed; those calls only fail in test/programming-error
  scenarios.
- HTTP `Response.Body.Close()` via `_ = ...` (e.g.,
  `core/download.go:167`) is idiomatic and not flagged.
- Sequencing per TODO.md: this work *depends on* the test work
  (PR #402 / follow-up rounds). Each silent-failure path
  uncovered while writing a test becomes a decision here. Do
  not try to drain this file in one pass.
