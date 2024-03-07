Role Name
=========

A brief description of the role goes here.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here.

Role Variables
--------------

Available variables are listed below, along with default values (see `defaults/main.yml`):

    vbox_guest_additions_path: "/opt/VBoxGuestAdditions-version/other/"

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: vbox_configuration, vbox_guest_additions_path: "/opt/VBoxGuestAdditions-version/other/" }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
