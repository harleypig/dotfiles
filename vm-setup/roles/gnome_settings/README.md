# GNOME Settings Role

This role is responsible for configuring GNOME desktop environment settings
according to the user's preferences. It can be used to customize various
aspects of the GNOME desktop, including UI elements, system behaviors, and
autostart applications.

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

To use this role, include it in your playbook and set the desired variables in
the `defaults/main.yml` or pass them directly in the playbook.

Example playbook usage:

```yaml
- hosts: localhost
  roles:
    - role: gnome_settings
      vars:
        gnome_settings_tilix_profile_filename: path/to/profile_for_tilix
        gnome_settings_show_home: true
        gnome_settings_dock:
          - autohide: false
          - dock-position: 'BOTTOM'
```

## Customization

You can customize the GNOME settings by modifying the variables in
`defaults/main.yml` or by providing your own values when including the role in
a playbook.

## Create Autostart Task

The `create_autostart.yml` task file is used to create autostart entries for applications. This allows you to have applications, scripts, or commands automatically start when you log into your GNOME desktop environment.

To use this task, you need to define the following variables:

- `autostart_app_name`: The name of the application or script.
- `autostart_app_type`: The type of the autostart entry, which can be 'Application', 'Link', or 'Directory'.
- `autostart_app_exec`: The command or script to execute (required for 'Application' type).
- `autostart_app_url`: The URL to open (required for 'Link' type).

Additional optional settings can be provided through the `autostart_app_settings` dictionary. This task will create a `.desktop` file in the `~/.config/autostart` directory to manage the autostart behavior.


### Available Variables

The following variables can be set to customize the GNOME desktop environment.
These variables are defined in `defaults/main.yml`:

- `gnome_settings_show_home`: (boolean) Show or hide the home icon on the desktop. Default: `false`
  - Valid entries: `true` or `false`
- `gnome_settings_show_trash`: (boolean) Show or hide the trash icon on the desktop. Default: `false`
  - Valid entries: `true` or `false`
- `gnome_settings_titlebar_uses_system_font`: (boolean) Use the system font for window title bars. Default: `true`
  - Valid entries: `true` or `false`
- `gnome_settings_screensaver_idle_activation_enabled`: (boolean) Enable or disable the screensaver's idle activation. Default: `false`
  - Valid entries: `true` or `false`
- `gnome_settings_lock_screen_enabled`: (boolean) Enable or disable the lock screen. Default: `false`
  - Valid entries: `true` or `false`
- `gnome_settings_lock_screen_disable_lock_screen`: (boolean) Enable or disable the lock screen lockdown. Default: `true`
  - Valid entries: `true` or `false`

- `gnome_settings_desktop_background`: (list) A list of settings for the desktop background. Defaults:
  - `picture-options`: 'none'
  - `picture-uri`: ''
  - `picture-uri-dark`: ''
  - `primary-color`: '#00007D'
  - `show-desktop-icons`: false

- `gnome_settings_desktop_interface`: (list) A list of settings for the desktop interface. Defaults:
  - `clock-format`: '24h'
  - `clock-show-date`: true
  - `clock-show-seconds`: false
  - `clock-show-weekday`: true
  - `color-scheme`: 'prefer-dark'
  - `document-font-name`: 'Inconsolata Nerd Font 12'
  - `font-name`: 'Inconsolata Nerd Font 12'
  - `monospace-font-name`: 'Inconsolata Nerd Font Mono 12'

- `gnome_settings_dock`: (list) A list of settings for the GNOME dock. Defaults:
  - `autohide`: true
  - `dash-max-icon-size`: 40
  - `dock-position`: 'LEFT'
  - `extend-height`: false
  - `show-mounts`: false

- `gnome_settings_disabled_services`: (list) A list of system services to be disabled. Defaults:
  - Valid entries: Names of systemd services
  - `apt-daily.service`
  - `apt-daily-upgrade.service`

Each setting can be customized by changing the value next to its corresponding
variable. For boolean variables, use `true` to enable and `false` to disable
the feature. For list variables, provide a list of key-value pairs where the
key is the setting name and the value is the setting value.

## Tilix Task

The `tilix.yml` task file is responsible for setting up the Tilix terminal
emulator. It includes the following steps:

- Copying the `move_tilix` script to the local bin directory to allow moving the Tilix window to a specific screen position.
- Creating an autostart entry for Tilix to ensure it starts automatically upon login.
- Loading the Tilix profile if a custom profile file is provided.

To customize the Tilix setup, you can modify the
`gnome_settings_tilix_profile_filename` variable to specify the path to your
custom Tilix profile. Additionally, you can adjust the `move_tilix` script to
set the desired window position for Tilix.

## Dependencies

This role depends on the `install_pkgs` role to ensure that the necessary
packages are installed.
