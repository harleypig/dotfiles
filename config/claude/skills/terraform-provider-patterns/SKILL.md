---
name: terraform-provider-patterns
description: Concrete recipes for building a Terraform PROVIDER in Go with terraform-plugin-framework — provider/resource structure, schema + plan modifiers, ImportState, write-only attributes (create-only passwords/secrets), acceptance testing with terraform-plugin-testing + TF_ACC, tfplugindocs docs generation, and GoReleaser+GPG registry releases. Use when writing or refactoring a Terraform provider and you want the deeper how beyond running the scaffolding. Triggers - "write a terraform provider", "terraform-plugin-framework", "add a resource to the provider", "ImportState", "write-only attribute", "acceptance test TF_ACC", "tfplugindocs", "goreleaser provider release", "publish provider to the registry".
---

# terraform-provider-patterns

**Version:** v1.2.0

The deep *how* for building a **Terraform provider** in Go with HashiCorp's
**terraform-plugin-framework** (the current SDK; protocol v6). Language policy
comes from `go.md` + `golangci-lint.md`; the test bar from `testing.md`;
Terraform conventions from `terraform.md`. Distinct from **tftest-patterns**,
which tests Terraform *modules* — this builds the *provider* those modules
consume. A provider lives in its own `terraform-provider-<name>` repo (a
Registry requirement); a module library ("foundation fabric") is a **separate**
repo.

## Baseline

- **Scaffold from `terraform-provider-scaffolding-framework`** — a working
  skeleton: `main.go`, `internal/provider/`, `examples/`, generated `docs/`,
  `.goreleaser.yml`, `GNUmakefile`, `terraform-registry-manifest.json`, CI.
- **Versions:** framework **v1.18.x**, **Go ≥ 1.24**, Terraform ≥ 1.0,
  **protocol v6**. Pin them.
- **OpenAPI codegen** (`terraform-plugin-codegen-openapi` + `-framework`) is an
  **accelerator only** — HashiCorp labels it *tech preview, NOT for
  production*. Bootstrap a code-spec/schema from an OpenAPI 3 doc, then
  **hand-finish and own** the result; never treat it as a maintained pipeline.

## Structure

```text
main.go                      # providerserver.Serve(...)
internal/provider/
  provider.go                # the provider.Provider
  <thing>_resource.go        # one resource
  <thing>_data_source.go     # one data source
  client.go                  # API client (auth headers, envelope unwrap)
examples/  templates/  docs/ # tfplugindocs
```

`main.go` serves the gRPC plugin:

```go
providerserver.Serve(ctx, provider.New(version), providerserver.ServeOpts{
    Address: "registry.terraform.io/harleypig/mxroute",
    Debug:   debug, // -debug flag for delve
})
```

The **`provider.Provider`** implements `Metadata`, `Schema` (provider config),
`Configure` (build the API client, stash it on `resp.ResourceData` /
`DataSourceData`), `Resources`, `DataSources`.

## Recipe — a resource

Implement `resource.Resource` (`Metadata`, `Schema`, `Create`/`Read`/`Update`/
`Delete`), add `resource.ResourceWithConfigure` to receive the client, and
`resource.ResourceWithImportState`:

```go
func (r *ThingResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
    resource.ImportStatePassthroughID(ctx, path.Root("id"), req, resp)
}
```

**Gotcha:** unlike SDKv2 the framework does **not** auto-add an `id` — declare
it explicitly `Computed`, or acceptance/import tests fail.

## Recipe — schema + plan modifiers

```go
"id": schema.StringAttribute{
    Computed:      true,
    PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()},
},
"domain": schema.StringAttribute{
    Required:      true,
    PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()},
},
```

- `Required` / `Optional` / `Computed` / `Sensitive` are bool fields.
- `UseStateForUnknown()` keeps a stable computed value out of the
  "(known after apply)" noise.
- `RequiresReplace()` — the API can't update this in place.

## Recipe — write-only attribute (create-only password/secret)

The framework way for a value the API accepts but never returns (**TF 1.11+,
framework v1.15+**). The value lives **only in config** — state is always
`null`:

```go
"password_wo": schema.StringAttribute{
    Required:  true,
    WriteOnly: true,            // never stored in state
},
"password_wo_version": schema.Int64Attribute{
    Optional: true,             // bump to trigger an update
},
```

- Pair with `Required`/`Optional` (**not** `Computed`); no set attributes; if a
  nested attribute is write-only, all its children must be too.
- **Detecting change** (there's no prior state to diff): pair with a
  `*_wo_version` trigger, a `keepers`, or a hash kept in resource **private
  state**.
- This is the right pattern for MXroute's `email_account` password — prefer it
  over an old `Sensitive`-only field, which *does* persist to state.

## Recipe — acceptance test

Uses `terraform-plugin-testing`; gated by **`TF_ACC`** so it never touches real
infra by accident:

```go
func TestAccThing(t *testing.T) {
    resource.Test(t, resource.TestCase{
        ProtoV6ProviderFactories: map[string]func() (tfprotov6.ProviderServer, error){
            "mxroute": providerserver.NewProtocol6WithError(provider.New("test")()),
        },
        CheckDestroy: testAccCheckThingDestroy,
        Steps: []resource.TestStep{
            {Config: testAccThingConfig, Check: resource.ComposeAggregateTestCheckFunc(
                resource.TestCheckResourceAttr("mxroute_thing.t", "domain", "harleypig.com"),
            )},
            {ResourceName: "mxroute_thing.t", ImportState: true, ImportStateVerify: true},
        },
    })
}
```

For this setup, acceptance tests run against the **live account** via the
harleydev `bin/set_env` credentials (`TF_ACC=1` + the three MXroute env vars).
Keep them **out of the default CI gate** — they cost money and mutate real
state; run them deliberately.

## Fanning out — authoring many resources in parallel

A provider with several resources is a natural workflow fan-out — one agent
per resource, each mirroring a **proven** template (see the `LOOPS-WORKFLOWS`
doc, *Prove iteration one by hand*: build the first resource by hand, then fan
out the rest). Two provider-specific mechanics matter:

- **Author, don't build (per agent).** A Go package compiles as a *whole*, so
  N agents writing sibling files into one `internal/provider/` package cannot
  each run `go build` — every build would trip over the others' half-written
  files. Each agent *authors* its `<name>_resource.go` (+ test + example) and
  stops; the authoritative `go build` / `go vet` / lint runs **once at
  integration**, on the assembled package. This is the opposite of a Terraform
  *module* tree, where each module is independently buildable and a
  worktree-isolated per-agent verify works — a single-package provider gives
  that no purchase, so skip the worktrees and verify at integration.
- **`provider.go` is the one serial pinch-point.** Every resource must be
  registered in `Resources()` / `DataSources()` — a single-writer file. Agents
  must **not** edit it; the serial integration step registers them all at once.
  The thin `client.Do` client (above) keeps `client.go` untouched too, so the
  fan-out has exactly one shared file to serialize.

Verify each authored resource with an **adversarial review** agent — it catches
what `go build` and the linter cannot: a write-only secret leaking into state,
or an `Optional`-not-`Computed` attribute that yields a permanent plan diff.
The by-design "not registered in `provider.go`" a reviewer flags is the
integration step's job, not a file defect.

## Docs — tfplugindocs

`tfplugindocs` renders Registry markdown into `docs/` from the provider schema
plus `examples/` and `templates/`. Wire via `go generate`:

```go
//go:generate go run github.com/hashicorp/terraform-plugin-docs/cmd/tfplugindocs generate
```

- Example naming matters: `examples/resources/<name>/resource.tf`,
  `.../import.sh`.
- **Import docs are gated on the example file, not the code.** tfplugindocs
  renders a resource's `## Import` section **only when
  `examples/resources/<name>/import.sh` exists** — implementing
  `ResourceWithImportState` does nothing for the docs by itself. Every
  importable resource needs that file, or its Import section silently vanishes
  from the Registry page (this bit 6 of 10 resources on one provider: all
  imported in code, none documented it, because the examples were missing).
- `terraform-registry-manifest.json` at the root:
  `{"version":1,"metadata":{"protocol_versions":["6.0"]}}`.

## Release — GoReleaser + GPG

Copy `.goreleaser.yml` + `.github/workflows/release.yml` from the scaffolding
repo. Each `vX.Y.Z` tag (semver, no matching branch) must produce:

```text
terraform-provider-<name>_<ver>_<os>_<arch>.zip
terraform-provider-<name>_<ver>_manifest.json
terraform-provider-<name>_<ver>_SHA256SUMS
terraform-provider-<name>_<ver>_SHA256SUMS.sig   # GPG signature of the SHA256SUMS
```

Store `GPG_PRIVATE_KEY` (ASCII-armored) + `PASSPHRASE` as repo secrets; give
the Registry your GPG **public** key. Cut the tag per `release-tag` / `git.md`.

## Sources

Verified 2026-07-03:

- Framework overview / code walkthrough —
  <https://developer.hashicorp.com/terraform/plugin/framework>
- Import —
  <https://developer.hashicorp.com/terraform/plugin/framework/resources/import>
- Plan modification —
  <https://developer.hashicorp.com/terraform/plugin/framework/resources/plan-modification>
- Write-only arguments —
  <https://developer.hashicorp.com/terraform/plugin/framework/resources/write-only-arguments>
- Acceptance tests —
  <https://developer.hashicorp.com/terraform/plugin/framework/acctests>
- Docs / tfplugindocs —
  <https://developer.hashicorp.com/terraform/registry/providers/docs>
- Publishing (release assets, GPG) —
  <https://developer.hashicorp.com/terraform/registry/providers/publishing>
- Scaffolding template —
  <https://github.com/hashicorp/terraform-provider-scaffolding-framework>
- Code generation (tech-preview) —
  <https://developer.hashicorp.com/terraform/plugin/code-generation>

## Agent Behavior

- Scaffold from `terraform-provider-scaffolding-framework`; pin framework
  v1.18.x + Go ≥ 1.24 + protocol v6.
- Declare an explicit `Computed` `id`; implement `ImportState` on every
  resource **and add an `examples/resources/<name>/import.sh`** — without the
  example, tfplugindocs omits that resource's `## Import` doc section entirely.
- For any create-only secret (passwords, API keys) use a **`WriteOnly`**
  attribute + a `*_wo_version` trigger — never a plain `Sensitive` field that
  persists to state.
- Gate acceptance tests behind `TF_ACC`; run them against safe/live creds
  (harleydev `bin/set_env`), never in the default CI gate.
- When fanning out resource authoring across parallel agents, have each agent
  **author but not build** (a Go package can't compile file-by-file); run the
  authoritative build/lint once at integration, register every resource in
  `provider.go` in that single serial step, and adversarially review each
  resource for the state/plan bugs static checks miss.
- Generate docs with `tfplugindocs` (`go generate`); release via GoReleaser +
  GPG per the scaffolding workflow and `release-tag`.
- Treat OpenAPI codegen as a one-time accelerator, not a maintained pipeline.
