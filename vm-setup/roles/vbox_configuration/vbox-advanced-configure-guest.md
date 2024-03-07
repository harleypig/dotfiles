9.3. Advanced Configuration for Linux and Oracle Solaris Guests
9.3.1. Manual Setup of Selected Guest Services on Linux
The Oracle VM VirtualBox Guest Additions contain several different drivers. If you do not want to configure them all, use the following command to install the Guest Additions:

$ sh ./VBoxLinuxAdditions.run no_setup
After running this script, run the rcvboxadd setup command as root to compile the kernel modules.

On some 64-bit guests, you must replace lib with lib64. On older guests that do not run the udev service, you must add the vboxadd service to the default runlevel to ensure that the modules are loaded.

To set up the time synchronization service, add the vboxadd-service service to the default runlevel. To set up the X11 and OpenGL part of the Guest Additions, run the rcvboxadd-x11 setup command. Note that you do not need to enable additional services.

Use the rcvboxadd setup to recompile the guest kernel modules.

After compilation, reboot your guest to ensure that the new modules are loaded.

9.3.2. Guest Graphics and Mouse Driver Setup in Depth
This section assumes that you are familiar with configuring the X.Org server using xorg.conf and optionally the newer mechanisms using hal or udev and xorg.conf.d. If not you can learn about them by studying the documentation which comes with X.Org.

The Oracle VM VirtualBox Guest Additions includes drivers for X.Org. By default these drivers are in the following directory:

/opt/VBoxGuestAdditions-version/other/

The correct versions for the X server are symbolically linked into the X.Org driver directories.

For graphics integration to work correctly, the X server must load the vboxvideo driver. Many recent X server versions look for it automatically if they see that they are running in Oracle VM VirtualBox. For an optimal user experience, the guest kernel drivers must be loaded and the Guest Additions tool VBoxClient must be running as a client in the X session.

For mouse integration to work correctly, the guest kernel drivers must be loaded. In addition, for legacy X servers the correct vboxmouse driver must be loaded and associated with /dev/mouse or /dev/psaux. For most guests, a driver for a PS/2 mouse must be loaded and the correct vboxmouse driver must be associated with /dev/vboxguest.

The Oracle VM VirtualBox guest graphics driver can use any graphics configuration for which the virtual resolution fits into the virtual video memory allocated to the virtual machine, minus a small amount used by the guest driver, as described in Section 3.6, “Display Settings”. The driver will offer a range of standard modes at least up to the default guest resolution for all active guest monitors. The default mode can be changed by setting the output property VBOX_MODE to "<width>x<height>" for any guest monitor. When VBoxClient and the kernel drivers are active this is done automatically when the host requests a mode change. The driver for older versions can only receive new modes by querying the host for requests at regular intervals.

With legacy X Servers before version 1.3, you can also add your own modes to the X server configuration file. Add them to the "Modes" list in the "Display" subsection of the "Screen" section. For example, the following section has a custom 2048x800 resolution mode added:

Section "Screen"
        Identifier    "Default Screen"
        Device        "VirtualBox graphics card"
        Monitor       "Generic Monitor"
        DefaultDepth  24
        SubSection "Display"
                Depth         24
                Modes         "2048x800" "800x600" "640x480"
        EndSubSection
EndSection
