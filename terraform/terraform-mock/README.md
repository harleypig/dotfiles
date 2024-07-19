# Mocking in Terraform Tests

[Mocking](https://developer.hashicorp.com/terraform/language/tests/mocking)
allow authors to test the basics of their code without actually creating
infrastructure.

Previously, we created files to test our `tfmod_file` module which creates
files with our specified content. Our requirements have changed. Now we need
to push those files to a bucket in GCP.

Once we've made those changes, we want to test that we've written our code
correctly, but we don't want waste resources on mistakes that can be caught
before going to the cloud.

**FIXME**

We will be using the same files created in the previous tutorial.

## Warning

Tests can create real infrastructure and can run assertions and validations
against that infrastructure.

This tutorial **does not** create real infrstructure.

## Test Setup

There a few different ways to setup tests for terraform. This document will
focus on how our ADO agents are configured.

## Changes to the module

Modify the `tfmod_file` to support pushing the created files to a GCP bucket.

* Change to the `tfmod_file` directory.
  * `cd tfmod_file`

### `versions.tf`

Modify the `versions.tf` file to include the necessary provider.

```
terraform {
  required_version = ">=1.3.2"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
```

### `main.tf`

Modify the `main.tf` file and add the resource block below.

```
resource "local_file" "yaml_files" {
  for_each = local.files_from_yaml

  filename             = each.key
  content              = each.value["content"]
  file_permission      = each.value["file_permission"]
  directory_permission = each.value["directory_permission"]
}

locals {
  files_from_yaml = {
    for f in var.files_from_yaml : f["filename"] => f
  }
}

resource "google_storage_bucket_object" "file" {
  for_each   = local.files_from_yaml
  depends_on = [local_file.yaml_files]

  bucket = var.bucket_name
  name   = basename(each.key)
  source = each.key
}
```

### `variables.tf`

Modify the `variables.tf` file to include the new variables `project_id`, `region`, and `bucket_name`.

```
variable "files_from_yaml" {
  description = "files in the module"
  type = map(object({
    filename             = string
    content              = string
    file_permission      = string
    directory_permission = string
  }))

  validation {
    condition = alltrue([
      for filename, file in var.files_from_yaml :
      can(regex("^filename\\d+\\.txt$", filename))
    ])
    error_message = "All filenames must match the pattern 'filenameXXX.txt' where XXX is any number."
  }
}

variable "project_id" {
  description = "The id of the GCP  project."
  type        = string
}

variable "region" {
  description = "The region of the GCP project."
  type        = string
}

variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
}
```

## Changes to the test files

Modify the `tfmod_file` test files to support pushing the created files to a GCP bucket.

* Change to the tests directory
  * `cd tests`

tests/main.tf and terraform-mock/tfmod_file/tests/main.tf differ
tests/main.tftest.hcl and terraform-mock/tfmod_file/tests/main.tftest.hcl differ
tests/variables.tf and terraform-mock/tfmod_file/tests/variables.tf differ
tests/versions.tf and terraform-mock/tfmod_file/tests/versions.tf differ

### `versions.tf`

The test versions file needs to match the modules versions file.

`cp ../versions.tf .`

### `main.tf`

Modify the test `main.tf` file to add the `project_id`, `region`, and `bucket_name` variables.

```
module "test_files" {
  source          = "../"
  files_from_yaml = var.test_filenames
  project_id      = var.project_id
  region          = var.region
  bucket_name     = var.bucket_name
}
```

### `tfmod_file/variables.tf`

Modify the `variables.tf` file to add the variable definitions for `project_id`, `region`, and `bucket_name`.

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

variable "project_id" {
  description = "The id of the GCP  project."
  type        = string
}

variable "region" {
  description = "The region of the GCP project."
  type        = string
}

variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
}
```

## `main.tftest.hcl`

Modify the `main.tftest.hcl` file to include a mock provider and resource and mock values for the bucket.

```
mock_provider "google" {
  mock_resource "google_storage_bucket_object" {}
}

run "good_filename" {
  command = plan

  variables {
    project_id  = "mock-id"
    region      = "mock-region"
    bucket_name = "mock-bucket"

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

Run `terraform init`, `terraform fmt`, and `terraform validate`. Everything should pass before continuing.

Run `terraform test -verbose`. You should see the following output.

```
```
