---
paths:
  - "**/*.pkr.hcl"
  - "**/*.pkrvars.hcl"
---

# Packer Rules

**Version:** v1.0.0

Conventions for HashiCorp Packer image builds (HCL2 templates). Generic style
comes from `code-style.md`; this names only what is Packer-specific. Packer and
Terraform share HCL but are distinct tools — `antonbabenko/pre-commit-terraform`
does **not** provide Packer hooks (see `terraform.md`).

## Detection

Active when a repo contains `*.pkr.hcl` files.

## Safety posture

`packer build` creates real cloud resources (ephemeral builders + a saved
image) and needs credentials. An agent may **format and validate**; it must
**never** run `packer build` — building is an operator action, and never a CI
gate.

## Format

```bash
packer fmt -check -recursive -diff    # check (nonzero exit if unformatted)
packer fmt -recursive                 # write
```

## Validate — credential-free

```bash
packer validate -syntax-only .        # syntax only — no plugins, no creds
packer init . && packer validate .    # fuller check; init installs plugins
```

`-syntax-only` checks only the template syntax (no plugin install, no
credentials) — the safe CI/agent default. A full `packer validate` needs the
build plugins installed via `packer init`; avoid `-evaluate-datasources` in
CI/agent runs (it can call external, billable services). Required variables
with no default may need dummy `-var` values to validate.

## Conventions

- Standard files: `config.pkr.hcl`/`*.pkr.hcl` (sources + build), a
  `variables.pkr.hcl` (all user-configurable settings as variables), a
  `versions.pkr.hcl` pinning `required_plugins` + Packer version.
- Keep provisioners idempotent so rebuilds are reproducible.
- Pass secrets (tokens, keys) as variables/env, never hardcoded in templates.

## Packer ↔ Terraform handoff

A Packer-built image consumed by Terraform should be referenced by a
`data` lookup (e.g. newest image matching a label) rather than a hardcoded
image ID, so a rebuild doesn't require editing Terraform. Document the
build→reference flow in the repo.

## Enforcement (PostToolUse hook)

The global `config/claude/hooks/iac-fmt.py` `PostToolUse` hook runs **right
after** the agent edits a `*.pkr.hcl`/`*.pkrvars.hcl` file: it **auto-formats**
it with `packer fmt`, reports anything `fmt` could not fix, and runs `packer
validate -syntax-only` (no plugins/credentials). It calls `packer` via the
`bin/packer` docker wrapper and **fails open**. It **rewrites** the file, so
re-read after it reports a reformat. (Terraform shares the same hook — see
`terraform.md`.)

## Agent Behavior

- `packer fmt -check` and `packer validate -syntax-only` are fine; **never**
  `packer build` — that's the operator's call, never CI.
- Pin `required_plugins` + the Packer version in `versions.pkr.hcl`; keep
  user-configurable settings in variables and secrets out of templates.
- There is no pre-commit-terraform Packer hook — wire `packer fmt`/`validate`
  as `repo: local` hooks (or a CI step) if gating is wanted.

## Sources

- packer fmt — <https://developer.hashicorp.com/packer/docs/commands/fmt>
- packer validate (`-syntax-only`) —
  <https://developer.hashicorp.com/packer/docs/commands/validate>
- packer init — <https://developer.hashicorp.com/packer/docs/commands/init>
