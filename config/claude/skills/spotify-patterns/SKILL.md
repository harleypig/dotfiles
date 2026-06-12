---
name: spotify-patterns
description: Concrete Spotify Web API implementation recipes — proactive token refresh (survive the 1-hour expiry), track-relinking-aware Library operations (use linked_from for saved/contains/remove), pagination + set-based dedup, a 429/Retry-After + exponential-backoff wrapper, playlist-creation strategies (by-artist / by-theme / from-song-list), and playlist cover-art generation (SVG→PNG, a11y contrast, ugc-image-upload). Use when writing or refactoring Spotify integration code and you want the deeper how beyond the conventions in rules/spotify.md. Triggers: "refresh the Spotify token", "why does a saved track show as unsaved", "track relinking", "build a playlist from a list", "handle Spotify rate limits / 429", "generate a playlist cover".
---

# Spotify Patterns

**Version:** v1.0.0

Concrete, adaptable recipes for the Spotify Web API. **`rules/spotify.md` is
the source of truth for the policy** (auth + PKCE, scopes, deprecated
endpoints, relinking, SDK/EME, compliance) — read it first; this skill only
adds the deeper *how*. To audit existing Spotify code against the policy, use
the **spotify-audit** skill.

Examples are Python-leaning (the dominant Spotify-app language), but the
patterns are language-agnostic — the relinking and token-refresh recipes apply
equally to a TypeScript frontend.

## When to reach for this

Implementing auth/token handling, library or playlist operations,
search-driven playlist building, rate-limit handling, or cover-art upload —
and the one-liners in `rules/spotify.md` aren't enough detail.

## Proactive token refresh

A session must outlive the **one-hour** access token. Store the expiry as an
**absolute** deadline and refresh from the stored refresh token *before* a call
when it is near expiry — don't wait for the 401.

```python
import time

# Refresh when within this many seconds of expiry.
_SKEW = 60

async def fresh_access_token(session) -> str:
    token = session["access_token"]
    expires_at = session.get("token_expires_at")
    if expires_at is None or time.time() < expires_at - _SKEW:
        return token

    refresh = session.get("refresh_token")
    if not refresh:
        return token  # can't refresh; let a downstream 401 handle it

    data = await spotify_refresh(refresh)  # grant_type=refresh_token
    new = data.get("access_token")
    if not new:
        return token  # refresh failed; fall back, do not raise

    session["access_token"] = new
    # Spotify usually does NOT rotate the refresh token; keep a new one if sent.
    if data.get("refresh_token"):
        session["refresh_token"] = data["refresh_token"]
    session["token_expires_at"] = time.time() + data.get("expires_in", 3600)
    return new
```

Store `token_expires_at` as an absolute epoch (not the raw `expires_in`). A
refresh *failure* returns the stale token rather than raising, so the helper
keeps the same failure profile as a plain "get token" and the existing 401 path
still handles a truly-dead session.

## Relinking-aware Library operations

Spotify serves a recording under different track ids per market. The id from
playback / a relinked read is the **playable** one; the id the track is
**saved** under is the original, in `linked_from`. For *every* Library or
playlist write/membership op — saved-tracks `contains`, save, remove, and
playlist-track removal — use the original id, or a saved track reads back as
unsaved.

```python
def library_id(track: dict) -> str:
    # Original id for Library ops; falls back to the id when not relinked.
    return (track.get("linked_from") or {}).get("id") or track["id"]

# saved-state check uses the ORIGINAL id, not track["id"]
saved = await get("/me/tracks/contains", ids=library_id(track))
```

## Pagination + order-preserving dedup

Never assume a list fits one page; loop until `next` is null. When merging
several searches into a playlist, dedup ids while preserving order.

```python
async def all_items(url: str) -> list[dict]:
    items = []
    while url:
        page = await get(url)
        items.extend(page["items"])
        url = page.get("next")  # absolute next-page url, or None
    return items

unique_uris = list(dict.fromkeys(uris))  # dedup, insertion order kept
```

## 429 / Retry-After + backoff

On HTTP 429, wait the `Retry-After` seconds, then exponential backoff. Never
retry in a tight loop.

```python
async def with_retry(call, *, attempts=5):
    delay = 1
    resp = None
    for _ in range(attempts):
        resp = await call()
        if resp.status_code != 429:
            return resp
        wait = int(resp.headers.get("Retry-After", delay))
        await sleep(wait)
        delay *= 2  # 1 → 2 → 4 → 8 …
    return resp  # caller handles the final 429
```

## Playlist-creation strategies

Build the uri list, dedup, then add (≤100 uris per request — paginate).

- **By artist** — the artist's top tracks (`/artists/{id}/top-tracks`).
- **By theme / mood** — several search queries, merged and deduped.
- **From a song list** — search `"title artist"` per row, take the top hit.

There is no **recommendation-seeded** strategy here: `/recommendations` is
deprecated for new apps (see `rules/spotify.md`).

```python
async def from_song_list(rows: list[tuple[str, str]]) -> list[str]:
    uris = []
    for title, artist in rows:
        r = await get("/search", q=f"{title} {artist}", type="track", limit=1)
        hits = r["tracks"]["items"]
        if hits:
            uris.append(hits[0]["uri"])
    return list(dict.fromkeys(uris))
```

## Cover-art generation + upload

Render a themed SVG (mind a11y contrast), rasterize, then upload — requires the
**`ugc-image-upload`** scope.

```python
import cairosvg

png = cairosvg.svg2png(
    bytestring=svg.encode(), output_width=640, output_height=640
)
jpeg_b64 = to_jpeg_base64(png)  # Spotify wants base64 JPEG, ≤ 256 KB
await put(
    f"/playlists/{pid}/images",
    body=jpeg_b64,
    headers={"Content-Type": "image/jpeg"},
)
```

Pick text/background colors with a legible contrast ratio (WCAG AA on the cover
text). Without `ugc-image-upload` the upload returns 401 — fall back to a "set
this image manually" prompt rather than failing silently.
