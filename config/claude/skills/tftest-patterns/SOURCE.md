# Sources

Authored from the official HashiCorp Terraform documentation (verified current
2026-06-29), not adapted from a single external skill. House skill grounded in:

- Tests / `.tftest.hcl` (run blocks, `command = plan` vs `apply`, `assert`,
  `expect_failures`, `variables`, test discovery) —
  <https://developer.hashicorp.com/terraform/language/tests>
- Test files reference —
  <https://developer.hashicorp.com/terraform/language/files/tests>
- `terraform test` command —
  <https://developer.hashicorp.com/terraform/cli/commands/test>
- Provider mocking (`mock_provider`, `mock_resource`/`mock_data`,
  `override_*`; Terraform 1.7+) —
  <https://developer.hashicorp.com/terraform/language/tests/mocking>

Related local artifacts: `rules/terraform.md` (conventions/CLI),
`testing.md` (the success/failure-path bar). The `expect_failures`-halts-plan
gotcha is documented in HashiCorp's test docs and the community deep-dive at
<https://mattias.engineer/blog/2024/terraform-test-mocks/>.

Reference agent artifacts noted during mining (not adopted wholesale — our
lean rule-first approach differs): `hashicorp/agent-skills`,
`antonbabenko/terraform-skill`. See `audit/idea-sources.md`.
