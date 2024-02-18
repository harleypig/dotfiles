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
