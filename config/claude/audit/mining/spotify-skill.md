# Mining matrix — `fabioc-aloha/spotify-skill`

Part of the mining census (`../mining-census.md` has the disposition key and
the cross-repo CANDIDATE backlog). Apache-2.0. Round 2026-06-12. v0.9.0.
Third-party (13★, 0 open issues, 56 commits). Mined because pigify is the
first Spotify repo and the *Idea sources* registry had no Spotify coverage.

We **adapt ideas only, never vendor code**. Authoritative policy comes from
Spotify's official docs — the repo's `references/` are stale (predate the
2024-11-27 deprecations; omit PKCE / the implicit-grant ban).

Disposition column: **ADOPTED** = folded into `rules/spotify.md`,
`spotify-audit`, or `spotify-patterns`; **SKIP** = not used. Each reason leads
with **Done →**, naming where it landed. All ADOPT-idea recipes have now
shipped — `spotify-patterns` was built 2026-06-12, so nothing remains deferred.

| item | type | disp. | reason |
|------|------|-------|--------|
| `spotify-api/SKILL.md` | skill | ADOPTED | **Done →** `rules/spotify.md` (Endpoints, Scopes) + `spotify-audit`: endpoint/scope inventory + patterns |
| `references/api_reference.md` | reference | ADOPTED | **Done →** rule (Endpoints, Rate limiting): endpoint/error/rate-limit tables. **Stale** — cross-checked vs official docs |
| `references/authentication_guide.md` | reference | ADOPTED | **Done →** rule (Auth, Tokens): token lifecycle; we **added** the PKCE / implicit-ban it omitted |
| `references/COVER_ART_LLM_GUIDE.md` | reference | ADOPTED | **Done →** `spotify-patterns`: cover-art (SVG→PNG, a11y contrast, `ugc-image-upload`) |
| `spotify-api/scripts/*.py` | code | ADOPTED | **Done →** rule (Tokens): auto-refresh; `spotify-patterns`: playlist strategies, pagination/dedup. (40+ method inventory not enumerated wholesale.) No code copied. |
| `get_refresh_token.py` | script | ADOPTED | **Done →** rule (Auth): Auth-Code on `127.0.0.1`; `spotify-patterns`: the token-refresh recipe. (A standalone interactive capture CLI wasn't built — low value.) |
| `agent_skills_spec.md` | spec | SKIP | Agent Skills spec — informs skill *shape*, not Spotify policy |
| `tools/{init,validate,package}_skill.py` | tooling | SKIP | generic skill scaffolding, unrelated to Spotify |
| `examples/`, `Guide/` | examples/docs | SKIP | generic skill-authoring tutorials |
| housekeeping (`CHANGELOG`, `RELEASE_NOTES`, `*.backup`, `CustomGPT/`, …) | misc | SKIP | packaging artifacts |

**Adopted →** `rules/spotify.md` + `spotify-audit` (2026-06-12), and
`spotify-patterns` (token refresh, relinking, pagination/dedup, 429 wrapper,
playlist strategies, cover-art). The full ADOPT set has shipped — having these
recipes earlier would have pre-empted the relinking / token-refresh bugs that
motivated the Spotify category.

**Follow-up (TODO).** Re-mine **Spotify's own official documentation** — the
**Concepts**, **Tutorials**, and **How-Tos** sections — end to end for further
material to fold into `rules/spotify.md` and the skills. This round mined the
third-party repo plus the *building-with-AI* page and targeted official pages
(track relinking, scopes, Web Playback SDK, the Nov-2024 changes), not those
sections in full.
