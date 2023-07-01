[edit](https://github.com/2cld/netstack/blob/master/docs/lan/compute/proxmox/nswin11vm.md)

## proxmox windows11 vm nswin11
- References
  - [proxmox-windows11-vm](https://gulowsen.com/post/proxmox/proxmox-windows11-vm/)
  - [proxmox win11 drivers iso copy link](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)
  - [github for win11 driver](https://github.com/virtio-win/virtio-win-pkg-scripts)
- Create VM
  - Machine
    - Machine: Make sure machine is set to q35.
    - BIOS: Microsoft requires UEFI so use OVMF (UEFI).
    - Add EFI Disk and EFI Storage: EFI Disk should to be checked for Windows. It is a backup in case the boot part of windows gets corrupted. For EFI Disk you Should use the same storage as VM disk local-lvm.
    - SCSI Controller: Set this to VirtIO SCSI if not already.
    - Add TPM TPM is required for Windows 11 and Proxmox can virtualize it.
    - TPM Storage As EFI Storage this should point to local-lvm same disk for the VM on.
    - Version Make sure V2.0 is selected if you are installing Windows 11.
  - Drive
    - Bus Device: SCSI for compatibility.
    - Storage: local-lvm SSD same drive used in the previous steps.
    - Disk size: Microsoft minimum required drive size is 64 Gigabytes so give it that or more.
    - Cache: I set this to "write back" as it is the most stable option according to the Proxmox wiki.
  - CPU
    - Sockets: 1
    - Cores: 4 (half of the cores)
    - Type: Use "passthrough host" as the type
    - Extra CPU Flags: none
  - Memory
    - Memory: 8 gigabyte's of memory
    - Minimum memory: This is to make sure a VM will have enough memory for what you wish even if you enable ballooning.
    - Ballooning Device: Check this to enable Ballooning. When enabled, the VM will only be allocated the amount of memory it is actually using. This will give you the possibility to allocate more memory than you actually have, but be aware that this may cause start up problems and crashes.
  - Network
    - Bridge: This is the virtual network interface. You can add more after the initial setup.
    - VLAN Tag: Here you can enter a VLAN tag for which VLAN you wish your VM to be in. The tag is a number that can be between 1 and 4094.
    - Model: There are different types of network interface cards you can simulate. Most will make the VM think there is a cable connected. VirtIO will just come up as virtualized. Some operating systems may require one specific type.
    - MAC address: Here you are able to set a specific mac address if you require that.
    - Disconnect: Checking this simulates taking out a network cable. It can be helpful when you try different things and need to disconnect without deleting the entire network configuration.
  - DO NOT START VM
    - A: Select your windows VM in the server view.
    - B: Click Hardware
    - C: Clicking Add will open a drop down menu with additional hardware you can add. This includes both virtual and physical items.
    - D: To add the VirtIO ISO, click CD/DVD Drive.
    - E: Like when you configure the VM you can choose which storage and ISO image. Select the virtio-win.iso file.
    - F: Click Add to add the additional ISO addition.
  - tbd
- Install Windows
  - no key
  - Windows 11 Pro
  - Custom Install
  - Steps for adding the hard drive driver:
    - Start with Load driver. Then click Browse. Choose CD Drive virtio-win-"version".
    - Scroll down and expand vioscsi. Expand w11 folder for Windows 11, click amd64.
    - Click ok then next to install the driver. The hard drive should now show up in the setup window. 
  - Steps for adding the network driver:
    - Start with Load driver. Then click Browse. Choose CD Drive virtio-win-"version".
    - Scroll down and expand NetKVM. Expand w11 folder for Windows 11, click amd64.
    - Click ok then next to install the driver.  You will not see anything extra when this is installed but Windows will be able to do some updates during installation.
    - Next unless you wish to format the drive in a specific way click Next to continue.
- Setup Windows
  - Offline User To create an offline account simply click the options below in each menu.
    - A: Sign-in options
    - B: Offline account
    - C: Skip for now
  - Load Devices
    - run virtio-win-0.1.229/virtio-win-gt-x64.msi
    - Right click the start menu (Windows logo on the lower bar) Click Device Manager
    - Verify no PCI Device marked with and error.
    - If errors
      - Right click one of the devices with an error and click update driver.
      - In the window that opens, click Browse my computer for drivers.
      - On the next side click Browse.
      - In the file browser, navigate down to the virtio-win ISO and select it. You do not need to specify any drivers.
      - Click Next. Windows will go through the ISO and install the drivers it needs.
  - Remote Connection Enable
    - Start by right clicking the Windows start menu. Click Settings.
    - The System menu then scroll down to and click Remote Desktop
  - Guest Agent Install
    - [https://pve.proxmox.com/wiki/Qemu-guest-agent](https://pve.proxmox.com/wiki/Qemu-guest-agent)
    - Verify guest agent is enabled
    - Node (nswin11) Options -> QEMU Guest Agent : Enabled
    - run virtio-win-0.1.229/guest-agent/qemu-ga-x86-64.msi
  - tbd
- Backup vzdump-qemu-104-2023_07_01-17_21_19.vma.zst
```
root@cg2:/var/lib/vz/dump# ls
vzdump-qemu-104-2023_07_01-17_21_19.log
vzdump-qemu-104-2023_07_01-17_21_19.vma.zst
vzdump-qemu-104-2023_07_01-17_21_19.vma.zst.notes
root@cg2:/var/lib/vz/dump#
```
