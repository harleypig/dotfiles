---
name: terraform-e2e-patterns
description: Concrete recipes for gated APPLY-mode Terraform e2e tests — native terraform test with command = apply against real, ephemeral infrastructure. The which-framework-for-which-target matrix (plan-only vs TF_ACC vs apply-mode vs Terratest), a worked apply-mode .tftest.hcl with a test-target allow-list validation, teardown guarantees (reverse-order auto-destroy, test_cleanup warnings, trap + reaper backstops), and the opt-in CI safety procedure (workflow_dispatch/schedule, stored secrets, environment protection — never the default gate). Use when standing up, writing, or reviewing e2e tests that create real resources. Triggers - "e2e terraform test", "apply-mode terraform test", "test this module against real infrastructure", "integration test for real", "gated apply in CI", "test teardown", "reaper for orphaned test resources", "ephemeral test resources".
---

# terraform-e2e-patterns

**Version:** v1.0.0

The deep *how* for **e2e-testing Terraform against real infrastructure** —
native `terraform test` in **apply mode**, opt-in, gated, and torn down. The
bar comes from `testing.md` (success and failure paths); conventions/CLI from
`terraform.md`. This skill owns the ground **between** its two siblings, and
references rather than duplicates them:

- **tftest-patterns** — plan-only unit tests (`command = plan` +
  `mock_provider`), the credential-free default gate. Recipes for `assert`,
  `expect_failures`, and mocks live there.
- **terraform-provider-patterns** — provider acceptance in Go
  (`terraform-plugin-testing`, `TF_ACC`, `CheckDestroy`), for a provider you
  own; lives in the provider's repo and covers provider-internals.
- **This skill** — applying real (ephemeral) resources through modules and
  root-config compositions and asserting on **real state**: the applied
  wiring plan-only tests can't prove, without re-testing provider internals.

## Which framework for which target

| Target | Framework | Lang | Teardown |
|--------|-----------|------|----------|
| module/config units, validation rules | plan-only `terraform test` (**tftest-patterns**) | HCL | nothing created |
| provider internals you own | `terraform-plugin-testing` + `TF_ACC` (**terraform-provider-patterns**) | Go | auto apply→destroy + `CheckDestroy` |
| **applied module composition — this skill's default** | native `terraform test`, `command = apply` | HCL | auto-destroy at end of file, reverse order |
| e2e needing out-of-band asserts (SSH/dig/HTTP) | Terratest — **only** where native can't assert | Go | `defer destroy` |

Prefer native apply-mode: it is HCL (no second language), auto-destroys, and
reads like the configs it tests. Reach for Terratest only when an assertion
genuinely can't be expressed in HCL against state/outputs.

## Apply-mode fundamentals

- A `run` block's `command` **defaults to `apply`** — plan-only is the
  explicit choice. In an e2e file, write `command = apply` anyway: the reader
  should never have to remember the default to know the file creates infra.
- Real providers and real credentials (from the environment) — no
  `mock_provider`. Everything the run creates exists and costs until
  destroyed.
- `run` blocks execute **sequentially by default**, top to bottom — build
  progressive scenarios in order (create → extend → assert). Terraform 1.12+
  can parallelize independent runs (`test { parallel = true }`); leave it off
  when ordering *is* the scenario.
- Test state is **ephemeral** — held for the file's execution and destroyed
  at the end; nothing persists into the module's real state or backend.

## Recipe — gated apply-mode test

The **allow-list validation lives in the configuration under test** (a
`.tftest.hcl` can only *set* variables, not validate them). The e2e config
declares the guard; every test file must pass it:

```hcl
# e2e config (the composition under test) — variables.tf
variable "test_domain" {
  description = "e2e target; must be a designated test domain"
  type        = string

  validation {
    condition     = contains(["harleypig.dev", "harleydev.com"], var.test_domain)
    error_message = "test_domain must be a designated test domain, never live infra."
  }
}
```

```hcl
# e2e/<layer>/composition.tftest.hcl
variables {
  test_domain = "harleypig.dev"
}

run "create_composition" {
  command = apply

  assert {
    condition     = module.thing.id != ""
    error_message = "applied resource has no real id"
  }
}

run "extend_composition" {
  command = apply

  # sequential: builds on create_composition's applied state
  assert {
    condition     = length(module.records.record_ids) == 2
    error_message = "expected both records applied"
  }
}
```

A run pointed at a live target must **abort before any create** — that
validation firing at plan time, before apply, is the property to test when
standing the suite up (deliberately mis-target once; expect zero creates).

Name/tag everything the suite creates with a sweepable prefix (`e2e-*`):
it is the reaper's key and a human signal in the provider's console.

## Teardown — what's guaranteed, what needs a backstop

Native guarantees (see Sources):

- Terraform **automatically destroys** everything a test file created at the
  file's conclusion, in **reverse `run`-block order** — including when an
  assertion failed.
- A destroy that fails is **not silent**: `terraform test` reports the
  resources left behind (`test_cleanup` — "left some resources in state …
  they need to be cleaned up manually", listing each `failed_resources`
  instance). An interrupt (`test_interrupt`) likewise reports what wasn't
  destroyed.

Reported-but-orphaned still costs money, so layer backstops:

1. **Runner trap** — wrap the invocation so an exit path the framework
   doesn't own (wrapper bug, credential expiry mid-run) still attempts a
   destroy/cleanup.
2. **Reaper sweep** — a separately-runnable job that lists resources by the
   `e2e-*` tag/name/pattern (read-only list, then targeted delete) and
   removes anything a previous run left. Run it on demand and/or scheduled.
3. **Assert-gone post-run** — the suite's last check: a read-only listing
   (CLI or API) shows nothing matching the test prefix/target.

Keep resource lifetime minimal: create → assert → destroy within one file;
no lingering fixtures between files. When a `run` sources an alternate
`module` for setup, remember destruction is reverse run order — order setup
runs so their resources outlive their dependents.

## Opt-in CI — the safety procedure

- **Never on the default gate.** Apply-mode suites do not run on
  `pull_request` or any required check; the credential-free tier
  (tftest-patterns) gates merges. The e2e workflow is **separate and
  non-required**.
- **`workflow_dispatch` first.** Start manual-trigger-only; add `schedule`
  only as a deliberate zero-touch conversion, not by default.
- **Stored secrets, scoped exposure.** Real credentials come from repo /
  Environment secrets (a private repo, or a public repo with Environment
  protection) read into step env — never echoed, never in a public repo's
  unprotected CI.
- **Environment protection for costly suites.** Put expensive or destructive
  suites (instance spin-up, mail-flow) behind a GitHub Environment with
  required reviewers; keep only the cheap subset automatic.
- **Cheap-first ordering** inside the workflow: fail on the free checks
  before anything that costs money exists.

Design every piece **convertible**: env-driven target/credentials and a
guard/reaper that work identically from a laptop and from CI make the
later opt-in → scheduled conversion a config change, not a rewrite.

## Worked consumer

harleydev's `e2e/` tree (README + per-layer docs) is the full worked
example of this skill's model: three-layer allow-list guard, trap + reaper,
domain-purpose split, phased build-out.

## Agent Behavior

- Keep apply-mode suites **out of the default gate** — plan-only
  (tftest-patterns) gates merges; e2e is opt-in (`workflow_dispatch` /
  local runner), non-required in CI.
- Require a **target allow-list validation** in the configuration under
  test; verify the guard by mis-targeting once — it must abort before any
  create.
- Write `command = apply` explicitly; name/tag created resources with a
  sweepable `e2e-*` prefix; order runs so reverse-order destroy unwinds
  cleanly.
- Layer teardown: native auto-destroy + runner trap + reaper sweep +
  assert-gone post-run. Treat a `test_cleanup` warning as a defect to fix,
  not noise.
- Route by target: validation/unit → **tftest-patterns**; provider
  internals → **terraform-provider-patterns**; out-of-band asserts only →
  Terratest.

## Sources

- Terraform language — Tests (syntax, sequential/parallel runs, automatic
  cleanup in reverse run order):
  <https://developer.hashicorp.com/terraform/language/tests> (fetched
  2026-07-06)
- `terraform test` CLI:
  <https://developer.hashicorp.com/terraform/cli/commands/test> (fetched
  2026-07-06)
- Machine-readable UI — `test_cleanup` / `test_interrupt` (failed-destroy
  reporting):
  <https://developer.hashicorp.com/terraform/internals/machine-readable-ui>
  (fetched 2026-07-06)
