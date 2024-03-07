https://www.virtualbox.org/manual/ch08.html#vboxmanage-guestproperty

8.43. VBoxManage guestproperty

Manage virtual machine guest properties from host.

Synopsis

* VBoxManage guestproperty get < uuid | vmname > <property-name> [--verbose]
* VBoxManage guestproperty enumerate < uuid | vmname > [--no-timestamp] [--no-flags] [--relative] [--old-format] [patterns...]
* VBoxManage guestproperty set < uuid | vmname > <property-name> [property-value [--flags=flags]]
* VBoxManage guestproperty unset < uuid | vmname > <property-name>
* VBoxManage guestproperty wait < uuid | vmname > <patterns> [--timeout=msec] [--fail-on-timeout]

Description

The VBoxManage guestproperty command enables you to set or retrieve the
properties of a running virtual machine (VM). See Section 4.7, “Guest
Properties”. Guest properties are arbitrary name-value string pairs that can be
written to and read from by either the guest or the host. As a result, these
properties can be used as a low-volume communication channel for strings
provided that a guest is running and has the Guest Additions installed. In
addition, the Guest Additions automatically set and maintain values whose
keywords begin with /VirtualBox/.

General Command Operand
uuid|vmname
Specifies the Universally Unique Identifier (UUID) or name of the VM.

List All Properties for a Virtual Machine
VBoxManage guestproperty enumerate < uuid | vmname > [--no-timestamp] [--no-flags] [--relative] [--old-format] [patterns...]

The VBoxManage guestproperty enumerate command lists each guest property and value for the specified VM. Note that the output is limited if the guest's service is not updating the properties, for example because the VM is not running or because the Guest Additions are not installed.

--relative
Display the timestamp relative to current time.

--no-timestamp
Do not display the timestamp of the last update.

--no-flags
Do not display the flags.

--old-format
Use the output format from VirtualBox 6.1 and earlier.

pattern
Filters the list of properties based on the specified pattern, which can contain the following wildcard characters:

* (asterisk)
Represents any number of characters. For example, the /VirtualBox* pattern matches all properties that begin with /VirtualBox.

? (question mark)
Represents a single arbitrary character. For example, the fo? pattern matches both foo and for.

| (pipe)
Specifies multiple alternative patterns. For example, the s*|t* pattern matches any property that begins with s or t.

Retrieve a Property Value for a Virtual Machine
VBoxManage guestproperty get < uuid | vmname > <property-name> [--verbose]

The VBoxManage guestproperty get command retrieves the value of the specified property. If the property cannot be found, for example because the guest is not running, the command issues the following message:

No value set!
property-name
Specifies the name of the property.

--verbose
Provides the property value, timestamp, and any specified value attributes.

Set a Property Value for a Virtual Machine
VBoxManage guestproperty set < uuid | vmname > <property-name> [property-value [--flags=flags]]

The VBoxManage guestproperty set command enables you to set a guest property by specifying the property and its value. If you omit the value, the property is deleted.

property-name
Specifies the name of the property.

property-value
Specifies the value of the property. If no value is specified, any existing value is removed.

--flags=flags
Specify the additional attributes of the value. The following attributes can be specified as a comma-separated list:

TRANSIENT
Removes the value with the VM data when the VM exits.

TRANSRESET
Removes the value when the VM restarts or exits.

RDONLYGUEST
Specifies that the value can be changed only by the host and that the guest can read the value.

RDONLYHOST
Specifies that the value can be changed only by the guest and that the host can read the value.

READONLY
Specifies that the value cannot be changed.

Wait for a Property Value to Be Created, Deleted, or Changed
VBoxManage guestproperty wait < uuid | vmname > <patterns> [--timeout=msec] [--fail-on-timeout]

The VBoxManage guestproperty wait command waits for a particular value that is described by the pattern string to change, to be deleted, or to be created.

patterns
Specifies a pattern that matches the properties on which you want to wait. For information about the pattern wildcards, see the description of the --patterns option.

--timeoutmsec
Specifies the number of microseconds to wait.

--fail-on-timeout
Specifies that the command fails if the timeout is reached.

Unset a Virtual Machine Property Value
VBoxManage guestproperty unset < uuid | vmname > <property-name>

The VBoxManage guestproperty unset command unsets the value of a guest property.

The alternate form of this subcommand is delete.

property-name
Specifies the name of the property.

Examples
The following command lists the guest properties and their values for the win8 VM.

$ VBoxManage guestproperty enumerate win8
The following command creates a guest property called region for the win8 VM. The value of the property is set to west.

$ VBoxManage guestproperty set win8 region west
