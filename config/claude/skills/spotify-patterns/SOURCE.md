# Source

The **spotify-patterns** skill adapts **ideas only — no code** — from one repo,
with the highest-value recipes (proactive token refresh, relinking-aware
Library ops) written from first-hand implementation in the pigify project.

## Adapted (ideas/structure)

- **`fabioc-aloha/spotify-skill`** — <https://github.com/fabioc-aloha/spotify-skill>
  - License: **Apache-2.0**. Author: Fabio C. (`fabioc-aloha`).
  - Mined: 2026-06-12 (v0.9.0), in the same audit round as `rules/spotify.md`
    and the `spotify-audit` skill (see those artifacts' SOURCE / the mining
    census `audit/mining/spotify-skill.md`).
  - What we took (concepts only, our own code): the playlist-creation
    *strategies* (by-artist / by-theme / from-song-list), the cover-art
    SVG→PNG → `ugc-image-upload` pipeline, set-based dedup, and the
    pagination-loop pattern.
  - **Not taken:** its recommendation-seeded playlist strategy — it depends on
    the now-deprecated `/recommendations` endpoint (see `rules/spotify.md`).

## First-hand

- The **proactive token refresh** and **relinking-aware Library ops** recipes
  were written from the implementations done in the pigify project (where both
  had already caused bugs), not adapted from the source repo.

## Authoritative factual sources (policy, no code)

- See `rules/spotify.md` and `skills/spotify-audit/SOURCE.md` for the Spotify
  official-docs references (track relinking, rate limiting, the 2024-11-27
  deprecations, Web Playback SDK).
