---
paths:
  - "**/*.py"
---

# SQLAlchemy Rules

**Version:** v1.0.0

Conventions for SQLAlchemy (2.0 style). Builds on `python.md`. Schema
changes for persistent databases go through Alembic (`alembic.md`).

For concrete recipes beyond these conventions — model mixins, custom
`TypeDecorator` storage, eager-loading to kill N+1, the session unit-of-work,
and the tricky Alembic migration recipes — invoke the **sqlalchemy-patterns**
skill.

## Detection

Active when `sqlalchemy` is a dependency (e.g. in `pyproject.toml`).

## Models (2.0 declarative)

- Use the modern typed style: `DeclarativeBase`, `Mapped[...]`, and
  `mapped_column(...)`. No legacy `Column`/`declarative_base()`.
- Factor shared columns into mixins (e.g. a UUID primary key, created/
  updated timestamps); compose them onto models.
- Define relationships with `back_populates` and an explicit `order_by`
  where order matters. Add `UniqueConstraint` / indexes deliberately.
- Encapsulate custom storage (e.g. a UUID/`GUID` `TypeDecorator`) in one
  place and reuse it.

## Engines and sessions

- Create the engine(s) once; use a `sessionmaker`. Expose sessions to the
  app via a dependency that yields one session per unit of work and
  closes it (`finally: session.close()`).
- A single logical database = one engine. If an app spans multiple
  databases, give each its own engine/base and treat cross-database
  references as **logical** ids (no enforced cross-database foreign keys).

## SQLite specifics

- Foreign keys are off by default — enable them per connection with
  `PRAGMA foreign_keys=ON` via a `connect` event listener (sqlite only).
- Use `connect_args={"check_same_thread": False}` for threaded servers.

## Schema management

- For **persistent** schemas (user data), use Alembic migrations, not
  `create_all` (see `alembic.md`).
- `create_all` is acceptable only for **regenerable/throwaway** schemas
  (caches, reseedable content, tests).

## Agent Behavior

- Write models in the typed 2.0 style with complete annotations.
- Add the SQLite FK pragma listener whenever SQLite is a target.
- Do not add `create_all` for a database that holds data you must keep —
  add a migration instead.
