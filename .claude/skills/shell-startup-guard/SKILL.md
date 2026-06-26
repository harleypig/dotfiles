---
name: shell-startup-guard
description: Detect and resolve un-managed (out-of-band) changes to this dotfiles repo's `shell-startup` script — the kind a tool installer makes by writing into ~/.bashrc / ~/.bash_profile, which symlink to `shell-startup` (e.g. the grok/xAI CLI installer re-adding its PATH+completion block). Compares `shell-startup` against a committed `shell-startup.md5` checksum; on drift, shows what changed since the last blessed state and offers to approve, restore, relocate the stray block into a proper module/wrapper, or defer. Use during ship-pr's first half (before commit) and at merge-finalization, or whenever you suspect `shell-startup` was modified outside the repo's own edits.
---

# shell-startup Guard

**Version:** v1.0.0

`shell-startup` is the orchestrator that `~/.bash_profile` and `~/.bashrc`
symlink to. Tool installers that "add themselves to your shell profile" write
to those symlinks — landing **inside `shell-startup`** — without going through
git or the agent. The grok (xAI) CLI installer is the known offender: its
config-file target is hardcoded to `~/.bashrc` (no override; `GROK_BIN_DIR`
only moves the binaries), and it re-adds its `>>> grok installer >>>` block
whenever the marker is absent.

This skill is the tripwire. A committed **`shell-startup.md5`** at the repo
root records the blessed checksum of `shell-startup`; the skill compares the
two, and on a mismatch walks you through resolving it.

The judgment-free mechanics live in **`scripts/guard.sh`** (this directory).
The model owns the decision about *what the drift is* and *how to resolve it*.

## When this runs

- **ship-pr Step 1 (first half), before commit** — the primary gate. Wired in
  `.claude/WORKFLOW.md`. Catching drift here lets the decision land cleanly in
  the PR's commits.
- **Merge-time finalization (ship-pr Step 4.5)** — a backstop, in case an
  installer ran between commit and merge.
- **On demand** — whenever you suspect `shell-startup` changed out of band.

The agent never has to *remember* to re-bless after its **own** edits: a
PostToolUse hook (`config/claude/hooks/md5-guard.py`) regenerates
`shell-startup.md5` automatically whenever the agent edits `shell-startup`
through the Edit/Write tools. Only **un-managed** changes (an installer, a
manual edit outside the tools) leave the checksum stale — which is exactly
what this skill catches.

## Procedure

### 1. Check

```bash
.claude/skills/shell-startup-guard/scripts/guard.sh check
```

- **Exit 0 (clean):** nothing to do — continue the workflow.
- **Exit 2 (no baseline / error):** `shell-startup.md5` is missing. If the
  current `shell-startup` is correct, create the baseline with `bless` (below)
  and commit it. Otherwise investigate before proceeding.
- **Exit 1 (drift):** continue to step 2.

### 2. Show the drift

```bash
.claude/skills/shell-startup-guard/scripts/guard.sh diff
```

This diffs the working-tree `shell-startup` against its content at the **last
commit that touched `shell-startup.md5`** (the last blessed state). Because
`shell-startup` and its checksum always change together, that commit is the
correct baseline — and going back to it captures **all** drift accumulated
since, even across several commits.

Read the diff and classify the change before prompting the user:

- An **installer block** (e.g. `>>> grok installer >>>`) re-added out of band.
- A **manual / unknown edit** someone made directly to `shell-startup`.

### 3. Stop and ask the user

Present the diff and offer these resolutions (do **not** pick one silently):

1. **Approve** — the change is wanted as-is. Re-bless and stage both files:

   ```bash
   .claude/skills/shell-startup-guard/scripts/guard.sh bless
   ```

   Then `git add shell-startup shell-startup.md5`.

2. **Restore** — discard the drift; put `shell-startup` back to its last
   blessed content:

   ```bash
   .claude/skills/shell-startup-guard/scripts/guard.sh restore
   ```

3. **Relocate** — the stray block belongs in the environment but not *here*.
   Move it out of `shell-startup` into the right home, then **restore**
   `shell-startup` (step 2) so the orchestrator stays clean:

   - **`config/shell-startup/<tool>`** — a guarded module, for config that
     must load into every interactive shell (PATH, completion, aliases). This
     is what the grok block became (`config/shell-startup/grok`); if the grok
     installer re-added its block, relocating just means restoring, since the
     module already supplies it.
   - **`bin/<tool>`** — an on-demand wrapper (`set the env, then exec <tool>
     "$@"`), for tool-only env that should **not** pollute every shell. See
     the "Move env-polluting shell-startup setup into bin wrappers" pattern in
     `TODO.md`.

   After moving, re-run `check` to confirm clean.

4. **Defer** — leave it for the next PR. Take no action; the checksum stays
   mismatched and the guard will flag it again next run. Tell the user it is
   deferred so it is not mistaken for resolved.

### 4. Verify

After approve / restore / relocate:

```bash
.claude/skills/shell-startup-guard/scripts/guard.sh check
```

It should report **clean** (defer is the one outcome that stays in drift, by
design).

## Notes

- **md5 is for drift detection, not security.** A non-adversarial checksum is
  enough to notice an installer rewrote the file; md5sum is universally
  available. (sha256 would work too — md5 was the explicit choice for
  simplicity.)
- **Always commit `shell-startup` and `shell-startup.md5` together.** The
  baseline-diff logic depends on them moving in lockstep. The PostToolUse
  auto-bless hook keeps agent edits in step; the `bless` subcommand does the
  same for manual ones.
