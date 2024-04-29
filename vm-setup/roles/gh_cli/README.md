## Role Name

The `gh_cli` role is responsible for installing the GitHub CLI on the target system.

## Requirements

This role requires Ansible and depends on the `add_repo` role for setting up the necessary repository.

## Role Variables

No additional variables are required for this role as it uses the `add_repo` role to handle repository setup.

## Dependencies

This role depends on the `add_repo` role.

## Example Playbook

```yaml
- hosts: servers
  roles:
     - role: gh_cli
```

This example will install the GitHub CLI on the servers.
