---
paths:
  - "**/*.py"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# Spotify Web API Rules

**Version:** v1.0.0

Conventions for integrating the **Spotify Web API** and **Web Playback SDK**.
This rule is the policy/reference; to audit an existing codebase against it,
run the **spotify-audit** skill. Concrete recipes (cover-art generation,
playlist-building strategies, pagination/dedup helpers) are planned for a
**spotify-patterns** skill (tracked in the dotfiles `TODO.md`).

## Detection

Active **only** when the codebase actually integrates Spotify — a `spotipy`
(or other Spotify client) dependency, the Web Playback SDK
(`@spotify/web-playback-sdk` or the `sdk.scdn.co` script), or direct calls to
`api.spotify.com` / `accounts.spotify.com`. The path globs above are a coarse
gate (any JS/TS/Python file); this section is the real one — the rule is
dormant in a repo that does not touch Spotify.

## Authentication

- **User data → Authorization Code with PKCE.** A confidential server-side
  backend may use plain Authorization Code; SPAs, native, and mobile clients
  use PKCE (`response_type=code`, `code_challenge_method=S256`, a stored
  `code_verifier`).
- **Public catalogue only → Client Credentials** (no user context, and it
  returns no refresh token).
- **Never the Implicit Grant** (`response_type=token`) — deprecated; it leaks
  the access token in the URL fragment. Migrate legacy implicit flows to PKCE.
- **The client secret is server-side only** — never in client-side code or a
  committed `.env`. Prefer file/secret-manager sourcing (`*_FILE`, Vault, a
  cloud secrets manager) over plain environment variables in production.
- **Redirect URIs must be HTTPS**, the sole exception being
  `http://127.0.0.1` for local development. Do **not** use `http://localhost`
  or wildcard URIs — Spotify rejects them.

## Tokens

- Access tokens expire after **3600s (one hour)**; the refresh token does not
  expire unless the user revokes it. Client Credentials issues no refresh
  token.
- **Refresh proactively** — renew from the stored refresh token at/just
  before expiry rather than waiting for the first 401, so a session survives
  the one-hour boundary. Persist a rotated refresh token if the response
  carries one (the Authorization Code flow usually does not rotate it).
- Store tokens securely (a server-side session or an encrypted store), never
  on the client.

## Scopes

- **Request only the scopes the features actually use** — never ask for broad
  scopes preemptively; it weakens both consent and least-privilege.
- Common scopes: `user-read-private`, `user-read-email`, `user-library-read`,
  `user-library-modify`, `playlist-read-private`, `playlist-modify-private`,
  `playlist-modify-public`, `user-read-playback-state`,
  `user-modify-playback-state`, `streaming` (Web Playback SDK),
  `user-top-read`, `user-read-recently-played`.
- `ugc-image-upload` is **required** to upload a playlist cover image —
  without it the upload returns 401.

## Endpoints

- **Prefer the current endpoint over its legacy sibling:**
  `/playlists/{id}/items` over `/playlists/{id}/tracks`, and the unified
  *Save/Remove Items to Library* endpoints over the deprecated per-type
  `PUT`/`DELETE /me/tracks` (Save/Remove Tracks).
- **Deprecated for new apps (announced 2024-11-27)** — do not build on these;
  new apps receive 404 and there is **no official replacement**: **Audio
  Features** (`/audio-features`), **Audio Analysis**, **Recommendations**
  (`/recommendations`) and available-genre-seeds, **Related Artists**
  (`/artists/{id}/related-artists`), 30-second preview URLs in multi-get
  responses, and algorithmic / editorial-playlist access. Treat a *new*
  dependency on these as a defect — flag it; do **not** auto-rewrite, since no
  drop-in replacement exists.
- **Batch and paginate.** Per-request id caps **vary by endpoint** (e.g.
  `/tracks` and `/me/tracks*` cap at 20; some library endpoints at 50; a
  playlist add/remove at 100) — check each endpoint's documented maximum
  rather than assuming one number. Always paginate list reads (commonly
  50/page); never assume a collection fits in a single page.

## Rate limiting

- On **HTTP 429**, read the **`Retry-After`** header (seconds) and wait that
  long before retrying; then apply **exponential backoff** (1→2→4→8s). Never
  retry immediately or in a tight loop.

## Track relinking

- Spotify serves the same recording under different track ids per market.
  Pass a `market` parameter (an ISO-3166-1 alpha-2 code, or `from_token` for
  the user's country) so reads return a playable track; a relinked response
  carries `is_playable` and a **`linked_from`** object describing the
  **original** track.
- **Library and playlist write/membership operations MUST use the original id
  from `linked_from`** — saving/removing in *Your Music* and the saved-tracks
  membership check, and removing a track from a playlist. Using the relinked
  top-level id "will likely return an error or unexpected result." This is a
  *silent* correctness bug: a track the user has saved reads back as not
  saved.

## Web Playback SDK (in-browser playback)

- Requires **Spotify Premium**, the **`streaming`** scope, and a **secure
  context (HTTPS)**; it relies on EME/Widevine DRM.
- The SDK runs in a **cross-origin iframe** (`sdk.scdn.co`); the embedding
  page must **delegate `encrypted-media` and `autoplay`** to it via
  `Permissions-Policy` (the default `self` is not enough), or `connect()`
  fails.
- Audio needs a **user gesture**; after a device transfer some browsers (iOS)
  will not autoplay. Commercial use requires Spotify's written approval.

## Compliance (Developer Terms)

- **Attribute** Spotify content in the UI.
- **Do not cache** Spotify content beyond immediate use.
- **Do not train** machine-learning / AI models on Spotify data.

## Verifying against current docs

Spotify's surface shifts (the 2024-11-27 deprecations; the move to unified
library endpoints), and third-party guides lag it. Treat **Spotify's official
documentation as authoritative**. Context7's `/websites/developer_spotify_web-api`
is a convenient live source when available — but it is an optional aid, not a
dependency: this rule and the **spotify-audit** skill stand on their own
without it.

## Agent Behavior

- When adding or changing Spotify integration code, follow the auth, token,
  scope, endpoint, and relinking rules above — in particular proactive token
  refresh and `linked_from`-for-library-operations.
- To audit an existing Spotify codebase for alignment, run the
  **spotify-audit** skill.
- Treat Spotify's official docs as authoritative; older tutorials and
  third-party guides predate the 2024-11-27 deprecations and the PKCE
  guidance.
