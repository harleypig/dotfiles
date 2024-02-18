## Role Name

The `git_bug` role is responsible for installing and updating the `git-bug`
tool, which is a distributed bug tracker embedded in Git.

## Requirements

This role requires Git and access to GitHub's API for fetching the latest
release information.

## Role Variables

- `git_bug_repo`: The GitHub repository from which `git-bug` is cloned.
- `git_bug_binary_path`: The path where the `git-bug` binary will be installed.
- `git_bug_version_command`: The command used to check the installed version of `git-bug`.

## Dependencies

There are no strict dependencies for this role, but it requires network access
to GitHub for downloading the latest release of `git-bug`.

## Example Playbook

```yaml
- hosts: servers
  roles:
     - role: git_bug
```
