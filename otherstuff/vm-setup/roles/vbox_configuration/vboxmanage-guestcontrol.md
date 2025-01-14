https://www.virtualbox.org/manual/ch08.html#vboxmanage-guestcontrol

8.44. VBoxManage guestcontrol
Control a virtual machine from the host system.

Synopsis

VBoxManage guestcontrol < uuid | vmname > run [--arg0=argument 0] [--domain=domainname] [--dos2unix] [--exe=filename] [--ignore-orphaned-processes] [ --no-wait-stderr | --wait-stderr ] [ --no-wait-stdout | --wait-stdout ] [ --passwordfile=password-file | --password=password ] [--profile] [--putenv=var-name=[value]] [--quiet] [--timeout=msec] [--unix2dos] [--unquoted-args] [--username=username] [--verbose] <-- [argument...]>


VBoxManage guestcontrol < uuid | vmname > start [--arg0=argument 0] [--domain=domainname] [--exe=filename] [--ignore-orphaned-processes] [ --passwordfile=password-file | --password=password ] [--profile] [--putenv=var-name=[value]] [--quiet] [--timeout=msec] [--unquoted-args] [--username=username] [--verbose] <-- [argument...]>


VBoxManage guestcontrol < uuid | vmname > copyfrom [--dereference] [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--no-replace] [--recursive] [--target-directory=host-destination-dir] [--update] [--username=username] [--verbose] <guest-source0> guest-source1 [...] <host-destination>


VBoxManage guestcontrol < uuid | vmname > copyto [--dereference] [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--no-replace] [--recursive] [--target-directory=guest-destination-dir] [--update] [--username=username] [--verbose] <host-source0> host-source1 [...]


VBoxManage guestcontrol < uuid | vmname > mkdir [--domain=domainname] [--mode=mode] [--parents] [ --passwordfile=password-file | --password=password ] [--quiet] [--username=username] [--verbose] <guest-directory...>


VBoxManage guestcontrol < uuid | vmname > rmdir [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--recursive] [--username=username] [--verbose] <guest-directory...>


VBoxManage guestcontrol < uuid | vmname > rm [--domain=domainname] [--force] [ --passwordfile=password-file | --password=password ] [--quiet] [--username=username] [--verbose] <guest-directory...>


VBoxManage guestcontrol < uuid | vmname > mv [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--username=username] [--verbose] <source...> <destination-directory>


VBoxManage guestcontrol < uuid | vmname > mktemp [--directory] [--domain=domainname] [--mode=mode] [ --passwordfile=password-file | --password=password ] [--quiet] [--secure] [--tmpdir=directory-name] [--username=username] [--verbose] <template-name>


VBoxManage guestcontrol < uuid | vmname > stat [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--username=username] [--verbose] <filename>


VBoxManage guestcontrol < uuid | vmname > list < all | files | processes | sessions > [--quiet] [--verbose]


VBoxManage guestcontrol < uuid | vmname > closeprocess [ --session-id=ID | --session-name=name-or-pattern ] [--quiet] [--verbose] <PID...>


VBoxManage guestcontrol < uuid | vmname > closesession [ --all | --session-id=ID | --session-name=name-or-pattern ] [--quiet] [--verbose]


VBoxManage guestcontrol < uuid | vmname > updatega [--quiet] [--verbose] [--source=guest-additions.ISO] [--wait-start] [-- [argument...]]


VBoxManage guestcontrol < uuid | vmname > watch [--quiet] [--verbose]

Description
The VBoxManage guestcontrol command enables you to control a guest (VM) from the host system. See Section 4.9, “Guest Control of Applications”.

Common Options and Operands
The following options can be used by any of the VBoxManage guestcontrol subcommands:

uuid|vmname
Specifies the Universally Unique Identifier (UUID) or name of the VM.

--quiet
Specifies that the command produce quieter output.

The short form of this option is -q.

--verbose
Specifies that the command produce more detailed output.

The short form of this option is -v.

Some of the VBoxManage guestcontrol subcommands require that you provide guest credentials for authentication. The subcommands are: copyfrom, copyto, mkdir, mktemp, mv, rmdir, rm, run, start, and stat.

While you cannot perform anonymous executions, a user account password is optional and depends on the guest's OS security policy. If a user account does not have an associated password, specify an empty password. On OSes such as Windows, you might need to adjust the security policy to permit user accounts with an empty password. In additional, global domain rules might apply and therefore cannot be changed.

The following options are used for authentication on the guest VM:

--domain=domainname
Specifies the user domain for Windows guest VMs.

--password=password
Specifies the password for the specified user. If you do not specify a password on the command line or if the password file is empty, the specified user needs to have an empty password.

--passwordfile=filename
Specifies the absolute path to a file on the guest OS that contains the password for the specified user. If the password file is empty or if you do not specify a password on the command line, the specified user needs to have an empty password.

--username=username
Specifies an existing user on the guest OS that runs the process. If unspecified, the host user runs the process.

Guest Process Restrictions
By default, you can run up to five guest processes simultaneously. If a new guest process starts and would exceed this limit, the oldest not-running guest process is discarded to run the new process. You cannot retrieve output from a discarded guest process. If all five guest processes are active and running, attempting to start a new guest process fails.

You can modify the guest process execution limit in two ways:

Use the VBoxManage setproperty command to update the /VirtualBox/GuestAdd/VBoxService/--control-procs-max-kept guest property value.

Use the VBoxService command and specify the --control-procs-max-kept=value option.

After you change the limit, you must restart the guest OS.

You can serve an unlimited number guest processes by specifing a value of 0, however this action is not recommended.

Run a Command on the guest
VBoxManage guestcontrol < uuid | vmname > run [--arg0=argument 0] [--domain=domainname] [--dos2unix] [--exe=filename] [--ignore-orphaned-processes] [ --no-wait-stderr | --wait-stderr ] [ --no-wait-stdout | --wait-stdout ] [ --passwordfile=password-file | --password=password ] [--profile] [--putenv=var-name=[value]] [--quiet] [--timeout=msec] [--unix2dos] [--unquoted-args] [--username=username] [--verbose] <-- [argument...]>

The VBoxManage guestcontrol vmname run command enables you to execute a program on the guest VM. Standard input, standard output, and standard error are redirected from the VM to the host system until the program completes.

Note
The Windows OS imposes certain limitations for graphical applications. See Chapter 14, Known Limitations.

--exe=path-to-executable
Specifies the absolute path of the executable program to run on the guest VM. For example: C:\Windows\System32\calc.exe.

--timeout=msec
Specifies the maximum amount of time, in milliseconds, that the program can run. While the program runs, VBoxManage receives its output.

If you do not specify a timeout value, VBoxManage waits indefinitely for the process to end, or for an error to occur.

--putenv=NAME=[value]
Sets, modifies, and unsets environment variables in the guest VM environment.

When you create a guest process, it runs with the default standard guest OS environment. Use this option to modify environment variables in that default environment.

Use the --putenv=NAME=[value] option to set or modify the environment variable specified by NAME.

Use the --putenv=NAME=[value] option to unset the environment variable specified by NAME.

Ensure that any environment variable name or value that includes spaces is enclosed by quotes.

Specify a --putenv option for each environment variable that you want to modify.

The short form of this option is -E.

--unquoted-args
Disables the escaped double quoting of arguments that you pass to the program. For example, \"fred\".

--ignore-orphaned-processes
Ignores orphaned processes. Not yet implemented.

--profile
Uses a shell profile to specify the environment to use. Not yet implemented.

--no-wait-stdout
Does not wait for the guest process to end or receive its exit code and any failure explanation.

--wait-stdout
Waits for the guest process to end to receive its exit code and any failure explanation. The VBoxManage command receives the standard output of the guest process while the process runs.

--no-wait-stderr
Does not wait for the guest process to end to receive its exit code, error messages, and flags.

--wait-stderr
Waits for the guest process to end to receive its exit code, error messages, and flags. The VBoxManage command receives the standard error of the guest process while the process runs.

--dos2unix
Transform DOS or Windows guest output to UNIX or Linux output. This transformation changes CR + LF line endings to LF. Not yet implemented.

--unix2dos
Transform UNIX or Linux guest output to DOS or Windows output. This transformation changes LF line endings to CR + LF.

--[argument...]
Specifies the name of the program and any arguments to pass to the program.

Ensure that any command argument that includes spaces is enclosed by quotes.

Start a Command on the guest
VBoxManage guestcontrol < uuid | vmname > start [--arg0=argument 0] [--domain=domainname] [--exe=filename] [--ignore-orphaned-processes] [ --passwordfile=password-file | --password=password ] [--profile] [--putenv=var-name=[value]] [--quiet] [--timeout=msec] [--unquoted-args] [--username=username] [--verbose] <-- [argument...]>

The VBoxManage guestcontrol vmname start command enables you to execute a guest program until it completes.

Note
The Windows OS imposes certain limitations for graphical applications. See Chapter 14, Known Limitations.

Copy a file from the guest to the host.
VBoxManage guestcontrol < uuid | vmname > copyfrom [--dereference] [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--no-replace] [--recursive] [--target-directory=host-destination-dir] [--update] [--username=username] [--verbose] <guest-source0> guest-source1 [...] <host-destination>

The VBoxManage guestcontrol vmname copyfrom command enables you to copy a file from the guest VM to the host system.

--dereference
Enables following of symbolic links on the guest file system.

--no-replace
Only copies a file if it does not exist on the host yet.

The short form of this option is -n.

--recursive
Recursively copies files and directories from the specified guest directory to the host.

The short form of this option is -R.

--target-directory=host-dst-dir
Specifies the absolute path of the destination directory on the host system. For example, C:\Temp.

--update
Only copies a file if the guest file is newer than on the host.

The short form of this option is -u.

guest-source0 [guest-source1 [...]]
Specifies the absolute path of one or more files to copy from the guest VM. For example, C:\Windows\System32\calc.exe. You can use wildcards to specify multiple files. For example, C:\Windows\System*\*.dll.

Copy a file from the host to the guest.
VBoxManage guestcontrol < uuid | vmname > copyto [--dereference] [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--no-replace] [--recursive] [--target-directory=guest-destination-dir] [--update] [--username=username] [--verbose] <host-source0> host-source1 [...]

The VBoxManage guestcontrol vmname copyto command enables you to copy a file from the host system to the guest VM.

--dereference
Enables following of symbolic links on the host system.

--no-replace
Only copies a file if it does not exist on the guest yet.

The short form of this option is -n.

--recursive
Recursively copies files and directories from the specified host directory to the guest.

The short form of this option is -R.

--target-directory=guest-dst-dir
Specifies the absolute path of the destination directory on the guest. For example, /home/myuser/fromhost.

--update
Only copies a file if the host file is newer than on the guest.

The short form of this option is -u.

host-source0 [host-source1 [...]]
Specifies the absolute path of a file to copy from the host system. For example, C:\Windows\System32\calc.exe. You can use wildcards to specify multiple files. For example, C:\Windows\System*\*.dll.

Create a directory on the guest.
VBoxManage guestcontrol < uuid | vmname > mkdir [--domain=domainname] [--mode=mode] [--parents] [ --passwordfile=password-file | --password=password ] [--quiet] [--username=username] [--verbose] <guest-directory...>

The VBoxManage guestcontrol vmname mkdir command enables you to create one or more directories on the guest VM.

Alternate forms of this subcommand are md, createdir, and createdirectory.

--parents
Creates any of the missing parent directories of the specified directory.

For example, if you attempt to create the D:\Foo\Bar directory and the D:\Foo directory does not exist, using the --parents creates the missing D:\Foo directory. However, if you attempt to create the D:\Foo\Bar and do not specify the --parents option, the command fails.

--mode=mode
Specifies the permission mode to use for the specified directory. If you specify the --parents option, the mode is used for the associated parent directories, as well. mode is a four-digit octal mode such as 0755.

guest-dir [guest-dir...]
Specifies an absolute path of one or more directories to create on the guest VM. For example, D:\Foo\Bar.

If all of the associated parent directories do not exist on the guest VM, you must specify the --parents option.

You must have sufficient rights on the guest VM to create the specified directory and its parent directories.

Remove a directory from the guest.
VBoxManage guestcontrol < uuid | vmname > rmdir [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--recursive] [--username=username] [--verbose] <guest-directory...>

The VBoxManage guestcontrol vmname rmdir command enables you to delete the specified directory from the guest VM.

Alternate forms of this subcommand are removedir and removedirectory.

--recursive
Recursively removes directories from the specified from the guest VM.

The short form of this option is -R.

guest-dir [guest-dir...]
Specifies an absolute path of one or more directories to remove from the guest VM. You can use wildcards to specify the directory names. For example, D:\Foo\*Bar.

You must have sufficient rights on the guest VM to remove the specified directory and its parent directories.

Remove a file from the guest.
VBoxManage guestcontrol < uuid | vmname > rm [--domain=domainname] [--force] [ --passwordfile=password-file | --password=password ] [--quiet] [--username=username] [--verbose] <guest-directory...>

The VBoxManage guestcontrol vmname rm command enables you to delete the specified files from the guest VM.

The alternate form of this subcommand is removefile.

--force
Forces the operation and overrides any confirmation requests.

The short form of this option is -f.

guest-file [guest-file...]
Specifies an absolute path of one or more file to remove from the guest VM. You can use wildcards to specify the file names. For example, D:\Foo\Bar\text*.txt.

You must have sufficient rights on the guest VM to remove the specified file.

Rename a file or Directory on the guest
VBoxManage guestcontrol < uuid | vmname > mv [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--username=username] [--verbose] <source...> <destination-directory>

The VBoxManage guestcontrol vmname mv command enables you to rename files and directories on the guest VM.

Alternate forms of this subcommand are move, ren, and rename.

guest-source [guest-source...]
Specifies an absolute path of a file or a single directory to move or rename on the guest VM. You can use wildcards to specify the file names.

You must have sufficient rights on the guest VM to access the specified file or directory.

dest
Specifies the absolute path of the renamed file or directory, or the destination directory to which to move the files. If you move only one file, dest can be a file or a directory, otherwise dest must be a directory.

You must have sufficient rights on the guest VM to access the destination file or directory.

Create a Temporary File or Directory on the guest
VBoxManage guestcontrol < uuid | vmname > mktemp [--directory] [--domain=domainname] [--mode=mode] [ --passwordfile=password-file | --password=password ] [--quiet] [--secure] [--tmpdir=directory-name] [--username=username] [--verbose] <template-name>

The VBoxManage guestcontrol vmname mktemp command enables you to create a temporary file or temporary directory on the guest VM. You can use this command to assist with the subsequent copying of files from the host system to the guest VM. By default, this command creates the file or directory in the guest VM's platform-specific temp directory.

Alternate forms of this subcommand are createtemp and createtemporary.

--directory
Creates a temporary directory that is specified by the template operand.

--secure
Enforces secure file and directory creation by setting the permission mode to 0755. Any operation that cannot be performed securely fails.

--mode=mode
Specifies the permission mode to use for the specified directory. mode is a four-digit octal mode such as 0755.

--tmpdir=directory
Specifies the absolute path of the directory on the guest VM in which to create the specified file or directory. If unspecified, directory is the platform-specific temp directory.

template
Specifies a template file name for the temporary file, without a directory path. The template file name must contain at least one sequence of three consecutive X characters, or must end in X.

Show a file or File System Status on the guest
VBoxManage guestcontrol < uuid | vmname > stat [--domain=domainname] [ --passwordfile=password-file | --password=password ] [--quiet] [--username=username] [--verbose] <filename>

The VBoxManage guestcontrol vmname stat command enables you to show the status of files or file systems on the guest VM.

file [file ...]
Specifies an absolute path of a file or file system on the guest VM. For example, /home/foo/a.out.

You must have sufficient rights on the guest VM to access the specified files or file systems.

List the Configuration and Status Information for a Guest Virtual Machine
VBoxManage guestcontrol < uuid | vmname > list < all | files | processes | sessions > [--quiet] [--verbose]

The VBoxManage guestcontrol vmname list command enables you to list guest control configuration and status information. For example, the output shows open guest sessions, guest processes, and files.

all|sessions|processes|files
Indicates the type of information to show. all shows all available data, sessions shows guest sessions, processes shows processes, and files shows files.

Terminate a Process in a guest Session
VBoxManage guestcontrol < uuid | vmname > closeprocess [ --session-id=ID | --session-name=name-or-pattern ] [--quiet] [--verbose] <PID...>

The VBoxManage guestcontrol vmname closeprocess command enables you to terminate a guest process that runs in a guest session. Specify the process by using a process identifier (PID) and the session by using the session ID or name.

--session-id=ID
Specifies the ID of the guest session.

--session-name=name|pattern
Specifies the name of the guest session. Use a pattern that contains wildcards to specify multiple sessions.

PID [PID ...]
Specifies the list of PIDs of guest processes to terminate.

Close a guest Session
VBoxManage guestcontrol < uuid | vmname > closesession [ --all | --session-id=ID | --session-name=name-or-pattern ] [--quiet] [--verbose]

The VBoxManage guestcontrol vmname closesession command enables you to close a guest session. Specify the guest session either by session ID or by name.

--session-id=ID
Specifies the ID of the guest session.

--session-name=name|pattern
Specifies the name of the guest session. Use a pattern that contains wildcards to specify multiple sessions.

--all
Closes all guest sessions.

Update the Guest Additions Software on the guest
VBoxManage guestcontrol < uuid | vmname > updatega [--quiet] [--verbose] [--source=guest-additions.ISO] [--wait-start] [-- [argument...]]

The VBoxManage guestcontrol vmname updatega command enables you to update the Guest Additions software installed in the specified guest VM.

Alternate forms of this subcommand are updateadditions and updateguestadditions.

--source=new-iso-path
Specifies the absolute path of the Guest Additions update .ISO file on the guest VM.

--reboot
Automatically reboots the guest after a successful Guest Additions update.

--timeout=ms
Sets the timeout (in ms) to wait for the overall Guest Additions update to complete. By default no timeout is being used.

--verify
Verifies whether the Guest Additions were updated successfully after a successful installation. A guest reboot is mandatory.

--wait-ready
Waits for the current Guest Additions being ready to handle the Guest Additions update.

--wait-start
Starts the VBoxManage update process on the guest VM and then waits for the Guest Additions update to begin before terminating the VBoxManage process.

By default, the VBoxManage command waits for the Guest Additions update to complete before it terminates. Use this option when a running VBoxManage process affects the interaction between the installer and the guest OS.

-- argument [argument ...]
Specifies optional command-line arguments to pass to the Guest Additions updater. You might use the -- option to pass the appropriate updater arguments to retrofit features that are not yet installed.

Ensure that any command argument that includes spaces is enclosed by quotes.

Wait for a guest run level
The VBoxManage guestcontrol vmname waitrunlevel command enables you to wait for a guest run level being reached.

--timeout=ms
Sets the timeout (in ms) to wait for reaching the run level. By default no timeout is being used.

system|userland|desktop
Specifies the run level to wait for.

Show Current Guest Control Activity
VBoxManage guestcontrol < uuid | vmname > watch [--quiet] [--verbose]

The VBoxManage guestcontrol vmname watch command enables you to show current guest control activity.

Examples
The following VBoxManage guestcontrol run command executes the ls -l /usr command on the My OL VM Oracle Linux VM as the user1 user.

$ VBoxManage --nologo guestcontrol "My OL VM" run --exe "/bin/ls" \
--username user1 --passwordfile pw.txt --wait-stdout -- -l /usr
The --exe option specifies the absolute path of the command to run in the guest VM, /bin/ls. Use the -- option to pass any arguments that follow it to the ls command.

Use the --username option to specify the user name, user1 and use the --passwordfile option to specify the name of a file that includes the password for the user1 user, pw.txt.

The --wait-stdout option waits for the ls guest process to complete before providing the exit code and the command output. The --nologo option suppresses the output of the logo information.

The following VBoxManage guestcontrol run command executes the ipconfig command on the My Win VM Windows VM as the user1 user. Standard input, standard output, and standard error are redirected from the VM to the host system until the program completes.

$ VBoxManage --nologo guestcontrol "My Win VM" run \
--exe "c:\\windows\\system32\\ipconfig.exe" \
--username user1 --passwordfile pw.txt --wait-stdout
The --exe specifies the absolute path of command to run in the guest VM, c:\windows\system32\ipconfig.exe. The double backslashes shown in this example are required only on UNIX host systems.

Use the --username option to specify the user name, user1 and use the --passwordfile option to specify the name of a file that includes the password for the user1 user, pw.txt.

The --wait-stdout option waits for the ls guest process to complete before providing the exit code and the command output. The --nologo option to suppress the output of the logo information.

The following VBoxManage guestcontrol start command executes the ls -l /usr command on the My OL VM Oracle Linux VM until the program completes.

$ VBoxManage --nologo guestcontrol "My Win VM" start \
--exe "c:\\windows\\system32\\ipconfig.exe" \
--username user1 --passwordfile pw.txt
The following VBoxManage guestcontrol run command executes a /usr/bin/busybox -l /usr command on the My OL VM Oracle Linux VM as the user1 user, explicitly using ls as argument 0.

$ VBoxManage --nologo guestcontrol "My OL VM" run --exe "/usr/bin/busybox" \
--username user1 --passwordfile pw.txt --wait-stdout --arg0 ls -- -l /usr
The --exe option specifies the absolute path of the command to run in the guest VM, /usr/bin/busybox. Use the -- option to pass any arguments that follow it to the busybox command.

Use the --username option to specify the user name, user1 and use the --passwordfile option to specify the name of a file that includes the password for the user1 user, pw.txt.

The --wait-stdout option waits for the ls guest process to complete before providing the exit code and the command output. The --nologo option suppresses the output of the logo information.

The --arg0 option explicitly specifies the argument 0 to use for the command to execute.

Note
If this option is not set, argument 0 will be taken from the value of --exe, or, if --exe is also not set, the first value passed after --.

Use --verbose to see the effective command line passed to the guest.

The default behavior of argument 0 is to either use the value from --exe, or, if not set, the first value passed after --.
