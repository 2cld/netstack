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
- 

---
---
---
---
# update 2024.04.21 cleanup from ghadmin
cg2.cf.2cld.net

- [Setting up NAS on Proxmox youtube](https://www.youtube.com/watch?v=AP61_ETd2GE)
- [https://www.twingate.com](https://www.twingate.com) like zerotier [Network Chuck - youtube on twingate](https://www.youtube.com/watch?v=IYmXPF3XUwo)
- [https://www.cloudron.io/get.html](https://www.cloudron.io/get.html) - app installer ?
- [https://www.freenom.com/en/index.html?lang=en](https://www.freenom.com/en/index.html?lang=en) - free domains but not working right now
- [https://www.cloudflare.com](https://www.cloudflare.com) free cdn and revprox
- [https://openwrt.org/toh/hwdata/buffalo/buffalo_wzr-600dhp](https://openwrt.org/toh/hwdata/buffalo/buffalo_wzr-600dhp) - openwrt for buffalo wzr-600dhp
- [PDF for Buffalow wzr-600DHP](https://images10.newegg.com/UploadFilesForNewegg/itemintelligence/Buffalo/35013156_01_EN1411782976303.pdf)
- [Homelab 2024 - TechoTim](https://www.youtube.com/watch?v=MpaAu3HVDYE)
- [Portainer 2 with K8s - TechoTim](https://www.youtube.com/watch?v=jzhd6tcjvw0)
- [netbot.xyz - iPXE networkboot](https://netboot.xyz/docs/selfhosting) like [RackN](https://rackn.com/rebar/)
- [Portainer via Proxmox Installer](https://www.youtube.com/watch?v=3vHHgLN-Cxw)
- [Portainer on Proxmox LXC](https://www.youtube.com/watch?v=mXNbIXmV3ZU)
- [Craft Computing - PCI Passthrough](https://www.youtube.com/watch?v=_hOBAGKLQkI)
- 
Setting up cg2 in cf.
- [ ] Move this stuff to [netstack.org/docs/lan/cg/proxmox](https://netstack.org/docs/lan/compute/proxmox)
- [ ] [Virtualise Existing Windows Install using Proxmox](https://www.youtube.com/watch?v=eFDcCxRS5Xk)
	- [ ] [VirtIO Drivers Download](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers)
	- [ ] [MS Disk2vhd Download](https://learn.microsoft.com/en-us/sysinternals/downloads/disk2vhd)
	- [ ] [Things to do on Fresh ProxMox](https://www.youtube.com/watch?v=xD9Xyt2mdSI)
	- [ ] [Convert Physical to ProxMox VM](https://www.youtube.com/watch?v=4fP-ilAo_Ks)
	- [ ] [Virtualize existing Windows using ProxMox](https://www.youtube.com/watch?v=eFDcCxRS5Xk)
	- [ ] [Clone Windows with dd](https://www.youtube.com/watch?v=M7_U-QkAmNo)
	- [ ] [Clone WIndows](https://www.youtube.com/watch?v=uE9xMNidGEo)
	- [ ] [Virtualize Windows 11 with ProxMox](https://www.youtube.com/watch?v=fupuTkkKPDU)
	- [ ] 
- [ ] P2V CyberTruck [Convert BM Win to Proxmox P2V](https://www.youtube.com/watch?v=I4LFm4Qbffs)
	- [ ] [Commands  https://hsve.org/p2v/](https://hsve.org/p2v/)
	- [ ] Create VM
		- [x] General
			- [x] Node: cg2
			- [x] VM ID: 811
			- [x] Name: p2vCybertruck
		- [x] OS
			- [x] Do not use any media
			- [x] Type: Windows 11
		- [x] System
			- [x] Graphics card: Default
			- [x] Machine q35
			- [x] BIOS: UEFI
			- [x] Add EFI Disk: checked
			- [x] EFI Storage: local-lvm
			- [x] Format: QEMU (qcow2)
			- [x] Pre-Enroll keys: unchecked
			- [x] SCSI Controller: VirtIO SCSI single
			- [x] QemuAgent: checked
			- [x] Add TPM: checked
			- [x] TPM Storage: local-lvm
		- [x] Disks
			- [x] Delete all disks
		- [x] CPU
			- [x] Sockets: 1
			- [x] Cores: 4
			- [x] Type: x86-64-v2-AES (Default)
			- [x] Rest leave default
		- [x] Memory
			- [x] Memory: 8192
		- [ ] Network
			- [ ] Bridge: vmbr0
			- [ ] Model: Intel E1000
			- [ ] Firewall: unchecked
		- [ ] Verify Settings -> Finish
	- [ ] in shell Find disks
	```
	find /dev/disk/by-id/ -type l|xargs -I{} ls -l {}|grep -v -E '[0-9]$' |sort -k11|cut -d' ' -f9,10,11,12
	```
	- [ ] in shell Set sata1
	```
	qm set 881 -sata1 /dev/disk/by-id/[Replace]
	```
	- [ ] Install drivers
	- [ ] Set scsi1
	```
	qm set 881 -scsi1 /dev/disk/by-id/[Replace]
	```
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
- Detect Motherboard on Windows 11
	- Run msinfo32
	- export to [cfPlex-msinfo32-export.txt](:/4515262bcc5e4c4794038e7570184222)
	- 
## CyberTruck
- Detect Motherboard on Windows 11
	- Run msinfo32
	- export to [CyberTruck-msinfo32-export.txt](:/4515262bcc5e4c4794038e7570184222)
	- Asus Tuf-x299 [Asus product link](https://www.asus.com/motherboards-components/motherboards/others/tuf-x299-mark-2/) [ pdf manual download](https://dlcdnets.asus.com/pub/ASUS/mb/LGA2066/TUF_X299_MARK1/E12783_TUF_X299_MARK1_UM_WEB_20170706.pdf?model=TUF%20X299%20MARK%201)
	- pdf saved to catStorage


# pfSense for cf in sl

- [https://netstack.org/docs/lan/network/pfsense/setup](https://netstack.org/docs/lan/network/pfsense/setup)
- [Network Chuck - pfSense Install](https://youtu.be/lUzSsX4T4WQ)
- 

## pfSense vm on slwin11 vbox
- System General Setup [https://192.168.6.1/system.php](https://192.168.6.1/system.php)
	- Hostname: sl-cf-pfSense
	- Domain: slcf2cld.lan
	- DNS: 1.1.1.1 (cloudflare)
	- DNS: 8.8.8.8 (google)
	- DNS Server Override: unchecked
	- TimeZone: US/Central
- WAN [https://192.168.6.1/interfaces.php?if=wan](https://192.168.6.1/interfaces.php?if=wan)
	- DHCP
	- Block private Networks: uncheck (we will have a 192.168.0.0 wan IP)
	- Block bogon networks: uncheck
- LAN [https://192.168.6.1/interfaces.php?if=lan](https://192.168.6.1/interfaces.php?if=lan)
	- IPv4 Address: 192.168.6.1/24 (to match cf subnet)
- DHCP Server [https://192.168.6.1/services_dhcp.php](https://192.168.6.1/services_dhcp.php)
	- Address Pool Range: 192.168.6.10 - 245
- DHCP Leases [https://192.168.6.1/status_dhcp_leases.php](https://192.168.6.1/status_dhcp_leases.php)
- Port Forward: [https://192.168.6.1/firewall_nat.php](https://192.168.6.1/firewall_nat.php)
	- tbd
- tbd
  
