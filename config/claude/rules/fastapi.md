---
paths:
  - "**/*.py"
---

# FastAPI Rules

**Version:** v1.0.0

Conventions for FastAPI services. Builds on the Python rules
(`python.md`) — type hints and pydantic are assumed.

For concrete recipes beyond these conventions — Pydantic v2 DTO splits,
validators, the native-`Depends` repository pattern, `AppError`→
`HTTPException` mapping — invoke the **fastapi-patterns** skill.

## Detection

Active when `fastapi` is a dependency (e.g. in `pyproject.toml`), or a
`FastAPI()` app is defined.

## Structure

- One `FastAPI` app assembled in a `main` module; mount feature routers
  with `app.include_router(...)`.
- Group endpoints into `APIRouter`s by domain, one module per area
  (e.g. `api/content.py`). Keep `main` thin.
- Startup/shutdown work (DB init, migrations, seeding) goes in a
  `lifespan` context manager, not import-time side effects.

## Request / response

- Every endpoint declares a `response_model` (a pydantic model). Define
  request/response schemas explicitly; do not return ORM objects without
  a schema mediating the boundary.
- Validate input with pydantic; trust validated values internally
  (`python.md`).
- Inject shared resources (DB sessions, the current user, settings) with
  `Depends(...)`. A session dependency yields one unit of work per
  request and closes it.

## Errors

- A service is an executable boundary: raise `HTTPException` with an
  appropriate status code at the API edge (e.g. 404 for missing
  resources). Do not leak raw driver/ORM exceptions to clients.
- Keep business/library code raising plain exceptions; translate to HTTP
  only at the endpoint/dependency layer.

## Cross-cutting

- Configure CORS via `CORSMiddleware` from settings (allowed origins),
  not hard-coded.
- Configuration comes from the settings layer (`pydantic-settings`), not
  scattered `os.environ` reads.

## Agent Behavior

- New endpoints: complete type annotations, a `response_model`, and at
  least one test via `TestClient` (success and the failure/404 path).
- Surface errors as `HTTPException`; never return a 200 with an error
  payload.
- Keep routers cohesive; do not pile unrelated endpoints into one module.
