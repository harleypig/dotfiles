---
name: tftest-patterns
description: Concrete recipes for Terraform's native test framework (.tftest.hcl) — plan-only unit tests that create no real infrastructure, mock_provider for credential-free runs, assert blocks on planned values/outputs, expect_failures to test variable validation rules, file-level vs per-run variables, and co-located tests/ layout. Use when writing or improving Terraform module tests and you want the deeper how beyond "run terraform test" and the testing.md bar. Triggers - "write tests for this module", "terraform test", "tftest", "mock the provider", "test a variable validation", "expect_failures", "test this terraform without credentials".
---

# tftest-patterns

**Version:** v1.0.0

The deep *how* for testing Terraform modules with the **native** framework
(`terraform test` + `.tftest.hcl`, GA in Terraform 1.6+). The bar comes from
`testing.md` (cover success **and** failure paths; a regression test per bug);
the conventions/CLI come from `terraform.md`. This is the technique. For the
shell analog see **bats-setup**; for Python see **pytest-patterns**.

## Credential-free by default

Two ingredients keep tests free of real infrastructure and credentials — the
default for CI and agents:

- **`command = plan`** — a run defaults to `apply` (creates real infra). Use
  `command = plan` for unit tests: it evaluates config + validations + plan
  without creating anything.
- **`mock_provider`** (Terraform 1.7+) — replaces the real provider so plan
  needs no token; it auto-generates values for computed attributes.

## Layout

Co-locate per module — `terraform test` discovers `*.tftest.hcl` in the module
root and in a `tests/` dir:

```text
tfmods/<module>/tests/validations.tftest.hcl
```

Run from the module dir: `terraform init` then `terraform test`. (If the
toolchain runs via Docker, mount the repo and run both in the container — see
`terraform.md`.)

## Recipe — valid plan + asserts

File-level `mock_provider` and `variables` apply to every run; assert on
planned values or outputs:

```hcl
mock_provider "linode" {}

variables {
  records = { www = { domain_id = 123, record_type = "A", target = "192.0.2.1" } }
}

run "valid_record_plans" {
  command = plan

  assert {
    condition     = length(linode_domain_record.domain_records) == 1
    error_message = "expected exactly one planned record"
  }
}
```

`assert` needs both `condition` (bool) and `error_message`. With `mock_provider`
computed attributes are random, so assert on **shape** (counts, input
echoes, keys), not exact computed values.

## Recipe — test a variable validation with `expect_failures`

Each run can override `variables`; `expect_failures` lists the checkable
objects expected to fail (a `variable`, resource, output, or check). This is
how you test `validation` blocks credential-free:

```hcl
run "rejects_invalid_ttl" {
  command = plan

  variables {
    records = { bad = { domain_id = 123, record_type = "A", target = "192.0.2.1", ttl_sec = 999 } }
  }

  expect_failures = [var.records]
}
```

Write one failing run per rule. To isolate which rule fired when a variable
has several, set the *other* fields to valid values so only the rule under
test fails.

## Gotcha — `expect_failures` halts the run

A failed custom condition (variable validation, precondition) **halts** plan
execution. So an `assert` block in the *same* run as an `expect_failures` for a
variable may never be evaluated — keep "expects a clean plan + asserts" and
"expects a validation failure" in **separate** `run` blocks.

## mock overrides (when defaults aren't enough)

Inside `mock_provider`, pin specific values a test asserts on:

```hcl
mock_provider "linode" {
  mock_resource "linode_volume" { defaults = { size = 20 } }
}
```

`override_resource` / `override_data` / `override_module` (with `target`) pin
values at file or run scope when a data source or submodule output must be
deterministic.

## Agent Behavior

- Default to `command = plan` + `mock_provider` — no real infra, no
  credentials. Reserve `command = apply` for explicitly-gated integration
  tests against safe/ephemeral targets only (never the default CI gate).
- Put a module's `validation` blocks under test with `expect_failures`, one
  run per rule; keep failure-runs separate from clean-plan asserts.
- Co-locate tests in `tfmods/<module>/tests/`; cover a success path and the
  failure paths (`testing.md`).
