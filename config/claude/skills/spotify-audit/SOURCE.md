# Source

The **spotify-audit** skill and its companion `rules/spotify.md` adapt
**ideas and structure only — no code** — from one repo, with all factual
policy grounded in Spotify's official documentation.

## Adapted (ideas/structure)

- **`fabioc-aloha/spotify-skill`** — <https://github.com/fabioc-aloha/spotify-skill>
  - License: **Apache-2.0**. Author: Fabio C. (`fabioc-aloha`).
  - Mined: shallow clone, 2026-06-12 (v0.9.0).
  - What we took: the *concept* of a packaged Spotify skill; its
    endpoint / scope / error-handling inventory; the auto-refresh-before-call
    pattern; the `ugc-image-upload`→401 insight; and the cover-art /
    playlist-strategy capabilities (noted as future `spotify-patterns` work).
    We wrote our own policy text and audit checklist from scratch.
  - Lineage: that repo in turn builds on **Anthropic PBC**'s Agent Skills
    system (Apache-2.0).
  - **Caveat:** its `spotify-api/references/` predate Spotify's 2024-11-27 API
    deprecations and omit PKCE / the implicit-grant ban, so we treat Spotify's
    official docs as authoritative wherever they conflict.

## Authoritative factual sources (policy, no code)

- Building with AI — <https://developer.spotify.com/documentation/web-api/tutorials/building-with-ai>
- Track relinking — <https://developer.spotify.com/documentation/web-api/concepts/track-relinking>
- Web Playback SDK — <https://developer.spotify.com/documentation/web-playback-sdk>
- Nov 2024 Web API changes — <https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api>
- Live reference (optional): Context7 `/websites/developer_spotify_web-api`
