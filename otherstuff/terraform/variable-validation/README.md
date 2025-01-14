# Variable Validation in Terraform

[Variable
validation](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#input-variable-validation)
in Terraform allows us to enforce rules on variable values. By using the
`validation` block within a variable definition, we can specify conditions
that the variable must meet.

`condition` must return a boolean. Any valid terraform function, or
combination of functions can be used in a condition, as long as it evaluates
to `true` or `false`.

If the condition evaluates to false, Terraform produces an error message that
includes the result of the error_message expression. If you declare multiple
validations, Terraform returns error messages for all failed conditions.

The `tfmod_file` module will allow any valid value for the filename. We want
to limit filenames for our project, so we need to use variable validation.

## Validating current values

Modify `tfmod_file/variables.tf` so that it looks like this.

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
      contains(["filename1.txt", "filename2.txt"], filename)
    ])
    error_message = "All filenames must be either 'filename1.txt' or 'filename2.txt'."
  }
}
```

Run `terraform init`, `terraform fmt`, `terraform validate`, and `terraform
plan`. Everything should pass before continuing.

Now change `filename1.txt` in `myfolder/file1.yaml` to `filename3.txt` and run
the same init, fmt, validate, and plan commands. The plan command should fail
with the following message.

```
Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│
│   on main.tf line 21, in module "yaml_file":
│   21:   files_from_yaml = local.files_from_yamlb
│     ├────────────────
│     │ var.files_from_yaml is map of object with 2 elements
│
│ All filenames must be either 'filename1.txt' or 'filename2.txt'.
│
│ This was checked by the validation rule at tfmod_file/variables.tf:10,3-13.
╵
```

If you want to allow any number after filename, you could add a bunch of
possible filenames, but that would get unweildy pretty quickly. Instead, use
a regex.

Change your validation so that it looks like the following.

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
```

Notice the `contains(...)` line has been changed to `can(....)`, and the
`error_message` has been updated. Since `regex` doesn't return a boolean value
(it returns an empty list if the regex doesn't match), we use `can` to convert
to a boolean.

Run `terraform init`, `terraform fmt`, `terraform validate`, and `terraform
plan`. You should now see a successful plan.

Run `terraform apply` and make sure the files were created.
