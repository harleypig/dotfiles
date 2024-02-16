# Role Name

The `gcloud` role is responsible for setting up the Google Cloud SDK on the target system by adding the Google Cloud repository.

## Requirements

This role requires Ansible and access to the target system's package manager.

## Role Variables

This role does not have any user-modifiable variables. It uses the `add_repo` role to install the Google Cloud repository.

## Dependencies

This role depends on the `add_repo` role.

## Example Playbook

```yaml
- hosts: servers
  roles:
     - role: gcloud
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
