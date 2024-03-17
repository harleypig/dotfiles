Bitwarden Role
===============

This role installs the Bitwarden CLI tool (`bw`) to `/usr/local/bin`.

Requirements
------------

None.

Role Variables
--------------

None.

Dependencies
------------

None.

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: bitwarden }
