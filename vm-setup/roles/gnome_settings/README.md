# GNOME Settings Role

This role is responsible for configuring GNOME desktop environment settings according to the user's preferences. It can be used to customize various aspects of the GNOME desktop, including UI elements, system behaviors, and autostart applications.

## Role Structure

The role consists of the following main parts:

- `tasks/main.yml`: The main entry point for the role that includes other task files.
- `tasks/create_autostart.yml`: Tasks for creating autostart entries for applications.
- `tasks/tilix.yml`: Tasks for setting up the Tilix terminal emulator, including autostart configuration.
- `defaults/main.yml`: Default values for the role's variables.
- `vars/main.yml`: Variables related to the packages required by the role.
- `files/move_tilix`: A script to move the Tilix window to a specific position on the screen.
- `templates/autostart_app.desktop.j2`: A Jinja2 template for creating .desktop entries for autostart applications.
- `meta/main.yml`: Metadata for the role, including dependencies.

## Usage

To use this role, include it in your playbook and set the desired variables in the `defaults/main.yml` or pass them directly in the playbook.

Example playbook usage:

```yaml
- hosts: localhost
  roles:
    - role: gnome_settings
      vars:
        gnome_settings_show_home: true
        gnome_settings_dock:
          - autohide: false
          - dock-position: 'BOTTOM'
```

## Customization

You can customize the GNOME settings by modifying the variables in `defaults/main.yml` or by providing your own values when including the role in a playbook.

## Dependencies

This role depends on the `install_pkgs` role to ensure that the necessary packages are installed.
