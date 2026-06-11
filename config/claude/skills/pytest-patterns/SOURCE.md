# Source / provenance

## Tracked source (implementation detail used)

| Upstream repo | Path | License | SHA at adaptation |
|---------------|------|---------|-------------------|
| `ruslan-korneev/claude-plugins` | `plugins/python/skills/pytest-patterns/` (SKILL + references) | MIT | `62a0c1c` (full: `62a0c1cf8da56e54de9e550753e3cf783e7ee391`) |

Details reused: fixture/conftest scoping guidance, the "patch where it's used"
rule, the frozen-time `side_effect` recipe, and the pytest-xdist
worker-isolation scheme.

Adaptation date: 2026-06-11.

## Deliberate divergences

- **Stripped the stack specifics** — the upstream is heavily
  dependency-injector + SQLAlchemy flavored (`FakeSessionMaker`, session
  rollback fixtures); those belong in `fastapi-patterns` /
  `sqlalchemy-patterns` (the layering principle, `EXTENDING.md`). This skill
  stays generic pytest.
- **Bar comes from `testing.md`** (success + failure paths,
  regression-per-bug); the skill is technique, not policy.

## Check the tracked source for new ideas

```bash
gh api "repos/ruslan-korneev/claude-plugins/commits?path=plugins/python/skills/pytest-patterns&per_page=1" \
  --jq '.[0] | "\(.sha[0:7])  \(.commit.committer.date)"'
```

If the SHA differs, skim for new recipes; bump the SHA/date here and the
**Version** in `SKILL.md`.
