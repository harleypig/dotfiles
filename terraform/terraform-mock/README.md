# Creating and Testing a Folder in Google Cloud Platform with Terraform Mocking

This guide will walk you through creating a folder in Google Cloud Platform
(GCP) and testing it using Terraform's mocking capabilities. This ensures that
your Terraform configurations are correct without creating real
infrastructure.

## Warning

Tests can create real infrastructure and can run assertions and validations
against that infrastructure. This tutorial **does not** create real
infrastructure.

## Test Setup

There are a few different ways to set up tests for Terraform. This document
will focus on how to configure tests using Terraform's mocking capabilities.

* Change to the `tfmod_file` directory and create a directory called `tests`.
  * `cd tfmod_file` and `mkdir tests`
* Copy `versions.tf` to the `tests` directory.
  * `cp ../versions.tf tests`
* Change to the `tests` directory.
  * `cd tests`

## Create `main.tf`

Create a minimal `main.tf` that passes the data on to the module we're
testing.

Paste the following code into a file named `main.tf` and save it.

```
module "test_folder" {
  source          = "../"
  folder_name     = var.test_folder_name
}
```

## Create `variables.tf`

The variable definition is the same as the module's definition, but we don't
need the validation check and we'll provide default options for fields we
won't be using in the test.

Paste the following code into a file named `variables.tf` and save it.

```
variable "test_folder_name" {
  description = "Name of the folder to be created"
  type        = string
  default     = "test-folder"
}
```

## Create `main.tftest.hcl`

Now we write the code that runs the test.

Paste the following code into a file named `main.tftest.hcl` and save it.

```
run "create_folder" {
  command = plan

  variables = {
    test_folder_name = "mock-folder"
  }
}
```

## Run the Test

Run `terraform init`, `terraform fmt`, and `terraform validate`. Everything
should pass before continuing.

Run `terraform test`. You should see the following output.

```
main.tftest.hcl... in progress
  run "create_folder"... pass
main.tftest.hcl... tearing down
main.tftest.hcl... pass

Success! 1 passed, 0 failed.
```
