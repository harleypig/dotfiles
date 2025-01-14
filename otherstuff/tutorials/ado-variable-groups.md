# Azure DevOps Variable Groups

Azure DevOps Pipelines are essential for automating the build, test, and
deployment processes of your code. They facilitate continuous integration and
continuous delivery (CI/CD), allowing your code changes to be automatically
tested and deployed with minimal manual intervention. By defining pipeline
steps in YAML or using the visual designer, you can streamline your development
workflow, catch issues early, and deliver updates more quickly and reliably to
your users.

Variable groups in Azure DevOps Pipelines allow you to manage and share values
such as connection strings, API keys, and other environment-specific settings
across multiple pipelines and stages. This centralization ensures consistency
and simplifies maintenance, as you only need to update your variables in one
place. In this tutorial, we will walk you through the process of setting up and
managing a variable group, enabling you to keep your CI/CD processes running
efficiently.


## Create a variable group

A variable group cannot be created via YAML. You will need to use the web
interface to do so.

* Go to [ADO variable group](https://dev.azure.com) page.
* Select your project. For this tutorial we'll be using the `Cloud` project.
* Go to `Pipelines` -> `Library`.
* Click on `+ Variable group`.
* Give your variable group a short but descriptive name.
* Give your variable group a description. This is optional, but is helpful.
* Click `Save`.

! Do not turn on the `Link secrets from an Azure key vault as variables`. We
are using Hashicorp's Vault application.

This tutorial will describe setting up a variable group to access the Hashicorp
Vault service.

! This is a basic setup. You will need to modify and add variables for your
specific needs.

## Define variables

While the variable names can be any arbitrary text, it would be much less
confusing if you named your variables something that matched their use. For
example, for Vault's role-id requirement, you would name your variable
`role_id`.

We'll be adding the `role_id`, `secret_id`, and `vault_addr` variables.

### Create `role_id` variable

* Click on `+ Add`. The focus will be in the name field.
* Enter `role_id` in the name field.
* Click on the value field and enter `my role id hash`.

### Create `secret_id` variable

* Click on `+ Add`.
* Enter `secret_id` in the name field.
* Click on the value field and enter `my secret id hash`.
* Click on the lock icon on the right hand side of the variable definition.
  * When you do this, the variable line should become dim and the value field
    should be filled with asterisks. You will not be able to see this value
    going forward.

### Create `vault_addr` variable

* Click on `+ Add`.
* Enter `vault_addr` in the name field.
* Click on the value field.
* Enter the address for the Hashicorp Vault app.
* Click on `Save`.

## Manage allowed users

* Click on `Security`.

You will see a list of predefined groups (or teams), including yourself as an
administrator for this group.

You will probably want to add your team as admins for this group.

* Click `+ Add`.
* Search for and add your team in the `User or group` field.
* Select `Administrator` in the `Role` dropdown.
* Click `Add`.
* Close the `Security` popup window.
* Add any other users or groups as appropriate for your use case.

Specifics of managing security roles and access is beyond the scope of this
tutorial.

## Manage pipeline permissions

You will need to connect your variable group to an existing pipeline.

* Click `Pipeline permissions`.
* Click `+` and find the pipeline you want use this variable group.
* Repeat this process for as many pipelines as needed.
* Close the `Pipeline permissions` popup window.

??? Don't we have a way to allow a pipeline to use a variable group and it has
to be approved by someone in the security group when the pipeline is run?

## Manage approvals and checks

??? Can't find a variable group that uses this. I'm not even sure what the
value would be on having one of these on a variable group.

## Use a variable group in a pipeline
