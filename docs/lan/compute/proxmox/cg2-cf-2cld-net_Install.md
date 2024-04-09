[edit]()

cg2.cf-2cld-net_Install current doc is in christrees Joplin cg2.cf.2cld.net

last update below was on 2024.04.09

---

cg2.cf.2cld.net

Setting up cg2 in cf.
- [ ] test
- [ ] test
- [ ] test



## cg2.cf.2cld.net
- [cf.2cld.net/docs](https://cf.2cld.net/docs)
- [netstack.org/docs/lan/cg/proxmox](https://netstack.org/docs/lan/compute/proxmox)
- [zfs on proxmox truenas import](https://forum.proxmox.com/threads/migrating-zfs-from-truenas-to-proxmox.131634/)
- [cg2 - https://192.168.6.7:8006/](https://192.168.6.7:8006/) root - Time2Invest

## win11 vm on proxmox
- [win11 vm https://gulowsen.com/post/proxmox/proxmox-windows11-vm/](https://gulowsen.com/post/proxmox/proxmox-windows11-vm/)
- [virtio-win.iso download](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)
- VM Config
- General
	- Node: cg2
	- VM ID: 101
	- Name: win11sg2vm101
	- Start at boot: checked
- OS
	- Storage: local
	- ISO image: Select the ISO file for windows.
	- Type: Microsoft Windows. 
	- Version: Change to the windows version you wish to install.
- System
	- Machine: q35.
	- BIOS: Microsoft have it as a requirement to use UEFI so switch over to OVMF (UEFI).
	- Add EFI Disk and EFI Storage: EFI Disk should to be checked for Windows. You can do without it, but it is a backup in case the boot part of windows gets corrupted. For EFI Disk you Should use the same storage you plan to use for the VM disk.
	- SCSI Controller: Set this to VirtIO SCSI if not already.
	- Add TPM TPM is a requirement for Windows 11 and luckily Proxmox can virtualize it. So even if your machine does not have the required hardware, you are able to install Windows 11 as a guest OS.
	- TPM Storage As EFI Storage this should point to the drive you plan to setup the disk for the VM on.
	- Version Make sure V2.0 is selected if you are installing Windows 11.
- Disk
	- Bus Device: SCSI for compatibility.
	- Storage: For extra speed I will be using the NVME SSD I have in the system. It is also the same drive as I used in the previous steps.
	- Disk size: 64 Gigabytes or more.
	- Cache: I set this to "write back" as it is the most stable option according to the Proxmox wiki
- CPU
	- Sockets: My system only have 1 processor so this will be staying at 1 for me. If you have more cores in your system, you can allocate both and give cores from both of them.
	- Cores: I usually give systems access to half of the cores. That way they should have enough power and I don't have to worry about runaway processor usage.
	- Type: There is a range of CPU types you can make it look like you have but I will just passthrough host as the type.
	- Extra CPU Flags: There are loads of other CPU flags you can change, none of which I touch.
- Memory
	- Memory: For now I am allocating 8 gigabyte's of memory to this VM. It is double what is needed but installation usually is a bit faster with more memory. This can easily be changed later.
	- Minimum memory: This is to make sure a VM will have enough memory for what you wish even if you enable ballooning.
	- Ballooning Device: Check this to enable Ballooning. When enabled, the VM will only be allocated the amount of memory it is actually using. This will give you the possibility to allocate more memory than you actually have, but be aware that this may cause start up problems and crashes.
- Network
	- Bridge: This is the virtual network interface. You can add more after the initial setup.
	- VLAN Tag: Here you can enter a VLAN tag for which VLAN you wish your VM to be in. The tag is a number that can be between 1 and 4094.
	- Model: There are different types of network interface cards you can simulate. Most will make the VM think there is a cable connected. VirtIO will just come up as virtualized. Some operating systems may require one specific type.
	- MAC address: Here you are able to set a specific mac address if you require that.
	- Disconnect: Checking this simulates taking out a network cable. It can be helpful when you try different things and need to disconnect without deleting the entire network configuration.
- Confirm
	- Start after created: __NOT CHECKED__  As it says, The VM will start after you hit Finish. __Do not do it__ with Windows virtual machines because there are one additional step.
- More ISO's
	- Additional ISO Unlike Linux, Windows need a few additional drivers to get up and running
	- A: Select your windows VM in the server view.
	- B: Click Hardware
	- C: Clicking Add will open a drop down menu with additional hardware you can add. This includes both virtual and physical items.
	- D: To add the VirtIO ISO, click CD/DVD Drive.
	- E: Like when you configure the VM you can choose which storage and ISO image. Select the virtio-win.iso file.
	- F: Click Add to add the additional ISO addition.
- Install Windows
	- Use Custom, no keys, Windows 11 Pro
	- Storage -> Add Drivers -> 
	- Steps for adding the hard drive driver:
		- Start with Load driver.
		- Then click Browse.
		- Choose CD Drive virtio-win-"version".
		- Scroll down and expand vioscsi.
		- Expand w11 folder for Windows 11. As long as you are using a system with a normal processor, click amd64.
		- Click ok then next to install the driver. The hard drive should now show up in the setup window. You can at this point click next to continue if you don't want the network driver installed yet.
	- Steps for adding the network driver:
		- Start with Load driver.
		- Then click Browse.
		- Choose CD Drive virtio-win-"version".
		- Scroll down and expand NetKVM.
		- Expand w11 folder for Windows 11.  As long as you are using a system with a normal processor, click amd64.
		- Click ok then next to install the driver.  You will not see anything extra when this is installed but Windows will be able to do some updates during installation.
		- Next unless you wish to format the drive in a specific way click Next to continue.
	- Waiting time! The amount of time this will take varies on what resources and type of disk you have allocated to the virtual machine. After the Windows have been installed it will reboot.
- Windows setup
	- After the machine have rebooted, you will be prompted to setup Windows. Windows will reboot multiple times during the setup.
	- The first you will setup again is your country and keyboard layout. If you installed the driver for the network, the system will start updating then restart.
	- Let's name your device: Type in the name you want your VM to have. It will reboot again.
	- Personal or work/school use: For a regular setup with no domain or organization control you should just set it up for personal use.
	- User account You can either log in with your Microsoft account or you can create an offline account. Offline accounts might only be available for Windows pro. I have not tested the home variant enough to be sure.
- Create offline account
	- To create an offline account simply click the options below in each menu.
	- A: Sign-in options
	- B: Offline account
	- C: Skip for now
	- and a whole lot of avoiding creating an online account


## cfPlex 
- Asus Motherboard p9x79_ws
- [doc link](https://www.asus.com/commercial-servers-workstations/p9x79_ws/specifications/)
- max ram 64GB 8x8GB

## CyberTruck
- MSI Mother
