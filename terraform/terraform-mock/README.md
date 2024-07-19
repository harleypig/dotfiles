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

* Change to the `tfmod_file` directory.
  * `cd tfmod_file`

variables.tf and terraform-mock/tfmod_file/variables.tf differ
versions.tf and terraform-mock/tfmod_file/versions.tf differ

tests/main.tf and terraform-mock/tfmod_file/tests/main.tf differ
tests/main.tftest.hcl and terraform-mock/tfmod_file/tests/main.tftest.hcl differ
tests/variables.tf and terraform-mock/tfmod_file/tests/variables.tf differ
tests/versions.tf and terraform-mock/tfmod_file/tests/versions.tf differ

### `tfmod_file/main.tf`

Modify the `main.tf` file and add the resource block

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
