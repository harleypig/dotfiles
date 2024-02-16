## Role Name

The `add_iac` role is responsible for setting up Infrastructure as Code (IaC)
tools on the target system. Currently, it focuses on adding the HashiCorp
repository and installing HashiCorp products such as Terraform and Packer.

## Requirements

No specific requirements.

## Role Variables

The role uses the following variables which are set in the `defaults/main.yml`
of the `add_repo` role:

`repo_list`: A list of repositories to add. By default, it includes the
HashiCorp repository.

## Dependencies

This role depends on the `add_repo` role to add the necessary APT repositories
for HashiCorp products.

## Example Playbook

Including an example of how to use your role (for instance, with variables
passed in as parameters) is always nice for users too:

```yaml
- hosts: servers
  roles:
     - { role: add_iac }
```

## License

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
Version 2, December 2004

Copyright (C) 2023 Alan Young

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO.

## Author Information

This role was created in 2023 by Alan Young
