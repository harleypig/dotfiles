---
name: pytest-patterns
description: Concrete pytest depth for Python — fixture design (scope, yield-teardown, factory-as-fixture, conftest hierarchy), mocking discipline (patch where it's used, AsyncMock vs MagicMock, spec/autospec, mock at boundaries not internals), real-dependency-over-mock for DBs, freezing time/randomness, parametrize with ids and failure cases, pytest.raises(match=...), branch coverage, and pytest-xdist isolation. Use when writing or improving Python tests and you want the deeper how beyond "use pytest" and the testing.md bar. Triggers: "write tests for this", "pytest fixture", "mock this", "freeze time in a test", "parametrize", "why is this test flaky", "async test".
---

# pytest-patterns

**Version:** v1.0.0

The deep *how* for Python tests with pytest. **The bar comes from
`testing.md`** (cover success **and** failure paths; a regression test per
bug) — this skill
is the technique to meet it well. Generic Python; for DB-layer test setup see
the **sqlalchemy-patterns** skill, for the bash analog see **bats-setup**.

## Fixtures

- **Scope deliberately** — `function` (default, isolated) unless setup is
  expensive and safely shared (`module`/`session`). A shared-scope fixture
  that holds mutable state is a flakiness source.
- **Teardown via `yield`** — set up, `yield` the value, tear down after:

  ```python
  @pytest.fixture
  def client():
      c = make_client()
      yield c
      c.close()
  ```

- **Factory-as-fixture** — when tests need *many* objects with tweaks, yield a
  *callable* instead of one object:

  ```python
  @pytest.fixture
  def make_user():
      def _make(**over):
          return User(email="a@b.com", **over)
      return _make
  ```

- **conftest hierarchy** — shared fixtures in `tests/conftest.py`;
  area-specific ones in `tests/<area>/conftest.py`. Don't import fixtures; let
  pytest discover them.

## Mocking discipline

- **Patch where it's *used*, not where it's defined** —
  `patch("app.svc.client")` (the module that calls it), not
  `patch("app.client")`. The #1 mocking bug.
- **`AsyncMock` for async, `MagicMock` for sync** — mixing raises `TypeError`;
  an un-awaited `MagicMock` "passes" while testing nothing.
- **`spec=`/`autospec=True`** so the mock rejects calls the real object can't
  make — an unspecced mock accepts anything and hides drift.
- **Mock at boundaries, not internals** — patch the HTTP/clock/filesystem
  edge, not your own functions. Tests that assert *implementation* break on
  every
  refactor; tests that assert *behavior* don't.
- **Prefer a real dependency when it's cheap** — for the database, a real test
  DB with per-test transaction rollback beats a mocked session (you test real
  SQL/constraints). Session setup: **sqlalchemy-patterns**.

## Freezing time and randomness

Patch at the **use site**, and keep the constructor working with `side_effect`
so non-frozen calls still build values:

```python
with patch("app.svc.datetime") as m:
    m.now.return_value = FIXED
    m.side_effect = lambda *a, **k: datetime(*a, **k)
```

A test that depends on real `now()`/`random()` is flaky by construction — pin
them.

## Parametrize — including the failure cases

Use `ids=` for readable output, and parametrize the **failure/edge** inputs
too (that's the `testing.md` bar, not just the happy path):

```python
@pytest.mark.parametrize("raw,ok", [
    ("a@b.com", True), ("@b.com", False), ("", False),
], ids=["valid", "no-local", "empty"])
def test_email(raw, ok):
    assert is_valid(raw) is ok
```

## Exceptions, coverage, parallelism

- **Assert the error, not just that one occurs** — `pytest.raises(ValueError,
  match=r"not found")`; the `match` guards against the *wrong* error passing.
- **Branch coverage > line coverage** — `--cov-branch`. 100% lines with
  untested branches is false confidence (and misses the failure paths).
- **Parallel with `pytest-xdist`** — give each worker its own external state
  (e.g. DB name keyed by `worker_id`) or parallel runs corrupt each other.

## Provenance

Adapted from the mining census — `claude-plugins` python `pytest-patterns`
(implementation detail reused: fixture/conftest scoping, the patch-where-used
rule, the frozen-time `side_effect` recipe, xdist worker isolation). Stripped
of its dependency-injector/SQLAlchemy specifics (those live in the relevant
skills). See `SOURCE.md`.
