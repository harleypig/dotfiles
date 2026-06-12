---
name: spotify-audit
description: Audit a Spotify Web API / Web Playback SDK codebase for alignment with current Spotify best practices and Developer Terms. Checks auth (Authorization Code + PKCE, no implicit grant, secret handling, redirect URIs), proactive token refresh, scope minimization, deprecated endpoints (post-2024-11-27 + legacy library/playlist paths), rate-limit/429 handling, track relinking (use linked_from for Library ops), and Web Playback SDK/EME prerequisites. Use for "/spotify-audit", "audit our Spotify code", "is our Spotify integration aligned/compliant", "check Spotify API usage", "find deprecated Spotify endpoints", or before shipping Spotify-facing changes.
---

# Spotify Audit

**Version:** v1.0.0

Audit a codebase that integrates the Spotify Web API and/or Web Playback SDK
for alignment with current Spotify practice and the Developer Terms. This
skill is the **checker**; the policy it enforces lives in **`rules/spotify.md`**
(the source of truth — every finding cites a clause there). It produces a
severity-grouped findings report and does **not** auto-rewrite: some
deprecations have no drop-in replacement and need a human decision.

## Read first

- **`rules/spotify.md`** — the authoritative policy (auth, tokens, scopes,
  endpoints, rate limiting, relinking, SDK/EME, compliance).

## Scope to the repo

Detect the Spotify surface first, then audit only what exists:

- The auth / OAuth flow — login, callback, and token storage/refresh.
- The HTTP client / service layer that calls `api.spotify.com`.
- The requested **scope list** (in the authorize URL or login config).
- Any Web Playback SDK usage (`sdk.scdn.co`, the `streaming` scope, and the
  embedding page's `Permissions-Policy` / CSP headers).

## Checklist — signal → why → fix

Record each hit with `file:line`. Spotify's API shifts, so verify
endpoint/deprecation status against the official docs (Context7's
`/websites/developer_spotify_web-api` is a convenient live source if
available — optional, not required).

### Auth

- `response_type=token` / implicit-grant flow → deprecated; token leaks in
  the URL → migrate to Authorization Code + PKCE.
- Client Credentials used for `/me/*` (user-scoped) data → 401/403, no user
  context → use Authorization Code (+ PKCE).
- Client secret in client-side code, the frontend bundle, or a committed
  `.env` → secret leak → server-side only; `*_FILE`/secrets manager; `.env`
  gitignored.
- Redirect URI on `http://` other than exactly `http://127.0.0.1`, or
  `http://localhost`, or a wildcard → rejected/insecure → HTTPS, or
  `http://127.0.0.1` for dev only.

### Tokens

- No token-refresh path, or no expiry check before calls → the session breaks
  at the one-hour mark → refresh proactively from the stored refresh token.

### Scopes

- Scope list broader than the features in use (e.g. `*-modify-*` with no
  write calls) → least-privilege violation → request only what is used.
- Cover-image upload without `ugc-image-upload` → 401 → add the scope.

### Endpoints

- Calls to `/audio-features`, `/audio-analysis`, `/recommendations`,
  `available-genre-seeds`, `/artists/{id}/related-artists` → deprecated
  2024-11-27, 404 for new apps, no replacement → remove (flag; do not
  auto-fix).
- `/playlists/{id}/tracks` instead of `/playlists/{id}/items`, or the
  deprecated per-type `PUT`/`DELETE /me/tracks` instead of the unified
  *Save/Remove Items to Library* endpoints → legacy path → use the current
  one.
- Multi-get / add / remove that ignores the per-endpoint id cap (varies —
  often 20, sometimes 50, 100 for a playlist add/remove), or list reads that
  do not paginate → truncated or rejected requests → batch to the endpoint's
  cap and paginate.

### Rate limiting

- HTTP layer with no 429 / `Retry-After` branch, or a retry loop with no
  delay → throttling / ban risk → honor `Retry-After`, then exponential
  backoff.

### Track relinking

- The saved-tracks membership check, *Your Music* save/remove, or a
  playlist-track removal using the **root** track id when relinking is in play
  (a `linked_from` is present, or a `market` is passed) → wrong or
  not-found track; saved tracks read back as unsaved → use `linked_from.id`
  (the original).
- Catalogue/library reads with no `market` (or `from_token`) where
  playability matters → unplayable tracks surfaced → pass `market`.

### Web Playback SDK / EME

- SDK used without the `streaming` scope, without Premium gating, with the
  iframe host page not delegating `encrypted-media` / `autoplay` via
  `Permissions-Policy`, or served over non-HTTPS → `connect()` fails silently
  → add the scope, gate on Premium, delegate EME/autoplay, serve over HTTPS.

### Compliance

- Long-term caching/persistence of Spotify metadata, missing Spotify
  attribution in the UI, or feeding Spotify data into model training →
  Developer-Terms violation → cache only for immediate use, attribute, never
  train.

## Report

Group findings by severity and cite `file:line` + the `rules/spotify.md`
clause each violates:

- **Critical** — secret leak, implicit grant, a compliance violation.
- **High** — new dependency on a deprecated endpoint, missing token refresh,
  relinking misuse (a silent data bug), missing 429 handling.
- **Medium** — over-broad scopes, a legacy `/tracks` or `/me/tracks` path, a
  missing `market`, un-paginated reads.
- **Info** — SDK/EME prerequisites to verify manually (Premium, HTTPS).

State what was checked and what is clean — never imply coverage you did not
run. Recommend fixes; do **not** auto-rewrite deprecated calls that have no
replacement (flag those for a human decision).
