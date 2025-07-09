[edit](https://github.com/2cld/netstack/edit/master/docs/portals/eve-ng/install.md)


- Download the Ubuntu 16.04 LTS ISO file. The guide specifically notes that Ubuntu 18 is not supported for this method. Other sources indicate Ubuntu 18.x, 19.x, and 20.x are generally unsupported for EVE-NG.

Step-by-Step Installation Guide:

Phase 1: Create the Virtual Machine (VM) in Hyper-V
1. Open Hyper-V Manager and click on "New Virtual Machine".
2. Name your VM (e.g., "evelab").
3. Select "Generation 2" for the virtual machine generation.
4. Assign Startup Memory: Allocate RAM  with dynamic memory enabled.
5. Configure Networking: External HyperV Switch.
6. Create a Virtual Hard Disk: Virtual hard disk (e.g., 300GB).
7. Install Operating System: Ubuntu 22.04.5 LTS ISO file downloaded.
8. Click "Next", then "Finish" to create the VM.
9. Once the VM is created, right-click on it in Hyper-V Manager and select "Settings...".
10. Navigate to "Security" and disable "Secure Boot".
11. Go to "Processor" and increase the number of virtual processors 4.
12. Click "OK".
13. Connect to the VM and start it to begin the Ubuntu installation.

Phase 2: Ubuntu Server Installation and EVE-NG Pre-installation
1. Proceed with the standard Ubuntu 22.04.5 LTS server installation steps within the Hyper-V console.
2. After the Ubuntu installation completes and the VM reboots, log in with ghadmin.
3. Gain root access.
4. Change the root password to What#Time.
5. Execute apt-get update followed by apt-get upgrade to update Ubuntu packages. After the upgrade, shut down the server by typing shutdown now.
```bash
apt-get update
```
```bash
apt-get upgrade
```

Phase 3: Enable Nested Virtualization (Hyper-V Specific)
1. On your host PC (not inside the VM), open a PowerShell prompt as an administrator.
2. Run the following command, replacing "evelab" with the exact name of your virtual machine: . This command exposes hardware-assisted virtualization extensions to the guest OS, which is crucial for EVE-NG to run virtual devices.
```powershell
Set-VMProcessor -VMName "EVE-NG" -ExposeVirtualizationExtensions $True
```
3. Start your EVE-NG VM again from the Hyper-V console. The warning message "neither Intel VT-x or AMD-V found on Hyper-V" should no longer appear.

Phase 4: Install EVE-NG Community Edition
1. Ensure you are logged into the evelab VM as root.
2. Execute the EVE-NG installation script by typing: .
```bash
wget -O – https://www.eve-ng.net/focal/install-eve.sh | bash -i
```
  ◦ Note: The URL https://www.eve-ng.net/focal/install-eve.sh refers to an Ubuntu 20.04 (Focal Fossa) repository. While the initial guide suggested Ubuntu 16.04 LTS, this command implies compatibility with or an update to using Ubuntu 20.04 for the EVE-NG installation script. Be aware of this potential version discrepancy.
3. Allow the installation to complete. This process can take some time depending on your Internet connection and disk speed.
4. After the installation is finished, reboot the server.
5. Once EVE-NG reboots, you will see a login screen. The default root password is eve.
6. Proceed with the initial EVE-NG configuration wizard (which includes setting the management IP address, hostname, and domain name). A static IP is often preferred.
7. Finally, perform another apt update and apt upgrade within the EVE-NG CLI to ensure all packages are up to date.

After these steps, you should be able to access the EVE-NG web interface by navigating to the assigned IP address in your web browser. The default credentials for the web GUI are usually admin for username and eve for password. Remember that by default, only the VPCS image is preinstalled, and you will need to import other device images to get full value from the program.
