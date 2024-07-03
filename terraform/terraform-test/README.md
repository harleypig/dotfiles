# Tests in Terraform

[Terraform tests](https://developer.hashicorp.com/terraform/language/tests)
let authors validate that module configuration updates do not introduce
breaking changes. Tests run against test-specific, short-lived resources,
preventing any risk to your existing infrastructure or state.

## Warning

Tests can create real infrastructure and can run assertions and validations
against that infrastructure.

## Test Setup

There a few different ways to setup tests for terraform. This document will
focus on how our ADO agents are configured.

* Change to `tfmod_file` and create a directory called `tests`.
  * `cd tfmod_file` and `mkdir tests`
* Copy `versions.tf` to the `tests` directory.
  * `cp versions.tf tests`
* Change to `tests`.
  * `cd tests`
