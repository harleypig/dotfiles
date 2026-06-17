---
name: release-tag
description: Cut a release version tag (vX.Y.Z) at a merge commit, following the repo's declared tagging method, then watch the release workflow. Use when the user wants to tag/cut/ship a release — "tag the release", "cut a release", "cut frontend/v0.2.0", "release-tag this", "bump the version and tag", "tag v1.2.0". Reads the repo's `.claude/CONVENTIONS.md` "Versioning & tagging" to determine the method (repo-level `vX.Y.Z` vs per-subdir `<component>/vX.Y.Z`), decides the bump (alpha-loose under v0, strict once v1+), creates the annotated tag(s) at the merge commit, pushes (with confirmation, since it publishes), and watches the build/publish. For a repo you don't own, follows ITS convention. This is ship-pr's Step 6 as a standalone skill.
---

# Release tag

**Version:** v1.0.0

Cut a **release version tag** that follows the repo's declared tagging method.
The *format* (`vX.Y.Z` = semver) and *tag hygiene* (annotated, at the merge
commit, never moved) live in **`rules/git.md` › Versioning & tags** — this
skill is the **procedure** that applies them.

Pushing a release tag usually **triggers the build/publish workflow**, so it
is **outward-facing**: confirm before pushing, and never move a published tag.

## When to use

The user wants to tag/release a finished, **merged** change — "cut a release",
"tag `frontend/v0.2.0`", "bump and tag". Commonly invoked as `ship-pr` Step 6,
but works standalone for an already-merged commit.

**Skip entirely** when the change ships **no artifact** (docs / CI / compose /
meta-only) or the repo doesn't tag releases.

## Procedure

### 1. Determine the method

Read the repo's `.claude/CONVENTIONS.md` "Versioning & tagging" for the
declared method (catalog in `rules/git.md`):

- **`repo`** → one `vX.Y.Z` stream for the whole repo.
- **`subdir`** → `<component>/vX.Y.Z` per deployable subtree
  (e.g. `backend/v*`, `frontend/v*`).

If the repo **declares no method**, infer from existing tags (`git tag -l`)
and **confirm with the user** before tagging. If the needed method isn't in
the `rules/git.md` catalog, that's a config gap — surface it and **add the
method there first** (don't invent a one-off).

**Foreign / forked repo you don't own:** ignore our catalog — follow **its**
convention (tag history, release docs, CI triggers). Match what they do.

### 2. Choose the stream(s)

Tag **only a stream whose shipped artifact changed**:

- `repo` → the single `v*` stream (if anything shipped).
- `subdir` → only the component(s) whose subtree changed — a frontend-only
  change tags `frontend/v*`, not `backend/v*`; a change to both tags each.

Skip docs / CI / compose / meta-only changes — they ship nothing.

### 3. Decide the bump

Find the latest tag on each chosen stream, then bump per `rules/git.md`
semver — remembering the **alpha vs stable** distinction:

```bash
git describe --tags --match '<prefix>v*' --abbrev=0   # latest on the stream
```

- **No tag yet** → seed the first release (commonly `v0.1.0`).
- **`v0.y.z` (alpha)** → loose: `y` for a meaningful addition, `z` otherwise;
  breaking changes need no major bump.
- **`v1.y.z`+ (stable)** → strict: a **breaking change bumps the major**; `y`
  = backward-compatible feature; `z` = backward-compatible fix.
- The **`0 → 1`** jump is a major decision (as weighty as `1 → 2`) — only on
  the user's explicit say-so.
- **Confirm the bump with the user** whenever it's beyond an obvious patch.

### 4. Cut the tag(s)

On the default branch at the **merge commit** (the squash-merge HEAD), cut an
**annotated** tag per the method's pattern:

```bash
git checkout "$DEFAULT" && git pull --ff-only
git tag -a "<prefix>vX.Y.Z" -m "<component> vX.Y.Z — <summary>" "$(git rev-parse HEAD)"
```

- `repo` → `vX.Y.Z`.
- `subdir` → `<component>/vX.Y.Z` (e.g. `frontend/v0.2.0`).

### 5. Push and watch

**Confirm with the user, then** push the tag(s) explicitly:

```bash
git push origin <tag> [<tag2> ...]
```

Pushing is the release trigger. Watch the release workflow to green
(`rules/github-actions.md`) and verify the artifact published (e.g. the image
tags via the registry). Report what released.

A GitHub **Release object** (release notes) is a separate, optional step
(`gh release create <tag> ...`) — do it only if the repo's convention wants
release notes; the tag alone is what builds/deploys.

## Guardrails

- **Outward-facing:** pushing a tag publishes/deploys — confirm before push.
- **Immutable tags:** never move / delete / re-point a pushed tag; a mistake
  gets a **new** tag.
- **Annotated, at the merge commit** (`rules/git.md` tag hygiene).
- **Only artifact-shipping changes** get a tag — skip docs/CI/meta-only.
- **`0 → 1`** is a deliberate, user-approved decision, not a default.
- **Foreign repos:** follow their convention, not ours.
