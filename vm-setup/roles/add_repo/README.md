## Role Name

The `add_repo` role is responsible for adding pre-defined third-party
repositories to the target system's package manager.

## Requirements

This role requires Ansible and access to the target system's package manager.

## Role Variables

`repo_list`: An optional list of repository identifiers that you want to add
from the `repos` dictionary. If this variable is not provided, all
repositories defined in `repos` will be added.

Currently, the predefined repositories are Hashicorp, Microsoft, and Google
Cloud.

### Handling Undefined Repositories

If a repository identifier provided in `repo_list` does not match any key in the `repos` dictionary, the role will fail with an error message. This validation ensures that only defined repositories can be added, preventing any misconfiguration or typos from causing issues during the execution of the role.

```yaml
- hosts: servers
  roles:
     - role: add_repo
       vars:
         repo_list:
           - google-cloud
           - hashicorp
```

### Error Handling


### Adding your own repository

XXX: This functionality needs to be tested.

You can either update the existing predefined repositories in the defaults
main.yml file or you can add a repository by adding the correct information as
described below.

`repos`: A dictionary where each key represents a unique identifier for
a repository, and the associated value is another dictionary with the
repository's details. The inner dictionary should contain the following keys:

- `filename`: The name of the file where the repository source will be saved.
- `key_url`: The URL to the repository's GPG key for secure installation.
- `repo_name`: A human-readable name for the repository.
- `repo_url`: The URL to the repository source list.

```yaml
- hosts: servers
  roles:
     - role: add_repo
       vars:
         repos:
           my_custom_repo:
             filename: 'my_custom_repo'
             key_url: 'http://example.com/my_repo_key.gpg'
             repo_name: 'My Custom Repository'
             repo_url: 'deb http://example.com/ubuntu some-component main'
         repo_list:
           - my_custom_repo
```

In this example, only the `my_custom_repo` repository would be added, using
the provided details.

## Dependencies

There are no strict dependencies for this role, but it may require network
access to download repository keys and package information.

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
