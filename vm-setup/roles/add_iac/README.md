Role Name
=========

The `add_iac` role is responsible for setting up Infrastructure as Code (IaC) tools on the target system. Currently, it focuses on adding the HashiCorp repository and installing HashiCorp products such as Terraform and Packer.

Requirements
------------

No specific requirements.

Role Variables
--------------

The role uses the following variables which are set in the `defaults/main.yml` of the `add_repo` role:

`repo_list`: A list of repositories to add. By default, it includes the HashiCorp repository.

Dependencies
------------

This role depends on the `add_repo` role to add the necessary APT repositories for HashiCorp products.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- hosts: servers
  roles:
     - { role: add_iac }
```

License
-------

BSD

Author Information
------------------

This role was created in 2023 by [Your Name].
