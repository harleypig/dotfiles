# Source / provenance

This skill is **adapted, not vendored**. Per policy, the table lists only
repos whose **implementation details** were reused. Idea-only influences are
recorded in the general idea-source registry (`SETUP-AUDIT.md` → "Idea
sources"), not here.

## Tracked sources (implementation detail used)

| Upstream repo            | Path drawn from                                  | License | SHA at adaptation |
|--------------------------|--------------------------------------------------|---------|-------------------|
| `ruslan-korneev/claude-plugins` | `plugins/fastapi/skills/alembic-patterns/` (SKILL + `references/enum-handling.md`) | MIT | `62a0c1c` (full: `62a0c1cf8da56e54de9e550753e3cf783e7ee391`) |

Details reused: the Alembic recipes — enum create/drop lifecycle with
`checkfirst`, data-backfill-before-NOT-NULL, SQLite `render_as_batch` /
`batch_alter_table`, and downgrade FK/dependency ordering.

Adaptation date: 2026-06-11.

## Our own / general idiom (not from a specific repo)

The model and session sections (mixins, `TypeDecorator`/`GUID`, relationship
config, the session-per-request unit of work, `selectinload` vs `joinedload`)
are this repo's own conventions (`rules/sqlalchemy.md`) plus standard
SQLAlchemy 2.0 idiom — no specific upstream tracked for them.

## Check the tracked source for new ideas

```bash
gh api "repos/ruslan-korneev/claude-plugins/commits?path=plugins/fastapi/skills/alembic-patterns&per_page=1" \
  --jq '.[0] | "\(.sha[0:7])  \(.commit.committer.date)"'
```

If the SHA differs from the table, skim the diff for new migration recipes
worth folding in, then bump the SHA/date here and the **Version** in
`SKILL.md`. Judgment pass, not a mechanical merge.
