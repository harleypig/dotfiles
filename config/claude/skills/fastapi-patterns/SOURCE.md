# Source / provenance

This skill is **adapted, not vendored**. The table below lists only repos
whose **implementation details** were actually used (so there is something to
track for updates). Repos that contributed *ideas only* — concepts we liked
but whose code we did not reuse — are **not** listed here; they live in the
general idea-source registry (`SETUP-AUDIT.md` → "Idea sources"), per policy:
cite a source per-artifact only when details, not just the idea, were taken.

## Tracked sources (implementation detail used)

| Upstream repo            | Path drawn from                                  | License | SHA at adaptation |
|--------------------------|--------------------------------------------------|---------|-------------------|
| `ruslan-korneev/claude-plugins` | `plugins/fastapi/skills/fastapi-patterns/` (SKILL + `references/dto.md`, `repository.md`, `exceptions.md`) | MIT | `62a0c1c` (full: `62a0c1cf8da56e54de9e550753e3cf783e7ee391`) |

Details reused: the `BaseDTO`/`ConfigDict` field set, the Create/Read/Update
split, the `AppError` hierarchy + handler-registration shape, and the generic
`BaseRepository` CRUD shape.

Adaptation date: 2026-06-11.

## Idea-only influences (NOT tracked here)

Consulted for concepts but **no implementation reused** — recorded in the
idea-source registry, not vendored:

- `fastapi/fastapi` official agent skill — FastAPI best-practice *concepts*
  (Annotated params, return-type serialization, async-vs-sync). General
  framework idiom; snippets here are our own.
- `rafaelkamimura/claude-tools` `fastapi-clean-architecture` — layering idea
  only.

## Deliberate divergences from the tracked source

Re-apply this judgment when reviewing upstream changes:

- **Dropped `dependency-injector`.** Upstream wires a DI container; this repo
  uses FastAPI-native `Depends` with a session-per-request dependency
  (`rules/fastapi.md`). Translate, don't import.
- **Repository `flush`es, never `commit`s** — transaction boundary kept at the
  service / request layer (the upstream variant commits inside the repo).
- **Kept only the value-add depth** beyond `rules/fastapi.md` /
  `rules/sqlalchemy.md`; persistence patterns live in the sqlalchemy-patterns
  skill, not here.

## Check the tracked source for new ideas

```bash
gh api "repos/ruslan-korneev/claude-plugins/commits?path=plugins/fastapi/skills/fastapi-patterns&per_page=1" \
  --jq '.[0] | "\(.sha[0:7])  \(.commit.committer.date)"'
```

If the SHA differs from the table, skim the upstream diff for *new patterns*
worth folding in, then bump the SHA/date here and the **Version** in
`SKILL.md`. This is a judgment pass (adopt good ideas in house idiom), not a
mechanical merge.
