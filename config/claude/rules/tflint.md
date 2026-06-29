---
paths:
  - "**/*.tf"
  - "**/.tflint.hcl"
---

# tflint Rules

**Version:** v1.0.0

`tflint` is a pluggable linter for Terraform (`.tf`) — it catches errors the
`terraform validate` pass can't (deprecated syntax, invalid instance types,
naming, provider-specific issues). It applies to **Terraform** files; pair it
with `terraform.md` (the language/CLI rule) and `trivy.md` (IaC misconfig /
security scanning — a different concern).

## Detection

Active when a repo contains `*.tf` files (and especially a `.tflint.hcl`).

## Invocation

```bash
tflint --init        # install plugins declared in .tflint.hcl (run first)
tflint --recursive   # lint each dir recursively (each needs its own config)
tflint --chdir=DIR   # lint a specific directory
```

No errors permitted; fix findings before committing.

## Configuration

Config lives in a repo-local **`.tflint.hcl`** (HCL; `.tflint.json` also
works). Declare plugins/rulesets there — the core `terraform` ruleset plus any
provider ruleset:

```hcl
plugin "terraform" { enabled = true; preset = "recommended" }
```

- `tflint --init` installs whatever the config declares; run it before linting
  (CI installs plugins this way — no cloud credentials needed for the core or
  most provider rulesets).
- **Deep checking is credential-bearing.** The old `--deep` CLI flag was
  **removed**; deep checks are now enabled via `deep_check = true` in a plugin
  block and make real cloud API calls, so they need provider credentials.
  Keep deep checking **out** of credential-free CI and agent runs — use the
  default (non-deep) rules there.

## Agent Behavior

- Run `tflint --init` then `tflint` (or `--recursive`) after changing `.tf`;
  fix all findings. Prefer driving it through pre-commit
  (`terraform_tflint`, see `pre-commit.md`).
- Configure rules/plugins in `.tflint.hcl`, not CLI flags (the per-tool CLI
  flags for credentials/regions were removed).
- Do **not** enable `deep_check` in credential-free CI/agent runs — it calls
  cloud APIs and needs credentials.

## Sources

- tflint — <https://github.com/terraform-linters/tflint>
- Config (`.tflint.hcl`, plugins) —
  <https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md>
