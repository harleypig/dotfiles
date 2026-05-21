# GitHub Actions Rules

**Version:** v1.0.0

This document defines normative agent behavior for monitoring and
resolving GitHub Actions CI runs, particularly in the context of pull
requests.

## Tool Detection

This rule applies only when GitHub Actions workflows are present in
the repository. The repository is considered to be using GitHub
Actions if at least one `.yml` or `.yaml` file exists under
`.github/workflows/`.

If that directory is absent or empty, skip all behavior in this
document — there are no CI runs to watch.

## After Creating a PR

Immediately after `gh pr create` succeeds, watch the triggered CI run
without waiting to be asked:

```bash
# Get the run ID that the new PR triggered
gh run list --limit 1

# Stream the run live
gh run watch <run-id> --exit-status
```

Do not proceed to merge discussion until the watch completes. Report
the outcome to the user — pass or fail — before doing anything else.

## On CI Pass

Report which jobs passed and confirm the PR is ready to merge. Do not
merge without explicit user approval (see `gh.md` Agent Rules).

## On CI Failure

1. **Fetch the failure log:**

   ```bash
   gh run view <run-id> --log-failed
   ```

2. **Diagnose the root cause.** Read the full output. Identify whether
   the failure is in a specific hook, test, compiler error, or
   infrastructure issue (missing tool, bad cache, etc.).

3. **Report to the user** — which job failed, what the error says, and
   the likely cause. Do this before touching any files.

4. **Propose a fix.** Describe concretely what you intend to change and
   why. Wait for the user to approve before making changes.

5. **Apply the fix** following normal pre-commit discipline (fix config
   → check config → commit — see `pre-commit.md`).

6. **Push to the PR branch** and re-watch:

   ```bash
   git push
   gh run list --limit 1   # get the new run ID
   gh run watch <new-run-id> --exit-status
   ```

7. **Repeat** until CI is green.

MUST NOT push fixes without user approval. MUST NOT merge with failing
CI. MUST NOT skip or bypass required status checks.

## Infrastructure vs. Code Failures

Distinguish between the two before proposing a fix:

- **Code failure** — test assertion, compile error, lint finding,
  formatter diff. Fix the source.
- **Infrastructure failure** — missing binary, network timeout,
  action version incompatibility, cache corruption. These often resolve
  on re-run; propose `gh run rerun <id>` before touching code.

When in doubt, show the raw log excerpt and ask the user.

## Useful Commands

```bash
# List recent runs (shows status at a glance)
gh run list --limit 5

# Full job/step breakdown for a run
gh run view <run-id>

# Failure output only (what to read first)
gh run view <run-id> --log-failed

# Full log for a specific job
gh run view <run-id> --job <job-id> --log

# Re-run failed jobs only (useful for flaky infra)
gh run rerun <run-id> --failed

# Re-run all jobs
gh run rerun <run-id>
```

## Agent Rules

- These rules apply ONLY when `.github/workflows/` contains at least
  one workflow file. Skip entirely if Actions are not configured.
- ALWAYS watch CI immediately after creating a PR — do not leave the
  user to discover results on their own.
- Report pass/fail outcome before asking what to do next.
- On failure: diagnose → report → propose fix → wait for approval.
- On success: confirm and invite the user to approve merge.
- Never merge a PR with failing required status checks.
- Prefer `gh run rerun --failed` over code changes for infrastructure
  failures (network, cache, missing tool on runner).
