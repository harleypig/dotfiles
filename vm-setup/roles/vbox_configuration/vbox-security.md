Chapter 13. Security Guide
Table of Contents

13.1. General Security Principles
13.2. Secure Installation and Configuration
13.2.1. Installation Overview
13.2.2. Post Installation Configuration
13.3. Security Features
13.3.1. The Security Model
13.3.2. Secure Configuration of Virtual Machines
13.3.3. Configuring and Using Authentication
13.3.4. Potentially Insecure Operations
13.3.5. Encryption
13.4. Security Recommendations
13.4.1. CVE-2018-3646
13.4.2. CVE-2018-12126, CVE-2018-12127, CVE-2018-12130, CVE-2019-11091
13.1. General Security Principles
The following principles are fundamental to using any application securely.

Keep software up to date. One of the principles of good security practise is to keep all software versions and patches up to date. Activate the Oracle VM VirtualBox update notification to get notified when a new Oracle VM VirtualBox release is available. When updating Oracle VM VirtualBox, do not forget to update the Guest Additions. Keep the host operating system as well as the guest operating system up to date.

Restrict network access to critical services. Use proper means, for instance a firewall, to protect your computer and your guests from accesses from the outside. Choosing the proper networking mode for VMs helps to separate host networking from the guest and vice versa.

Follow the principle of least privilege. The principle of least privilege states that users should be given the least amount of privilege necessary to perform their jobs. Always execute Oracle VM VirtualBox as a regular user. We strongly discourage anyone from executing Oracle VM VirtualBox with system privileges.

Choose restrictive permissions when creating configuration files, for instance when creating /etc/default/virtualbox, see Section 2.3.3.7, “Automatic Installation Options”. Mode 0600 is preferred.

Monitor system activity. System security builds on three pillars: good security protocols, proper system configuration and system monitoring. Auditing and reviewing audit records address the third requirement. Each component within a system has some degree of monitoring capability. Follow audit advice in this document and regularly monitor audit records.

Keep up to date on latest security information. Oracle continually improves its software and documentation. Check this note yearly for revisions.

13.2. Secure Installation and Configuration
13.2.1. Installation Overview
The Oracle VM VirtualBox base package should be downloaded only from a trusted source, for instance the official website http://www.virtualbox.org. The integrity of the package should be verified with the provided SHA256 checksum which can be found on the official website.

General Oracle VM VirtualBox installation instructions for the supported hosts can be found in Chapter 2, Installation Details.

On Windows hosts, the installer can be used to disable USB support, support for bridged networking, support for host-only networking and the Python language binding. See Section 2.1, “Installing on Windows Hosts”. All these features are enabled by default but disabling some of them could be appropriate if the corresponding functionality is not required by any virtual machine. The Python language bindings are only required if the Oracle VM VirtualBox API is to be used by external Python applications. In particular USB support and support for the two networking modes require the installation of Windows kernel drivers on the host. Therefore disabling those selected features can not only be used to restrict the user to certain functionality but also to minimize the surface provided to a potential attacker.

The general case is to install the complete Oracle VM VirtualBox package. The installation must be done with system privileges. All Oracle VM VirtualBox binaries should be executed as a regular user and never as a privileged user.

The Oracle VM VirtualBox Extension Pack provides additional features and must be downloaded and installed separately, see Section 1.5, “Installing Oracle VM VirtualBox and Extension Packs”. As for the base package, the SHA256 checksum of the extension pack should be verified. As the installation requires system privileges, Oracle VM VirtualBox will ask for the system password during the installation of the extension pack.

13.2.2. Post Installation Configuration
Normally there is no post installation configuration of Oracle VM VirtualBox components required. However, on Oracle Solaris and Linux hosts it is necessary to configure the proper permissions for users executing VMs and who should be able to access certain host resources. For instance, Linux users must be member of the vboxusers group to be able to pass USB devices to a guest. If a serial host interface should be accessed from a VM, the proper permissions must be granted to the user to be able to access that device. The same applies to other resources like raw partitions, DVD/CD drives, and sound devices.

13.3. Security Features
This section outlines the specific security mechanisms offered by Oracle VM VirtualBox.

13.3.1. The Security Model
One property of virtual machine monitors (VMMs) like Oracle VM VirtualBox is to encapsulate a guest by executing it in a protected environment, a virtual machine, running as a user process on the host operating system. The guest cannot communicate directly with the hardware or other computers but only through the VMM. The VMM provides emulated physical resources and devices to the guest which are accessed by the guest operating system to perform the required tasks. The VM settings control the resources provided to the guest, for example the amount of guest memory or the number of guest processors and the enabled features for that guest. For example remote control, certain screen settings and others. See Section 3.4, “General Settings”.

13.3.2. Secure Configuration of Virtual Machines
Several aspects of a virtual machine configuration are subject to security considerations.

13.3.2.1. Networking
The default networking mode for VMs is NAT which means that the VM acts like a computer behind a router, see Section 6.3, “Network Address Translation (NAT)”. The guest is part of a private subnet belonging to this VM and the guest IP is not visible from the outside. This networking mode works without any additional setup and is sufficient for many purposes. Keep in mind that NAT allows access to the host operating system's loopback interface.

If bridged networking is used, the VM acts like a computer inside the same network as the host, see Section 6.5, “Bridged Networking”. In this case, the guest has the same network access as the host and a firewall might be necessary to protect other computers on the subnet from a potential malicious guest as well as to protect the guest from a direct access from other computers. In some cases it is worth considering using a forwarding rule for a specific port in NAT mode instead of using bridged networking.

Some setups do not require a VM to be connected to the public network at all. Internal networking, see Section 6.6, “Internal Networking”, or host-only networking, see Section 6.7, “Host-Only Networking”, are often sufficient to connect VMs among each other or to connect VMs only with the host but not with the public network.

13.3.2.2. VRDP Remote Desktop Authentication
When using the Oracle VM VirtualBox Extension Pack provided by Oracle for VRDP remote desktop support, you can optionally use various methods to configure RDP authentication. The "null" method is very insecure and should be avoided in a public network. See Section 7.1.5, “RDP Authentication”.

13.3.2.3. Clipboard
The shared clipboard enables users to share data between the host and the guest. Enabling the clipboard in Bidirectional mode enables the guest to read and write the host clipboard. The Host to Guest mode and the Guest to Host mode limit the access to one direction. If the guest is able to access the host clipboard it can also potentially access sensitive data from the host which is shared over the clipboard.

If the guest is able to read from and/or write to the host clipboard then a remote user connecting to the guest over the network will also gain this ability, which may not be desirable. As a consequence, the shared clipboard is disabled for new machines.

13.3.2.4. Shared Folders
If any host folder is shared with the guest then a remote user connected to the guest over the network can access these files too as the folder sharing mechanism cannot be selectively disabled for remote users.

13.3.2.5. 3D Graphics Acceleration
Enabling 3D graphics using the Guest Additions exposes the host to additional security risks. See Section 4.5.1, “Hardware 3D Acceleration (OpenGL and Direct3D 8/9)”.

13.3.2.6. CD/DVD Passthrough
Enabling CD/DVD passthrough enables the guest to perform advanced operations on the CD/DVD drive, see Section 5.9, “CD/DVD Support”. This could induce a security risk as a guest could overwrite data on a CD/DVD medium.

13.3.2.7. USB Passthrough
Passing USB devices to the guest provides the guest full access to these devices, see Section 3.11.1, “USB Settings”. For instance, in addition to reading and writing the content of the partitions of an external USB disk the guest will be also able to read and write the partition table and hardware data of that disk.

13.3.3. Configuring and Using Authentication
The following components of Oracle VM VirtualBox can use passwords for authentication:

When using remote iSCSI storage and the storage server requires authentication, an initiator secret can optionally be supplied with the VBoxManage storageattach command. As long as no settings password is provided, by using the command line option --settingspwfile, then this secret is stored unencrypted in the machine configuration and is therefore potentially readable on the host. See Section 5.10, “iSCSI Servers” and Section 8.26, “VBoxManage storageattach”.

When using the Oracle VM VirtualBox web service to control an Oracle VM VirtualBox host remotely, connections to the web service are authenticated in various ways. This is described in detail in the Oracle VM VirtualBox Software Development Kit (SDK) reference. See Chapter 11, Oracle VM VirtualBox Programming Interfaces.

13.3.4. Potentially Insecure Operations
The following features of Oracle VM VirtualBox can present security problems:

Enabling 3D graphics using the Guest Additions exposes the host to additional security risks. See Section 4.5.1, “Hardware 3D Acceleration (OpenGL and Direct3D 8/9)”.

When teleporting a machine, the data stream through which the machine's memory contents are transferred from one host to another is not encrypted. A third party with access to the network through which the data is transferred could therefore intercept that data. An SSH tunnel could be used to secure the connection between the two hosts. But when considering teleporting a VM over an untrusted network the first question to answer is how both VMs can securely access the same virtual disk image with a reasonable performance.

If the network is not sufficiently trusted, the password should be changed for each teleportation as the a 3rd party could snoop up the unecrypted password hash when it is transferred between the target and source host machines.

When Page Fusion, see Section 4.10.2, “Page Fusion”, is enabled, it is possible that a side-channel opens up that enables a malicious guest to determine the address space of another VM running on the same host layout. For example, where DLLs are typically loaded. This information leak in itself is harmless, however the malicious guest may use it to optimize attack against that VM through unrelated attack vectors. It is recommended to only enable Page Fusion if you do not think this is a concern in your setup.

When using the Oracle VM VirtualBox web service to control an Oracle VM VirtualBox host remotely, connections to the web service, over which the API calls are transferred using SOAP XML, are not encrypted. They use plain HTTP by default. This is a potential security risk. For details about the web service, see Chapter 11, Oracle VM VirtualBox Programming Interfaces.

The web services are not started by default. See Section 9.18, “Starting the Oracle VM VirtualBox Web Service Automatically” to find out how to start this service and how to enable SSL/TLS support. It has to be started as a regular user and only the VMs of that user can be controlled. By default, the service binds to localhost preventing any remote connection.

Traffic sent over a UDP Tunnel network attachment is not encrypted. You can either encrypt it on the host network level, with IPsec, or use encrypted protocols in the guest network, such as SSH. The security properties are similar to bridged Ethernet.

Because of shortcomings in older Windows versions, using Oracle VM VirtualBox on Windows versions older than Vista with Service Pack 1 is not recommended.

13.3.5. Encryption
The following components of Oracle VM VirtualBox use encryption to protect sensitive data:

When using the Oracle VM VirtualBox Extension Pack provided by Oracle for VRDP remote desktop support, RDP data can optionally be encrypted. See Section 7.1.6, “RDP Encryption”. Only the Enhanced RDP Security method (RDP5.2) with TLS protocol provides a secure connection. Standard RDP Security (RDP4 and RDP5.1) is vulnerable to a man-in-the-middle attack.

When using the Oracle VM VirtualBox Extension Pack provided by Oracle for disk encryption, the data stored in disk images can optionally be encrypted. See Section 9.29, “Encryption of Disk Images”. This feature covers disk image content only. All other data for a virtual machine is stored unencrypted, including the VM's memory and device state which is stored as part of a saved state, both when created explicitly or part of a snapshot of a running VM.

13.4. Security Recommendations
This section contains security recommendations for specific issues. By default VirtualBox will configure the VMs to run in a secure manner, however this may not always be possible without additional user actions such as host OS or firmware configuration changes.

13.4.1. CVE-2018-3646
This security issue affect a range of Intel CPUs with nested paging. AMD CPUs are expected not to be impacted (pending direct confirmation by AMD). Also the issue does not affect VMs running with hardware virtualization disabled or with nested paging disabled.

For more information about nested paging, see Section 10.6, “Nested Paging and VPIDs”.

The following mitigation options are available.

13.4.1.1. Disable Nested Paging
By disabling nested paging (EPT), the VMM will construct page tables shadowing the ones in the guest. It is no possible for the guest to insert anything fishy into the page tables, since the VMM carefully validates each entry before shadowing it.

As a side effect of disabling nested paging, several CPU features will not be made available to the guest. Among these features are AVX, AVX2, XSAVE, AESNI, and POPCNT. Not all guests may be able to cope with dropping these features after installation. Also, for some guests, especially in SMP configurations, there could be stability issues arising from disabling nested paging. Finally, some workloads may experience a performance degradation.

13.4.1.2. Flushing the Level 1 Data Cache
This aims at removing potentially sensitive data from the level 1 data cache when running guest code. However, it is made difficult by hyper-threading setups sharing the level 1 cache and thereby potentially letting the other thread in a pair refill the cache with data the user does not want the guest to see. In addition, flushing the level 1 data cache is usually not without performance side effects.

Up to date CPU microcode is a prerequisite for the cache flushing mitigations. Some host OSes may install these automatically, though it has traditionally been a task best performed by the system firmware. So, please check with your system / mainboard manufacturer for the latest firmware update.

We recommend disabling hyper threading on the host. This is traditionally done from the firmware setup, but some OSes also offers ways disable HT. In some cases it may be disabled by default, but please verify as the effectiveness of the mitigation depends on it.

The default action taken by VirtualBox is to flush the level 1 data cache when a thread is scheduled to execute guest code, rather than on each VM entry. This reduces the performance impact, while making the assumption that the host OS will not handle security sensitive data from interrupt handlers and similar without taking precautions.

A more aggressive flushing option is provided via the VBoxManage modifyvm --l1d-flush-on-vm-entry option. When enabled the level 1 data cache will be flushed on every VM entry. The performance impact is greater than with the default option, though this of course depends on the workload. Workloads producing a lot of VM exits (like networking, VGA access, and similiar) will probably be most impacted.

For users not concerned by this security issue, the default mitigation can be disabled using the VBoxManage modifyvm name --l1d-flush-on-sched off command.

13.4.2. CVE-2018-12126, CVE-2018-12127, CVE-2018-12130, CVE-2019-11091
These security issues affect a range of Intel CPUs starting with Nehalem. The CVE-2018-12130 also affects some Atom Silvermont, Atom Airmont, and Knights family CPUs, however the scope is so limited that the host OS should deal with it and Oracle VM VirtualBox is therefore not affected. Leaks only happens when entering and leaving C states.

The following mitigation option is available.

13.4.2.1. Buffer Overwriting and Disabling Hyper-Threading
First, up to date CPU microcode is a prerequisite for the buffer overwriting (clearing) mitigations. Some host OSes may install these automatically, though it has traditionally been a task best performed by the system firmware. Please check with your system or mainboard manufacturer for the latest firmware update.

This mitigation aims at removing potentially sensitive data from the affected buffers before running guest code. Since this means additional work each time the guest is scheduled, there might be some performance side effects.

We recommend disabling hyper-threading (HT) on hosts affected by CVE-2018-12126 and CVE-2018-12127, because the affected sets of buffers are normally shared between thread pairs and therefore cause leaks between the threads. This is traditionally done from the firmware setup, but some OSes also offers ways disable HT. In some cases it may be disabled by default, but please verify as the effectiveness of the mitigation depends on it.

The default action taken by Oracle VM VirtualBox is to clear the affected buffers when a thread is scheduled to execute guest code, rather than on each VM entry. This reduces the performance impact, while making the assumption that the host OS will not handle security sensitive data from interrupt handlers and similar without taking precautions.

The VBoxManage modifyvm command provides a more aggressive flushing option is provided by means of the --mds-clear-on-vm-entry option. When enabled the affected buffers will be cleared on every VM entry. The performance impact is greater than with the default option, though this of course depends on the workload. Workloads producing a lot of VM exits (like networking, VGA access, and similiar) will probably be most impacted.

For users not concerned by this security issue, the default mitigation can be disabled using the VBoxManage modifyvm name --mds-clear-on-sched off command.
