# Mining matrix — `fabioc-aloha/spotify-skill`

Part of the mining census (`../mining-census.md` has the disposition key and
the cross-repo CANDIDATE backlog). Apache-2.0. Round 2026-06-12. v0.9.0.
Third-party (13★, 0 open issues, 56 commits). Mined because pigify is the
first Spotify repo and the *Idea sources* registry had no Spotify coverage.

We **adapt ideas only, never vendor code**. Authoritative policy comes from
Spotify's official docs — the repo's `references/` are stale (predate the
2024-11-27 deprecations; omit PKCE / the implicit-grant ban).

| item | type | disp. | reason |
|------|------|-------|--------|
| `spotify-api/SKILL.md` | skill | ADOPT-idea | endpoint/scope inventory + patterns → `rules/spotify.md`, `spotify-audit` |
| `references/api_reference.md` | reference | ADOPT-idea | endpoint/error/rate-limit tables — **stale**, cross-check vs official |
| `references/authentication_guide.md` | reference | ADOPT-idea | token lifecycle; **gap:** no PKCE / implicit warning (we add) |
| `references/COVER_ART_LLM_GUIDE.md` | reference | CANDIDATE | cover-art (SVG→PNG, a11y contrast) → future `spotify-patterns` |
| `spotify-api/scripts/*.py` | code | SKIP code / ADOPT-idea | 40+ methods, 5 playlist strategies, auto-refresh pattern (ideas only) |
| `get_refresh_token.py` | script | ADOPT-idea | Auth-Code flow on `127.0.0.1`, manual refresh-token capture (concept) |
| `agent_skills_spec.md` | spec | SKIP | Agent Skills spec — informs skill *shape*, not Spotify policy |
| `tools/{init,validate,package}_skill.py` | tooling | SKIP | generic skill scaffolding, unrelated to Spotify |
| `examples/`, `Guide/` | examples/docs | SKIP | generic skill-authoring tutorials |
| housekeeping (`CHANGELOG`, `RELEASE_NOTES`, `*.backup`, `CustomGPT/`, …) | misc | SKIP | packaging artifacts |

**Adopted →** `rules/spotify.md` + `spotify-audit` skill (this round).
**CANDIDATE backlog →** `spotify-patterns` skill (cover-art generation,
playlist-creation strategies, pagination/dedup, error-code mapping) — tracked
in `TODO.md`; lower priority but genuinely useful (would have pre-empted the
relinking / token-refresh bugs that motivated this round).
