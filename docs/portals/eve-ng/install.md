[edit]()

While EVE-NG officially does not support Microsoft Hyper-V, there is a guide detailing a user's successful installation of EVE-NG on Hyper-V. This guide suggests a workaround to achieve functionality, but please note that this is not an officially endorsed method and may lead to uncooperative virtual machines or other issues. EVE-NG typically recommends VMware Workstation or VMware Player for desktop installations.
Here is a step-by-step guide to install EVE-NG Community Edition on Microsoft Hyper-V, drawing on the available unofficial guide:
Important Disclaimer: EVE-NG explicitly states that VirtualBox, Citrix XenServer, and Microsoft Hyper-V are not officially supported. The steps provided below are based on a user's personal successful attempt and may require advanced troubleshooting or might not work in all environments. The official documentation consistently points to VMware solutions.
Prerequisites:
•
Your laptop or PC must have Hyper-V installed and a vSwitch configured with Internet access.
•
An Intel CPU supporting Intel® VT-x /EPT virtualization is required, and virtualization must be enabled in your computer's BIOS. You can check if virtualization is enabled on an EVE-NG instance by running grep -cw vmx /proc/cpuinfo in a terminal; an output greater than zero indicates it's enabled.
•
Download the Ubuntu 16.04 LTS ISO file. The guide specifically notes that Ubuntu 18 is not supported for this method. Other sources indicate Ubuntu 18.x, 19.x, and 20.x are generally unsupported for EVE-NG.
Step-by-Step Installation Guide:
Phase 1: Create the Virtual Machine (VM) in Hyper-V
1.
Open Hyper-V Manager and click on "New Virtual Machine".
2.
Name your VM (e.g., "EVE-NG"). It's important to choose a name without special characters as it will be used in a PowerShell command later.
3.
Select "Generation 2" for the virtual machine generation.
4.
Assign Startup Memory: Allocate RAM based on your host machine's capacity. For example, 8GB was used on a 12GB laptop, with dynamic memory enabled. Adjust this value according to your hardware and the intended lab size.
5.
Configure Networking: Select an existing vSwitch that is connected to the Internet. Internet access is essential during the installation process for updates.
6.
Create a Virtual Hard Disk: Assign a size for your virtual hard disk (e.g., 300GB). This size depends on the number of device images you plan to use in EVE-NG.
7.
Install Operating System: Choose "Install the operating system from a bootable image file" and browse to the Ubuntu 16.04 LTS ISO file you downloaded.
8.
Click "Next", then "Finish" to create the VM.
9.
Once the VM is created, right-click on it in Hyper-V Manager and select "Settings...".
10.
Navigate to "Security" and disable "Secure Boot". Failing to do so will prevent the VM from booting from the ISO.
11.
Go to "Processor" and increase the number of virtual processors as appropriate for your hardware.
12.
Click "OK".
13.
Connect to the VM and start it to begin the Ubuntu installation.
Phase 2: Ubuntu Server Installation and EVE-NG Pre-installation
1.
Proceed with the standard Ubuntu 16.04 LTS server installation steps within the Hyper-V console.
2.
After the Ubuntu installation completes and the VM reboots, log in with the user credentials you created during the Ubuntu setup.
3.
Gain root access by typing sudo su and entering your user password.
4.
Change the root password to something memorable (e.g., "eve").
5.
Execute apt-get update followed by apt-get upgrade to update Ubuntu packages. After the upgrade, shut down the server by typing shutdown now.
Phase 3: Enable Nested Virtualization (Hyper-V Specific)
1.
On your host PC (not inside the VM), open a PowerShell prompt as an administrator.
2.
Run the following command, replacing "EVE-NG" with the exact name of your virtual machine: Set-VMProcessor -VMName "EVE-NG" -ExposeVirtualizationExtensions $True. This command exposes hardware-assisted virtualization extensions to the guest OS, which is crucial for EVE-NG to run virtual devices.
3.
Start your EVE-NG VM again from the Hyper-V console. The warning message "neither Intel VT-x or AMD-V found on Hyper-V" should no longer appear.
Phase 4: Install EVE-NG Community Edition
1.
Ensure you are logged into the EVE-NG VM as root.
2.
Execute the EVE-NG installation script by typing: wget -O – https://www.eve-ng.net/focal/install-eve.sh | bash -i.
◦
Note: The URL https://www.eve-ng.net/focal/install-eve.sh refers to an Ubuntu 20.04 (Focal Fossa) repository. While the initial guide suggested Ubuntu 16.04 LTS, this command implies compatibility with or an update to using Ubuntu 20.04 for the EVE-NG installation script. Be aware of this potential version discrepancy.
3.
Allow the installation to complete. This process can take some time depending on your Internet connection and disk speed.
4.
After the installation is finished, reboot the server.
5.
Once EVE-NG reboots, you will see a login screen. The default root password is eve.
6.
Proceed with the initial EVE-NG configuration wizard (which includes setting the management IP address, hostname, and domain name). A static IP is often preferred.
7.
Finally, perform another apt update and apt upgrade within the EVE-NG CLI to ensure all packages are up to date.
After these steps, you should be able to access the EVE-NG web interface by navigating to the assigned IP address in your web browser. The default credentials for the web GUI are usually admin for username and eve for password. Remember that by default, only the VPCS image is preinstalled, and you will need to import other device images to get full value from the program.
