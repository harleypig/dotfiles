# TODOs

## Braindump

* shell script to detect environment and which playbooks need to be run
* environments
  + configuration for different (e.g., linode, virtualbox, etc.)
* dev, prod, gui (desktop)
* gui settings:
  + gsettings set org.gnome.desktop.background picture-uri ''
  + gsettings set org.gnome.desktop.background primary-color '#27285C'
  + gsettings set org.gnome.shell.extensions.desktop-icons show-trash false
  + gsettings set org.gnome.shell.extensions.desktop-icons show-home false

# Stuff

Here's an example of how this Ansible configuration could be structured:

```
.
├── inventory
│   ├── dev
│   │   ├── group_vars
│   │   │   └── all.yml
│   │   ├── hosts.yml
│   │   └── host_vars
│   ├── prod
│   │   ├── group_vars
│   │   │   └── all.yml
│   │   ├── hosts.yml
│   │   └── host_vars
│   └── staging
│       ├── group_vars
│       │   └── all.yml
│       ├── hosts.yml
│       └── host_vars
├── playbook.yml
├── roles
│   ├── common
│   │   ├── defaults
│   │   ├── files
│   │   ├── handlers
│   │   ├── meta
│   │   ├── tasks
│   │   ├── templates
│   │   └── vars
│   ├── dev
│   │   ├── defaults
│   │   ├── files
│   │   ├── handlers
│   │   ├── meta
│   │   ├── tasks
│   │   ├── templates
│   │   └── vars
│   └── prod
│       ├── defaults
│       ├── files
│       ├── handlers
│       ├── meta
│       ├── tasks
│       ├── templates
│       └── vars
└── vars
    ├── dev.yml
    ├── prod.yml
    └── staging.yml
```

In this example, we have an `inventory` directory that contains subdirectories for each environment (`dev`, `prod`, and `staging`). Each environment has its own `hosts.yml` file that lists the hosts that belong to that environment. The `group_vars` directory contains YAML files that define variables for all hosts in the environment, while the `host_vars` directory contains YAML files that define variables for individual hosts.

The `playbook.yml` file is the main playbook that specifies which roles to apply to which hosts. It might look something like this:

```
- name: Configure all systems
  hosts: all
  roles:
    - common

- name: Configure dev environment
  hosts: dev
  roles:
    - common
    - dev

- name: Configure prod environment
  hosts: prod
  roles:
    - common
    - prod
```

This playbook first applies the `common` role to all hosts, then applies the `dev` or `prod` role to hosts in the corresponding environment.

The `roles` directory contains subdirectories for each role (`common`, `dev`, and `prod`). Each role contains directories for defaults, files, handlers, meta, tasks, templates, and vars. These directories contain YAML files that define various aspects of the role, such as default variables, tasks to execute, and templates to use.

Finally, the `vars` directory contains YAML files that define environment-specific variables. For example, `dev.yml` might define variables that are specific to the development environment. These variables can be used in the `group_vars` and `host_vars` files, as well as in the role directories.
