---
name: fastapi-patterns
description: Concrete FastAPI + Pydantic v2 implementation recipes — DTO Create/Read/Update splits, validators, computed fields, the native-Depends dependency/session pattern, response_model/return-type serialization, the typed repository pattern, and AppError→HTTPException mapping. Use when writing or refactoring FastAPI endpoints, Pydantic DTOs/schemas, service or repository layers, dependency wiring, or API error handling and you want the deeper patterns beyond the conventions in rules/fastapi.md. Triggers: "write a DTO", "Pydantic model for this endpoint", "repository pattern", "structure this FastAPI module", "map exceptions to HTTP", "partial update schema".
---

# FastAPI Patterns

**Version:** v1.0.0

Concrete, copy-adaptable recipes for FastAPI services with Pydantic v2 and
SQLAlchemy 2.0. **`rules/fastapi.md` is the source of truth for the
conventions** (one `response_model` per endpoint, `lifespan` for startup,
`HTTPException` at the edge, `pydantic-settings` for config) — read it first;
this skill only adds the deeper *how*. For the persistence layer see the
**sqlalchemy-patterns** skill; this skill stops at the repository boundary.

This skill is **idiom-specific**: it uses FastAPI-native `Depends(...)` with a
session-per-request dependency. It deliberately does **not** use the
`dependency-injector` library that some upstream sources lean on (see
`SOURCE.md`) — match the surrounding code.

## When to reach for this

Writing endpoints, request/response schemas, a service or repository layer, or
API-level error handling — and the one-liners in `rules/fastapi.md` aren't
enough detail.

## DTOs (Pydantic v2)

Base config once; every DTO inherits ORM-mode and whitespace stripping:

```python
from pydantic import BaseModel, ConfigDict

class BaseDTO(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,      # build DTOs straight from ORM objects
        populate_by_name=True,     # accept field name or alias
        str_strip_whitespace=True,
    )
```

**Create / Read / Update split.** Create omits server-set fields (id,
timestamps); Read includes them; Update makes every field optional and is
applied with `exclude_unset` so absent keys are left untouched:

```python
class UserCreate(BaseDTO):
    email: str
    name: str

class UserRead(BaseDTO):
    id: int
    email: str
    name: str

class UserUpdate(BaseDTO):
    email: str | None = None
    name: str | None = None

# in the service: patch only the fields actually sent
data = payload.model_dump(exclude_unset=True)
for field, value in data.items():
    setattr(user, field, value)
```

**Field vs model validators.** `@field_validator` for one field;
`@model_validator(mode="after")` for cross-field rules:

```python
from pydantic import field_validator, model_validator

class SignUp(BaseDTO):
    email: str
    password: str
    password_confirm: str

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.lower()

    @model_validator(mode="after")
    def passwords_match(self) -> "SignUp":
        if self.password != self.password_confirm:
            raise ValueError("passwords do not match")
        return self
```

**Computed and nested.** `@computed_field` derives values at serialization;
nest Read DTOs directly:

```python
from pydantic import computed_field

class OrderRead(BaseDTO):
    id: int
    items: list[OrderItemRead]

    @computed_field
    @property
    def total(self) -> float:
        return sum(i.price * i.qty for i in self.items)
```

**Enums** serialize for free when the member type is `str`:

```python
from enum import Enum

class OrderStatus(str, Enum):
    pending = "pending"
    shipped = "shipped"

class OrderRead(BaseDTO):
    status: OrderStatus
```

**camelCase at the boundary, snake_case inside** — alias the field and dump
`by_alias` only at the JSON edge:

```python
from pydantic import Field

class Profile(BaseDTO):
    full_name: str = Field(alias="fullName")
```

## Dependencies and serialization (native FastAPI)

**`Annotated` dependency aliases** — declare once, reuse everywhere; the type
survives outside FastAPI too:

```python
from typing import Annotated
from fastapi import Depends

SessionDep = Annotated[Session, Depends(get_session)]
CurrentUserDep = Annotated[User, Depends(get_current_user)]

@router.get("/me")
async def me(user: CurrentUserDep) -> UserRead:
    return user
```

**Return type drives serialization.** Annotate the return; Pydantic v2
serializes in Rust and documents the schema automatically. Reach for
`response_model` only when the wire shape must differ from the returned object
(e.g. filtering secret fields).

**`async def` only when you `await` async I/O.** A plain `def` path operation
runs in the threadpool, so blocking work there won't stall the event loop —
but blocking calls inside an `async def` will. Pick the keyword by what the
body actually does.

**Router-level metadata** — set `prefix`/`tags`/`dependencies` on the
`APIRouter`, not on every `include_router(...)` call, so they live next to the
endpoints they describe.

## Repository pattern

A small generic base carries the typed CRUD; concrete repos add domain
queries. The session arrives by constructor injection (from a `Depends`
session dependency). **The repository `flush`es; it does not `commit`** — the
transaction boundary belongs to the service or the request dependency, so a
unit of work can span several repositories:

```python
from collections.abc import Sequence
from typing import Generic, TypeVar
from sqlalchemy import select
from sqlalchemy.orm import Session

ModelT = TypeVar("ModelT")

class BaseRepository(Generic[ModelT]):
    def __init__(self, session: Session, model: type[ModelT]) -> None:
        self._session = session
        self._model = model

    def get(self, id_: int) -> ModelT | None:
        return self._session.get(self._model, id_)

    def list(self) -> Sequence[ModelT]:
        return self._session.execute(select(self._model)).scalars().all()

    def add(self, entity: ModelT) -> ModelT:
        self._session.add(entity)
        self._session.flush()   # assign PKs/defaults; no commit here
        return entity
```

Concrete repos add the domain-specific reads and prevent N+1 with eager
loading:

```python
from sqlalchemy.orm import selectinload

class UserRepository(BaseRepository[User]):
    def __init__(self, session: SessionDep) -> None:
        super().__init__(session, User)

    def by_email(self, email: str) -> User | None:
        stmt = select(User).where(User.email == email)
        return self._session.execute(stmt).scalar_one_or_none()

    def with_orders(self, id_: int) -> User | None:
        stmt = (
            select(User)
            .where(User.id == id_)
            .options(selectinload(User.orders))
        )
        return self._session.execute(stmt).scalar_one_or_none()
```

(SQLAlchemy 2.0 model/session specifics — `Mapped`, the session dependency,
the SQLite FK pragma — live in the **sqlalchemy-patterns** skill and
`rules/sqlalchemy.md`.)

## Exception → HTTP mapping

Raise meaning-bearing errors in services; translate to HTTP once, at the edge,
with a registered handler — so business code stays free of `HTTPException`:

```python
# errors.py
class AppError(Exception):
    status_code = 500
    detail = "Internal server error"

    def __init__(self, detail: str | None = None) -> None:
        if detail is not None:
            self.detail = detail

class NotFoundError(AppError):
    status_code = 404
    detail = "Resource not found"

class ConflictError(AppError):
    status_code = 409
    detail = "Resource already exists"
```

```python
# wire once, in the app factory / lifespan setup
from fastapi import Request
from fastapi.responses import JSONResponse

async def handle_app_error(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code,
                        content={"detail": exc.detail})

app.add_exception_handler(AppError, handle_app_error)
```

Services then express intent without knowing about HTTP:

```python
def get_user(self, id_: int) -> User:
    user = self._repo.get(id_)
    if user is None:
        raise NotFoundError(f"user {id_} not found")
    return user
```

This is the depth behind the rule's "translate to HTTP only at the
endpoint/dependency layer" — a handler is the clean alternative to a
`try/except HTTPException` in every endpoint.

## Troubleshooting

When an endpoint misbehaves in a way that doesn't reduce to obvious logic — a
schema that won't validate, a response serializing wrong, a type that looks
right but isn't — **run the `qa-check` skill** before deep-diving. Its format
(`ruff format`), lint (`ruff check`), and type-check pass surfaces the usual
culprits (a mis-typed `Mapped`, a DTO field that doesn't match the model, an
un-awaited coroutine) faster than reading the traceback. Fix what it finds,
then resume.

## Provenance

Adapted from upstream sources (ideas drawn, re-rendered in this repo's native
idiom), not vendored. See `SOURCE.md` for repos, SHAs, and the upstream-check
procedure.
