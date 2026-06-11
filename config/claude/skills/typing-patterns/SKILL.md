---
name: typing-patterns
description: Concrete Python typing depth — fix type errors instead of silencing them, TypedDict (NotRequired/Required/total) over dict[str, Any], Protocol (structural) vs ABC, generics (TypeVar bound/constraints, the 3.12 class[T] syntax, ParamSpec for decorators), Literal, overload, narrowing (TypeGuard/isinstance/assert), Sequence/Mapping over list/dict in signatures, NewType, Self, Annotated, and using cast/Any only as a last resort. Use when adding or fixing Python type annotations and you want the deeper how beyond "run mypy" and the python.md policy. Triggers: "type this properly", "fix this type error without type:ignore", "TypedDict", "Protocol", "generic class/function", "overload", "narrow this type", "what's the right annotation".
---

# typing-patterns

**Version:** v1.0.0

The deep *how* for Python type annotations. **The policy comes from
`python.md`** (mypy/pyright; never a bare `# type: ignore` — justify with
`[code]` + a reason) — this skill is what to write *instead* of reaching for
the escape hatch.

## Fix the error, don't silence it

A type error is usually a real one. Before `# type: ignore`, ask what the
checker actually caught — most often a missing `None` check, a too-wide type,
or a real bug:

```python
# not:  return db.get(id)  # type: ignore
user = db.get(id)
if user is None:
    raise NotFoundError(id)
return user                 # now genuinely User, no ignore
```

`# type: ignore[code]` with a reason is the rare, documented last resort
(`python.md`) — not the first move.

## Shapes over `dict[str, Any]`

`dict[str, Any]` defeats the checker. Name the shape with **`TypedDict`**, and
control optionality per-field:

```python
from typing import TypedDict, NotRequired

class UserCreate(TypedDict):
    email: str
    name: str
    age: NotRequired[int]          # optional key; or `total=False` for all
```

Now `data["emial"]` and a missing `email` are caught.

## Structural typing — `Protocol` over ABC

When you need "anything with this shape," a `Protocol` types it without
forcing inheritance:

```python
from typing import Protocol

class Readable(Protocol):
    def read(self) -> str: ...

def load(src: Readable) -> str:    # any object with read() qualifies
    return src.read()
```

## Generics

- **`TypeVar` with `bound`/constraints** — keep generic functions honest:
  `T = TypeVar("T", bound=BaseModel)` (subtypes only);
  `S = TypeVar("S", str, bytes)` (one of those two).
- **3.12 syntax** — `class Repository[T]:` /
  `def first[T](xs: list[T]) -> T:`; cleaner than the `Generic[T]` base.
- **`ParamSpec`** — preserve a wrapped function's *exact* signature through a
  decorator: `def deco(f: Callable[P, R]) -> Callable[P, R]:` with
  `*args: P.args, **kwargs: P.kwargs`.

## Precision: `Literal`, `overload`, narrowing

- **`Literal`** for exact values — `Status = Literal["pending", "shipped"]`;
  the checker rejects `"shpped"`.
- **`@overload`** when the return type depends on the argument type — declare
  each signature, then one implementation.
- **Narrowing** — `isinstance`/`assert`, and **`TypeGuard`** for custom
  predicates:

  ```python
  def all_str(xs: list[object]) -> TypeGuard[list[str]]:
      return all(isinstance(x, str) for x in xs)
  ```

## Signatures and nominal types

- **`Sequence`/`Mapping`/`Iterable` over `list`/`dict`** in *parameters* —
  accept the read-only contract; return concrete types.
- **`NewType`** to stop primitive mix-ups — `UserId = NewType("UserId", int)`
  so a bare `int` won't pass where a `UserId` is wanted.
- **`Self`** for chainable/builder methods; **`Annotated`** to attach metadata
  (validators, units) to a type.

## Last resorts

`cast(...)` and `Any` switch the checker *off* for that value — `Any` then
spreads silently downstream. Prefer real validation (e.g. a pydantic
`TypeAdapter`) to assert a shape at runtime; if you must `cast`, comment why
it's safe.

## Provenance

Adapted **idea-level** from the mining census — `claude-plugins` python
`typing-patterns`. The recipes are general Python typing knowledge rendered in
house style; no upstream implementation reused. See `SOURCE.md`.
