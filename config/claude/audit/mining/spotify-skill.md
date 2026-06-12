# Mining matrix — `fabioc-aloha/spotify-skill`

Part of the mining census (`../mining-census.md` has the disposition key and
the cross-repo CANDIDATE backlog). Apache-2.0. Round 2026-06-12. v0.9.0.
Third-party (13★, 0 open issues, 56 commits). Mined because pigify is the
first Spotify repo and the *Idea sources* registry had no Spotify coverage.

We **adapt ideas only, never vendor code**. Authoritative policy comes from
Spotify's official docs — the repo's `references/` are stale (predate the
2024-11-27 deprecations; omit PKCE / the implicit-grant ban).

Disposition column: **ADOPTED** = folded into this round's
`rules/spotify.md` and `spotify-audit`; **CANDIDATE** = deferred to the
`spotify-patterns` backlog; a split row landed its cross-cutting *pattern*
and deferred its *recipe*. Each reason leads with **Done →** (what landed
where) or **Deferred →**.

| item | type | disp. | reason |
|------|------|-------|--------|
| `spotify-api/SKILL.md` | skill | ADOPTED | **Done →** `rules/spotify.md` (Endpoints, Scopes) + `spotify-audit`: endpoint/scope inventory + patterns |
| `references/api_reference.md` | reference | ADOPTED | **Done →** rule (Endpoints, Rate limiting): endpoint/error/rate-limit tables. **Stale** — cross-checked vs official docs |
| `references/authentication_guide.md` | reference | ADOPTED | **Done →** rule (Auth, Tokens): token lifecycle; we **added** the PKCE / implicit-ban it omitted |
| `references/COVER_ART_LLM_GUIDE.md` | reference | CANDIDATE | **Deferred →** `spotify-patterns`: cover-art (SVG→PNG, a11y contrast) |
| `spotify-api/scripts/*.py` | code | ADOPTED (pattern) + CANDIDATE (recipes) | **Done →** rule (Tokens): auto-refresh pattern. **Deferred →** `spotify-patterns`: 5 playlist strategies, 40+ method inventory. No code copied. |
| `get_refresh_token.py` | script | ADOPTED (rule) + CANDIDATE (helper) | **Done →** rule (Auth): Auth-Code on `127.0.0.1`. **Deferred →** `spotify-patterns`: the manual refresh-token-capture helper |
| `agent_skills_spec.md` | spec | SKIP | Agent Skills spec — informs skill *shape*, not Spotify policy |
| `tools/{init,validate,package}_skill.py` | tooling | SKIP | generic skill scaffolding, unrelated to Spotify |
| `examples/`, `Guide/` | examples/docs | SKIP | generic skill-authoring tutorials |
| housekeeping (`CHANGELOG`, `RELEASE_NOTES`, `*.backup`, `CustomGPT/`, …) | misc | SKIP | packaging artifacts |

**Adopted →** `rules/spotify.md` + `spotify-audit` skill (this round).
**CANDIDATE backlog →** `spotify-patterns` skill (cover-art generation,
playlist-creation strategies, pagination/dedup, error-code mapping) — tracked
in `TODO.md`; lower priority but genuinely useful (would have pre-empted the
relinking / token-refresh bugs that motivated this round).
