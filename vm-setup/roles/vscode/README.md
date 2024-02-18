## Role Name

The `vscode` role is responsible for installing the Visual Studio Code
(VSCode) editor by adding the Microsoft repository to the target system's
package manager.

## Requirements

This role requires Ansible and access to the target system's package manager.

## Role Variables

This role does not have any user-modifiable variables. It uses the `add_repo`
role to install the Microsoft repository, which includes the VSCode
repository.

## Dependencies

This role depends on the `add_repo` role.

## Example Playbook

```yaml
- hosts: servers
  roles:
     - role: vscode
```
