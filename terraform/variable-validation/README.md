# Variable Validation in Terraform

Variable validation in Terraform allows us to enforce rules on variable
values. By using the `validation` block within a variable definition, we can
specify conditions that the variable must meet. If the conditions are not met,
Terraform will produce an error message, preventing the configuration from
being applied with invalid values.

The `tfmod_file` module will allow any valid value for the filename. We want
to limit filenames for our project, so we need to use variable validation.
This enforces that values provided for variables meet our criteria.
