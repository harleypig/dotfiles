# Variable Validation in Terraform

[Variable
validation](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#input-variable-validation)
in Terraform allows us to enforce rules on variable values. By using the
`validation` block within a variable definition, we can specify conditions
that the variable must meet. If the conditions are not met, Terraform will
produce an error message, preventing the configuration from being applied with
invalid values. A condition must return a boolean value, either `true` or
`false`.

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

Run terraform init, fmt, validate and plan. Everything should pass before
continuing.

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
