# Tests in Terraform

[Terraform tests](https://developer.hashicorp.com/terraform/language/tests)
let authors validate that module configuration updates do not introduce
breaking changes. Tests run against test-specific, short-lived resources,
preventing any risk to your existing infrastructure or state.

## Warning

Tests can create real infrastructure and can run assertions and validations
against that infrastructure.

This tutorial **does not** create real infrstructure.

## Test Setup

There a few different ways to setup tests for terraform. This document will
focus on how our ADO agents are configured.

* Change to `tfmod_file` and create a directory called `tests`.
  * `cd tfmod_file` and `mkdir tests`
* Copy `versions.tf` to the `tests` directory.
  * `cp ../versions.tf tests`
* Change to `tests`.
  * `cd tests`

## Create `main.tf`

Create a minimal `main.tf` that passes the data on to the module we're
testing.

Paste the following code into a file named `main.tf` and save it.

```
module "test_files" {
  source          = "../"
  files_from_yaml = var.test_filenames
}
```

## Create `variables.tf`

The variable definition is the same as the modules defintion, but we don't
need the validation check and we'll provide default options for fields we
won't be using in the test.

Paste the following code into a file named `variables.tf` and save it.

```
variable "test_filenames" {
  description = "files in the module"
  type = map(object({
    filename             = string
    content              = string
    file_permission      = optional(string, "0644")
    directory_permission = optional(string, "0755")
  }))
}
```

## Create `main.tftest.hcl`

Now we write the code that runs the test.

Paste the following code into a file named `variables.tf` and save it.

```
run "good_filename" {
  command = plan

  variables {
    test_filenames = {
      "filename42.txt" = {
        filename = "filename42.txt"
        content  = "This should succeed"
      }
    }
  }
}
```

## Run the test

Run `terraform init`, `terraform fmt`, `terraform validate`, and `terraform
plan`. Everything should pass before continuing.

Run `terraform test`. You should see the following output.

```
main.tftest.hcl... in progress
  run "good_filename"... pass
main.tftest.hcl... tearing down
main.tftest.hcl... pass

Success! 1 passed, 0 failed.
```
