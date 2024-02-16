# Role Name

The `docker` role is responsible for setting up Docker on the target system.
It removes older Docker packages, adds the Docker repository, and installs the
necessary Docker packages.

## Requirements

This role requires Ansible and access to the target system's package manager.

## Role Variables

`docker_repo_name`: The identifier for the Docker repository to be added.
`docker_package_group`: The group of Docker packages to be installed.

## Dependencies

This role depends on the `add_repo` and `install_pkgs` roles.

## Example Playbook

```yaml
- hosts: servers
  roles:
     - role: docker
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
