## Role Name

The `add_repo` role is responsible for adding third-party repositories to the target system's package manager. It allows for the installation of packages from these repositories.

## Requirements

This role requires Ansible and access to the target system's package manager.

## Role Variables

The role uses the following variables defined in `defaults/main.yml` to configure the repositories to be added:

`repos`: A dictionary of repositories to be added, where each key is a repository identifier and each value is a dictionary containing the repository details such as `filename`, `key_url`, `repo_name`, and `repo_url`.

`repo_list`: An optional list of repository identifiers to add. If not provided, all repositories defined in `repos` will be added.

## Dependencies

There are no strict dependencies for this role, but it may require network access to download repository keys and package information.

## Example Playbook

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- hosts: servers
  roles:
     - role: add_repo
       vars:
         repo_list:
           - google-cloud
           - hashicorp
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

This role was created in 2023 by Alan Young.
