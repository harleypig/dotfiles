---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.tftest.hcl"
---

# Terraform Rules

**Version:** v1.0.0

Conventions for Terraform (and OpenTofu) configurations. Terraform is both a
language (HCL) and a CLI; this rule covers both. Generic style (naming,
paragraph spacing, the Rule of Three) comes from `code-style.md` — this names
only what is Terraform-specific. Linting is `tflint.md`; IaC misconfiguration
scanning is `trivy.md`; the native test framework's recipes are the
**tftest-patterns** skill (the bar is `testing.md`).

## Detection

Active when a repo contains `*.tf` files.

## Safety posture (READ FIRST)

Terraform changes real infrastructure. An agent may **format, validate, and
plan**; it must **never** run `terraform apply` (or `destroy`) — applying is a
deliberate operator action. CI likewise validates but never applies. The
credential-free operations below are safe for agents and CI; `plan`/`apply`
against a real backend need credentials and are out of scope for both.

## Format

```bash
terraform fmt -check -recursive -no-color   # check (nonzero exit if unformatted)
terraform fmt -recursive                    # write
```

2-space indent (Terraform's own style). Run check mode as the gate; the writer
belongs in the fix config (`pre-commit.md`).

## Validate — credential-free

`terraform validate` checks syntax + internal consistency; it does **not**
access remote state or configure providers, but it **requires `init` first**.
Init without touching the backend:

```bash
terraform init -backend=false && terraform validate -no-color
```

When the config declares an **S3-style backend** (e.g. Linode Object Storage),
even `-backend=false` can make the AWS SDK probe EC2 IMDS for credentials. Pass
**dummy** values so it doesn't — these are throwaway, not real secrets:

```bash
AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_EC2_METADATA_DISABLED=true \
  terraform init -backend=false && terraform validate -no-color
```

`plan`/`apply` against the real backend need credentials and touch
infrastructure — never a CI gate, never agent-run.

## Test

Use the **native** test framework (`terraform test`, `.tftest.hcl`, GA in
Terraform 1.6+) — not a third-party harness. Credential-free unit tests use
`command = plan` (no real infrastructure) plus `mock_provider` (Terraform 1.7+,
no provider credentials). Co-locate tests in each module's `tests/` dir. The
concrete recipes (run blocks, `assert`, `expect_failures`, `mock_provider`) are
the **tftest-patterns** skill; the success/failure-path bar is `testing.md`.

## versions.tf

Pin the required Terraform version and provider sources/versions in a
`versions.tf` (or `terraform {}` block) per module — unpinned providers drift.

## pre-commit

`antonbabenko/pre-commit-terraform` provides the hooks: `terraform_fmt`,
`terraform_validate`, `terraform_tflint`, `terraform_trivy` (the successor to
the **deprecated** `terraform_tfsec`), `terraform_docs`. Native hooks need the
underlying binaries (`terraform`, `tflint`, `trivy`) on `PATH`; if the repo
runs its toolchain through **Docker** instead (binaries not installed locally),
write `repo: local` `language: docker_image` hooks pinned to a version tag.
The repo has **no `packer_*` hooks** (see `packer.md`). Prefer driving these
through pre-commit (`pre-commit.md`).

## Enforcement (PostToolUse hook)

The global `config/claude/hooks/iac-fmt.py` `PostToolUse` hook runs **right
after** the agent edits a `*.tf`/`*.tfvars`/`*.tftest.hcl` file: it
**auto-formats** that file with `terraform fmt` (HCL is whitespace/quote
sensitive — a one-character slip causes confusing errors), reports anything
`fmt` could not fix (a parse error), and — **only if the dir is already
initialized** (`.terraform/` present) — runs `terraform validate` (dummy AWS
env, no `init`). It calls `terraform` via the `bin/terraform` docker wrapper
and **fails open** (no terraform/Docker → silent no-op). Unlike the check-only
`shell-check.py`, this one **rewrites** the file, so re-read after it reports a
reformat. Packer is handled by the same hook (see `packer.md`).

## Agent Behavior

- Format-check, validate (credential-free, `-backend=false` + dummy AWS env for
  S3 backends), and plan are fine; **never** `apply`/`destroy` — that's the
  operator's call.
- Add a `versions.tf` with pinned providers; validate inputs with `validation`
  blocks (they also become `.tftest.hcl` failure cases — tftest-patterns).
- Write tests with the native framework (`command = plan` + `mock_provider`),
  not Terratest, unless a repo already standardizes on Terratest.
- Prefer pre-commit (`pre-commit.md`); use `tflint.md` for lint and `trivy.md`
  (`trivy config --misconfig-scanners terraform`) for IaC misconfig scanning.

## Sources

- terraform fmt — <https://developer.hashicorp.com/terraform/cli/commands/fmt>
- terraform validate (and `-backend=false`) —
  <https://developer.hashicorp.com/terraform/cli/commands/validate>
- Tests / `.tftest.hcl` —
  <https://developer.hashicorp.com/terraform/language/tests>
- Provider mocking (`mock_provider`, 1.7+) —
  <https://developer.hashicorp.com/terraform/language/tests/mocking>
- `antonbabenko/pre-commit-terraform` —
  <https://github.com/antonbabenko/pre-commit-terraform>
