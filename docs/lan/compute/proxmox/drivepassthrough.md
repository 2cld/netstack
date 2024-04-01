
## You
As an IT professional using proxmox server how do I pass a windows harddrive to a proxmox ve vm?
## Copilot
Certainly! As an IT professional working with Proxmox VE, you can pass a physical hard drive from your Proxmox host to a virtual machine (VM). This process is known as disk passthrough. Here are the steps to achieve this:
- Identify the Disk:
    - First, you need to identify the physical disk you want to pass through to the VM. Note down the vendor, serial number, and other relevant details.
    - Avoid using device names like /dev/sdc, as these can change between reboots. Instead, use the stable /dev/disk/by-id paths.
- Update VM Configuration:
    - Log in to the Proxmox VE web interface or use the console.
    - Take note of the VM ID that the physical hard disk will connect to.
    - Use the following command to add the physical device as a new virtual SCSI disk:

/sbin/qm set [VM-ID] -virtio2 /dev/disk/by-id/[DISK-ID]

Replace [VM-ID] with the actual VM ID and [DISK-ID] with the disk ID obtained earlier.
- Uncheck Backup Option:
    - In the VM hardware settings, uncheck the backup option for the disk you've added.
- Configure the Disk in Windows:
    - Start the VM and log in to the Windows guest.
    - Initialize the disk using Windows Disk Management.
    - Create a new simple volume and assign a drive letter.
- Access the Disk:
    - Once configured, you'll be able to access the passed-through disk within the Windows VM.
Remember that this process prevents live migration of the VM and may impact host system I/O performance when running disk-intensive tasks on the VM . Always ensure backups and test thoroughly before implementing this in a production environment. 🚀

- [Proxmox doc - Passing a Physical Drive throught to VM](https://pve.proxmox.com/wiki/Passthrough_Physical_Disk_to_Virtual_Machine_%28VM%29)
