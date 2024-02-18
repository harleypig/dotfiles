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

### Available Variables

The following variables can be set to customize the GNOME desktop environment. These variables are defined in `defaults/main.yml`:

- `gnome_settings_show_home`: (boolean) Show or hide the home icon on the desktop.
  - Valid entries: `true` or `false`
- `gnome_settings_show_trash`: (boolean) Show or hide the trash icon on the desktop.
  - Valid entries: `true` or `false`
- `gnome_settings_titlebar_uses_system_font`: (boolean) Use the system font for window title bars.
  - Valid entries: `true` or `false`
- `gnome_settings_screensaver_idle_activation_enabled`: (boolean) Enable or disable the screensaver's idle activation.
  - Valid entries: `true` or `false`
- `gnome_settings_lock_screen_enabled`: (boolean) Enable or disable the lock screen.
  - Valid entries: `true` or `false`
- `gnome_settings_lock_screen_disable_lock_screen`: (boolean) Enable or disable the lock screen lockdown.
  - Valid entries: `true` or `false`

- `gnome_settings_desktop_background`: (list) A list of settings for the desktop background.
  - Valid keys: `picture-options`, `picture-uri`, `picture-uri-dark`, `primary-color`, `show-desktop-icons`

- `gnome_settings_desktop_interface`: (list) A list of settings for the desktop interface.
  - Valid keys: `clock-format`, `clock-show-date`, `clock-show-seconds`, `clock-show-weekday`, `color-scheme`, `document-font-name`, `font-name`, `monospace-font-name`

- `gnome_settings_dock`: (list) A list of settings for the GNOME dock.
  - Valid keys: `autohide`, `dash-max-icon-size`, `dock-position`, `extend-height`, `show-mounts`

- `gnome_settings_disabled_services`: (list) A list of system services to be disabled.
  - Valid entries: Names of systemd services

Each setting can be customized by changing the value next to its corresponding variable. For boolean variables, use `true` to enable and `false` to disable the feature. For list variables, provide a list of key-value pairs where the key is the setting name and the value is the setting value.

## Dependencies

This role depends on the `install_pkgs` role to ensure that the necessary packages are installed.
