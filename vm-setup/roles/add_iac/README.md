## Role Name

The `hashicorp` role is responsible for setting up Infrastructure as Code (IaC)
tools on the target system. Currently, it focuses on adding the HashiCorp
repository and installing HashiCorp products such as Terraform and Packer.

## Requirements

No specific requirements.

## Role Variables

This role does not have any user-modifiable variables.

## Dependencies

This role depends on the `add_repo` role to add the necessary APT repositories
for HashiCorp products.

## Example Playbook

Including an example of how to use your role (for instance, with variables
passed in as parameters) is always nice for users too:

```yaml
- hosts: servers
  roles:
     - role: hashicorp
```
