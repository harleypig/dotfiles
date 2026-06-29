---
name: terraform-review
description: The Terraform slice of qa-check — run the full Terraform QA sub-pipeline AND a structural audit over a Terraform tree, belt-and-suspenders over pre-commit. Verifies fmt, credential-free validate, tflint, trivy misconfig, native tftest, and terraform-docs currency, then audits module structure (required files, variable/output descriptions + validations, pinned providers, CFF single-resource shape, root-configs-consume-modules), honoring documented exceptions. Use for whole-tree Terraform QA, not line-level diff review: "review the terraform", "qa the terraform", "check the modules' structure", "are the tfmods consistent", "is the terraform ready to merge", "audit the terraform modules". Composed by qa-check for Terraform repos. A packer-review sibling mirrors this for Packer.
---

# terraform-review

**Version:** v1.0.0

The **Terraform slice of `qa-check`**: for a repo with Terraform, run the
Terraform QA dimensions *and* a structural audit, then return one report. It is
the single thing `qa-check` delegates to for Terraform — `qa-check` learns
"there is Terraform here" and hands it off.

This is deliberately **belt-and-suspenders over pre-commit**: it **re-verifies**
rather than trusting that the pre-commit hooks ran. Most of the toolchain pass
*is* what pre-commit does — running it again here is the point, not waste.

It is **global and subject-agnostic** across Terraform repos; the
repo-specific specifics (which dirs are modules vs. root configs, the required
file set, the exception policy) come from the **repo's own `.claude/`**.

## Read first

1. **The repo's QA / Terraform doc** (`.claude/` — a "Quality assurance" and/or
   "Terraform" section in `CONVENTIONS.md`/`WORKFLOW.md`). Take from it: the
   **module roots** (e.g. `tfmods/*`), the **working-config roots** (e.g.
   `domains/`, `servers/`, `volumes/`), the concrete commands, and any
   **repo-specific structure rules or exceptions**. This is the source of truth
   for *this* repo; fall back to the defaults below when it is silent.
2. **`terraform.md`** (CLI, credential-free validate, versions.tf, the
   terraform-docs convention), **`tftest-patterns`** (native tests),
   **`tflint.md`**, **`trivy.md`** — the tool details.
3. **`qa.md`** — the dimension/order/discipline this slice plugs into.

## Two halves

### 1. Toolchain pass (re-verify; don't trust pre-commit)

Run each, in cheap-first order, fail-fast — via the repo's pre-commit where
present (`pre-commit.md`), else the dockerized tools (`bin/terraform` etc.):

- **Format** — `terraform fmt -check -recursive` (also `*.tftest.hcl`).
- **Validate** — credential-free: `-backend=false` + dummy AWS env
  (`AWS_ACCESS_KEY_ID=test`, `AWS_EC2_METADATA_DISABLED=true`), per dir after a
  no-backend `init`. Never authenticates, never reads remote state.
- **Lint** — `tflint --init` then `tflint` (non-deep; `deep_check` is
  credential-bearing — keep it out).
- **Security** — `trivy config --misconfig-scanners terraform`.
- **Tests** — `terraform test` (plan-only, `mock_provider`) for every module
  with a `tests/` dir — no creds, no infra (`tftest-patterns`).
- **Docs currency** — `terraform-docs --output-check` (non-modifying) so each
  README's generated tables match the `.tf` (`terraform.md`).

Never `apply`/`destroy`, never `packer build` — assessment only.

### 2. Structural audit (the gap pre-commit doesn't cover)

For each **module** (and, where noted, each **working config**):

- **Required files** — module has `main.tf`, `variables.tf`, `outputs.tf`,
  `versions.tf`, `provider.tf`, `README.md`, and `tests/*.tftest.hcl`. (A
  working config has its `.tf` + `README.md`; it needs no reusable I/O.)
- **Descriptions + validations** — every `variable` and `output` has a
  `description`; inputs carry `validation` blocks where a constraint exists
  (these double as `.tftest.hcl` failure cases).
- **Pinned providers** — provider sources/versions pinned in `versions.tf`
  (no unpinned drift).
- **CFF shape** — a module declares **one** primary resource (single-resource
  modules); **root configs consume modules** (`module "…"` blocks) rather than
  declaring provider resources inline; each README is **current**
  (the `--output-check` above).

Take the *exact* required-file set and any shape rules from the repo's
`.claude/` when it specifies them; the list above is the default.

## Exceptions are first-class

Conventions always meet a justified exception eventually. **A violation is
acceptable when it is documented** — so the audit flags only **undocumented**
deviations. A documented exception is reported under *Documented exceptions*,
not as a finding.

"Documented" means, in order of preference:

- **At the point of violation (minimum):** an adjacent comment explaining it,
  ideally tagged greppably — `# qa-exception: <reason>` (the packer-review
  sibling uses the same tag).
- **In the module's `README.md`:** an "Exceptions" note.
- **In an ADR** (the `adr` skill) for a deviation with broader rationale,
  referenced from the code.

When the audit hits a deviation, look for one of these nearby; if present, it
passes (and is listed); if absent, it is a finding whose suggested fix is
"either conform, or document the exception."

## Running it

The structural scan is read-heavy (every module's `.tf`). For a large library,
**delegate** to a generic `Explore` / `general-purpose` subagent (the lens
above in the prompt; return **structured findings only**) — fan out one per
top-level area and merge. For a few modules, scan inline. State which you did.

The toolchain pass runs the actual tools (Docker/pre-commit) — run it yourself,
don't delegate tool execution to a subagent.

## Report shape

Lead with the verdict, then evidence, ordered by leverage:

```markdown
## Terraform review — <repo/scope>

**Verdict:** <one line> — toolchain <pass/fail>, structure <N findings>

### Toolchain
- fmt ✓ · validate ✓ · tflint ✓ · trivy ✓ · tftest ✓ (M modules) · docs ✓

### Structural findings
- `tfmods/<m>` — missing outputs.tf; var `x` has no description
- `<config>/` — declares a resource inline (root config should consume a module)

### Documented exceptions (informational)
- `tfmods/<m>/main.tf` — two resources, `# qa-exception: <reason>`
```

Keep it proportional; omit empty sections. **Assess and report — do not fix.**
Conforming the findings (or writing the missing module/tests/README) is a
separate, confirmed step.

## Use in qa-check

`qa-check` composes this for Terraform repos (it sits across `qa.md`'s Format,
Lint, Security, Tests, and Documentation dimensions for the Terraform stack,
plus the structural slice of the Code-style audit). It assesses and reports;
**pre-commit and CI remain the gate.** A `packer-review` sibling mirrors this
for Packer (planned).

## Sources

House skill — no external code reused. Grounded in this config's own rules:
`terraform.md`, `tftest-patterns`, `tflint.md`, `trivy.md`, `qa.md`,
`code-style.md` (the exception-documentation stance), and the tool docs cited
in those rules.
