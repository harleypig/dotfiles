3.2. Unattended Guest Installation
Oracle VM VirtualBox can install a guest OS automatically. You only need to provide the installation medium and a few other parameters, such as the name of the default user.

You can perform an unattended guest installation in the following ways:

Use the Create Virtual Machine wizard. An optional step in the wizard enables you to configure unattended installation. You can specify the default user credentials for the guest OS and also whether to install the Guest Additions automatically. See Section 1.8, “Creating Your First Virtual Machine”.

During this step, Oracle VM VirtualBox scans the installation medium and changes certain parameters to ensure a seamless installation as a guest running on Oracle VM VirtualBox.

Use the VBoxManage commands. Section 3.2.1, “Using VBoxManage Commands for Unattended Guest Installation” describes how to perform an unattended guest installation for an Oracle Linux guest.

When you first start a VM that has been configured for unattended installation, the guest OS installation is performed automatically.

The installation operation changes the boot device order to boot the virtual hard disk first and then the virtual DVD drive. If the virtual hard disk is empty prior to the automatic installation, the VM boots from the virtual DVD drive and begins the installation.

If the virtual hard disk contains a bootable OS, the installation operation exits. In this case, change the boot device order manually by pressing F12 during the BIOS splash screen.

3.2.1. Using VBoxManage Commands for Unattended Guest Installation
The following example shows how to perform an unattended guest installation for an Oracle Linux VM. The example uses various VBoxManage commands to prepare the guest VM. The VBoxManage unattended install command is then used to install and configure the guest OS.

Create the virtual machine.

# VM="ol7-autoinstall"
# VBoxManage list ostypes
# VBoxManage createvm --name $VM --ostype "Oracle_64" --register
Note the following:

The $VM variable represents the name of the VM.

The VBoxManage list ostypes command lists the guest OSes supported by Oracle VM VirtualBox, including the name used for each OS in the VBoxManage commands.

A 64-bit Oracle Linux 7 VM is created and registered with Oracle VM VirtualBox.

The VM has a unique UUID.

An XML settings file is generated.

Create a virtual hard disk and storage devices for the VM.

# VBoxManage createhd --filename /VirtualBox/$VM/$VM.vdi --size 32768
# VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI
# VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 \
--type hdd --medium /VirtualBox/$VM/$VM.vdi
# VBoxManage storagectl $VM --name "IDE Controller" --add ide
# VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 \
--type dvddrive --medium /u01/Software/OL/OracleLinux-R7-U6-Server-x86_64-dvd.iso
The previous commands do the following:

Create a 32768 MB virtual hard disk.

Create a SATA storage controller and attach the virtual hard disk.

Create an IDE storage controller for a virtual DVD drive and attach an Oracle Linux installation ISO.

(Optional) Configure some settings for the VM.

# VBoxManage modifyvm $VM --ioapic on
# VBoxManage modifyvm $VM --boot1 dvd --boot2 disk --boot3 none --boot4 none
# VBoxManage modifyvm $VM --memory 8192 --vram 128
The previous commands do the following:

Enable I/O APIC for the motherboard of the VM.

Configure the boot device order for the VM.

Allocate 8192 MB of RAM and 128 MB of video RAM to the VM.

Perform an unattended install of the OS.

# VBoxManage unattended install $VM \
--iso=/u01/Software/OL/OracleLinux-R7-U6-Server-x86_64-dvd.iso \
--user=login --full-user-name=name --password password \
--install-additions --time-zone=CET
The previous command does the following:

Specifies an Oracle Linux ISO as the installation ISO.

Specifies a login name, full name, and login password for a default user on the guest OS.

Note that the specified password is also used for the root user account on the guest.

Installs the Guest Additions on the VM.

Sets the time zone for the guest OS to Central European Time (CET).

Start the virtual machine.

This step completes the unattended installation process.

# VBoxManage startvm $VM --type headless
The VM starts in headless mode, which means that the VirtualBox Manager window does not open.

(Optional) Update the guest OS to use the latest Oracle Linux packages.

On the guest VM, run the following command:

# yum update
