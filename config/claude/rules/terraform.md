---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.tftest.hcl"
---

# Terraform Rules

**Version:** v1.0.1

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

**Docker-wrapped CLI + parent paths.** When `terraform` runs through a
docker wrapper (the `bin/terraform` image, used where the binary isn't
installed locally), the container mounts only the **current** directory. A
root config that references parent paths — `../modules` sources, a
`provider.tf -> ../provider.tf` symlink — then can't resolve them (`Unable
to evaluate directory symlink` / `Unreadable module directory`). Run
`validate`/`test` from the **repo root** with `-chdir=DIR`, not `cd DIR`,
so the mount spans the parents:

```bash
terraform -chdir=DIR init -backend=false && \
  terraform -chdir=DIR validate -no-color
terraform -chdir=DIR test
```

(Same reason `terraform-docs` runs from the repo root — see *terraform-docs*
below.)

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

## terraform-docs (module READMEs)

Generate a module's README reference tables (Inputs/Outputs/Resources) with
**terraform-docs** rather than hand-writing them — mechanical content that
otherwise drifts. It **statically parses** `.tf` (no `terraform init`, no
credentials). Config is a `.terraform-docs.yml` (`formatter: markdown table`,
`output.mode: inject` between the `<!-- BEGIN_TF_DOCS -->` /
`<!-- END_TF_DOCS -->` markers); prose around the markers is preserved, so a
module keeps hand-written usage/notes alongside the generated tables.

- **Run it dockerized** where the toolchain isn't installed locally: the
  `bin/terraform-docs` docker wrapper, image
  `quay.io/terraform-docs/terraform-docs` (pin a tag, e.g. `:0.20.0`).
- **Per-module, not `recursive`**, for a *flat* library of sibling modules
  (a `tfmods/`-style dir, not a main module with a `modules/` subdir):
  recursive mode wrongly documents each module's `tests/` dir as a submodule.
  Loop over modules instead.
- **Gate with `--output-check`** (non-modifying; non-zero if a README is
  stale) in pre-commit/CI; the writer (`terraform-docs` without it) stays a
  manual/dev step, per `pre-commit.md`'s fix-once discipline.

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
- terraform-docs (config schema, `--output-check`, docker image, recursive) —
  <https://terraform-docs.io/> · <https://github.com/terraform-docs/terraform-docs>
