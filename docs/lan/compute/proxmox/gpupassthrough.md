[edit](https://github.com/2cld/netstack/edit/master/docs/lan/compute/proxmox/gpupassthrough.md)

---
---
- [Jim's Garage](https://www.youtube.com/@Jims-Garage/videos) and [github](https://github.com/JamesTurland/JimsGarage/tree/main)
- TechHutTV homelab [yt1](https://www.youtube.com/watch?v=zLFB6ulC0Fg) and [yt2](https://www.youtube.com/watch?v=Uzqf0qlcQlo) and [github](https://github.com/TechHutTV/homelab/tree/main/media)
- ElectronicsWizartdy [SMB proxmox yt-videos](https://www.youtube.com/watch?v=hJHpVi9LGqc)
- NAS Shares on LXC Unpriv [yt](https://www.youtube.com/watch?v=DMPetY4mX-c)
- Split GPU between Unpriv LXC  [yt](https://www.youtube.com/watch?v=0ZDr5h52OOE)
- tbd
  
<details>
  <summary>cg2.cf2.2cld.net - proxmox setup</summary>

## cg2.cf2.2cld.net
- bing [Passing a GPU through to a Proxmox container for Plex Transcode](https://www.bing.com/videos/riverview/relatedvideo?q=how+to+pass+gpu+to+lvm+in+proxmox&mid=67909F2363653B05C73367909F2363653B05C733&FORM=VIRE) or [youtube](https://youtu.be/-Us8KPOhOCY)
- Article [lxc nvidia gpu passthrough](https://theorangeone.net/posts/lxc-nvidia-gpu-passthrough/)

- check version

```bash
uname -r
```

- I got the following

```
root@cg2:~# uname -r
6.8.12-2-pve
root@cg2:~# 
```

- Install pve-headers package

```bash
apt-cache search pve-header
apt install pve-headers-*.*.*-*-pve
```

- So I used

```bash
root@cg2:~# apt install pve-headers-6.8.12-2-pve
```

- Blacklist drivers so it does not load. Edit /etc/modprobe.d/blacklist.conf

```bash
blacklist nouveau
```

- run update-initramfs -u

```bash
update-initramfs -u
```

- reboot
- Install NVIDIA Drivers

```bash
apt install build-essential
```

- Find and pull down GTX 660 driver

```bash
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/470.256.02/NVIDIA-Linux-x86_64-470.256.02.run
```

- make executable

```bash
root@cg2:~# chmod +x NVIDIA-Linux-x86_64-470.256.02.run 
root@cg2:~# ls -al NVIDIA-Linux-x86_64-470.256.02.run 
-rwxr-xr-x 1 root root 272850014 May 23 10:43 NVIDIA-Linux-x86_64-470.256.02.run
root@cg2:~#
```

- run file

```bash
./NVIDIA-Linux-x86_64-470.256.02.run
```

- some questions are asked.. I used defaults on all
- Test by typing, see if it sees your gpu

```bash
nvidia-smi
```

- Load drivers on boot.  Edit /etc/modules-load.d/modules.conf and the following:

```bash
nvidia
nvidia-modeset
nvidia_uvm
```

- run update-initramfs -u

```bash
update-initramfs -u
```

- create udev nvidia file /etc/udev/rules.d/70-nvidia.rules

```bash
KERNEL=="nvidia", RUN+="/bin/bash -c '/usr/bin/nvidia-smi -L && /bin/chmod 666 /dev/nvidia*'"
KERNEL=="nvidia_modeset", RUN+="/bin/bash -c '/usr/bin/nvidia-modprobe -c0 -m && /bin/chmod 666 /dev/nvidia-modeset*'"
KERNEL=="nvidia_uvm", RUN+="/bin/bash -c '/usr/bin/nvidia-modprobe -c0 -u && /bin/chmod 666 /dev/nvidia-uvm*'"
```

- reboot
- list the nvidia devices

```bash
root@cg2:~# ls -l /dev/nv*
crw-rw-rw- 1 root root 195,   0 Oct 20 16:33 /dev/nvidia0
crw-rw-rw- 1 root root 195, 255 Oct 20 16:33 /dev/nvidiactl
crw-rw-rw- 1 root root 195, 254 Oct 20 16:33 /dev/nvidia-modeset
crw-rw-rw- 1 root root 235,   0 Oct 20 16:34 /dev/nvidia-uvm
crw-rw-rw- 1 root root 235,   1 Oct 20 16:34 /dev/nvidia-uvm-tools
crw------- 1 root root  10, 144 Oct 20 16:33 /dev/nvram

/dev/nvidia-caps:
total 0
cr-------- 1 root root 239, 1 Oct 20 16:33 nvidia-cap1
cr--r--r-- 1 root root 239, 2 Oct 20 16:33 nvidia-cap2
```

- Edit the conf for the container /etc/pve/lxc/<ID>.conf add

```bash
# Allow cgroup access
lxc.cgroup2.devices.allow = c 195:0 rw
lxc.cgroup2.devices.allow = c 195:255 rw
lxc.cgroup2.devices.allow = c 195:254 rw
lxc.cgroup2.devices.allow = c 235:0 rw
lxc.cgroup2.devices.allow = c 235:1 rw
lxc.cgroup2.devices.allow = c 10:144 rw
# Pass through device files
lxc.mount.entry = /dev/nvidia0 dev/nvidia0 none bind,optional,create=file
lxc.mount.entry = /dev/nvidiactl dev/nvidiactl none bind,optional,create=file
lxc.mount.entry = /dev/nvidia-modeset dev/nvidia-modeset none bind,optional,create=file
lxc.mount.entry = /dev/nvidia-uvm dev/nvidia-uvm none bind,optional,create=file
lxc.mount.entry = /dev/nvidia-uvm-tools dev/nvidia-uvm-tools none bind,optional,create=file
lxc.mount.entry = /dev/nvram dev/nvram none bind,optional,create=file
```

- Start Container, update, upgrade download nvidia drivers and install --no-kernel-module

```bash
apt update && apt upgrade -y
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/470.256.02/NVIDIA-Linux-x86_64-470.256.02.run
chmod +x NVIDIA-Linux-x86_64-470.256.02.run
./NVIDIA-Linux-x86_64-470.256.02.run --no-kernel-module
```

- reboot
- test by running nvidia-smi

</details>

---

<details>
  <summary> 101 cfPlex.cf2.2cld.net - cfPlex gpu test priv lxc</summary>

## cfPlex.cf2.2cld.net
now installing plex on container to eval it can use the gpu
- lxc 101 /etc/pve/lxc/101.conf

</details>

---

<details>
  <summary> 102 xxx.cf2.2cld.net - gpu test unpriv lxc</summary>
	
## xxx.cf2.2cld.net
now installing plex on container to eval it can use the gpu
- [youtube split GPU unpriv lxc](https://www.youtube.com/watch?v=0ZDr5h52OOE)
- lxc 102 /etc/pve/lxc/102.conf

</details>

---

<details>
  <summary>301 win11cfPlex.cf2.2cld.net - ssd passthrough of old cfPlex</summary>

## win11cfPlex.cf2.2cld.net
uses old cfPlex with ssd drive pass-through [youtube](https://www.youtube.com/watch?v=eFDcCxRS5Xk)
Tutorial on how to virtualise an old existing Windows install you might want to recover data from.

VirtIO Drivers: [https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers)

- CMD to mount SATA drives to VM (-sata can be interchanged with -scsi):
```
qm set "VM ID" -sata1 /dev/disk/by-id/ata-"MODEL"_"SN"
```
- CMD I used to connect the cfPlex SSD to 301
```
qm set 301 -sata1 /dev/disk/by-id/ata-WDC_WDBNCE0010PNC_2017A5808811
```
- Run the virtio-win-gt-x64 installer for 64-bit or -x86 for 32-bit. 

</details>

---
---
---
older notes
----
<details>
  <summary>old notes</summary>
	
- youtube [Proxmox PCIE Passthrough to Windows 11](https://www.youtube.com/watch?v=c4Gp1O7jQcA)
- [pcie-passthrough-proxmox-and-windows-11](https://gulowsen.com/post/proxmox/pcie-passthrough-proxmox-and-windows-11/)
- youtube [Proxmox GPU Passthrough To Windows 11](https://www.youtube.com/watch?v=ecFtSFCJqSg)
- [proxmox-gpu-passthrough-to-windows-10-11](https://hsve.org/proxmox-gpu-passthrough-to-windows-10-11/)
- [nvidia-kvm-patcher](https://github.com/sk1080/nvidia-kvm-patcher)
- proxmox [PCI(e)_Passthrough](https://pve.proxmox.com/wiki/PCI(e)_Passthrough)
- proxmox [NVIDIA_vGPU_on_Proxmox_VE_7.x](https://pve.proxmox.com/wiki/NVIDIA_vGPU_on_Proxmox_VE_7.x#cite_note-4)
- [gpu-passthrough-on-proxmox](https://www.wundertech.net/how-to-set-up-gpu-passthrough-on-proxmox/)
- youtube [Proxmox GPU/PCIE passthrough](https://www.youtube.com/watch?v=5ce-CcYjqe8)
  - proxmox [https://pve.proxmox.com/wiki/PCI_Passthrough](https://pve.proxmox.com/wiki/PCI_Passthrough)
  - [guide_to_gpu_passthrough](https://www.reddit.com/r/homelab/comments/b5xpua/the_ultimate_beginners_guide_to_gpu_passthrough/?utm_medium=android_app&utm_source=share)

```text

Edit GRUB
nano /etc/default/grub

Change this line from
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
to
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off"

save file and update grub
update-grub

Reboot the node
Edit the module file VFIO = Virtual Function I/O
nano /etc/modules

Add these lines
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd

save and reboot

IOMMU remapping (some systems are not good at mapping the IOMMU, this will help)
nano  /etc/modprobe.d/iommu_unsafe_interrupts.conf
options vfio_iommu_type1 allow_unsafe_interrupts=1

nano /etc/modprobe.d/kvm.conf
options kvm ignore_msrs=1

Blacklist the GPU drivers (this will kkeep the host system from trying to use the new GPU)
nano /etc/modprobe.d/blacklist.conf

blacklist radeon
blacklist nouveau
blacklist nvidia
blacklist nvidiafb

Adding GPU to VFIO
lspci -v

Look for your GPU and take note of the first set of numbers this is your PCI card address.
Then run this command
lspci -n -s (PCI card address)

This command gives use the GPU vendors number.
Use those numbers in this command
nano /etc/modprobe.d/vfio.conf

options vfio-pci ids=(GPU number,Audio number) disable_vga=1

Run this command to update everything
update-initramfs -u

Then restart the server.

Make a new VM
Bios is OMVF(UEFI)
Machine is q35
Start the new VM and make sure remote desktop is active and find the IP Adress

```

# Nvidia vGPU on Proxmox
- Craft Computing [Eight Gaming PCs in a 1U Server - Cloud Gaming Server Part 16](https://www.youtube.com/watch?v=pIdCV1H1_88&t=198s)
- Craft Computing [Proxmox GPU Virtualization](https://www.youtube.com/watch?v=jTXPMcBqoi8)
- Craft Computing [google doc txt file](https://drive.google.com/drive/folders/1KHf-vxzUCGqsWZWOW0bXCvMhXh5EJxQl)

```

---INSTALL DEPENDENCIES---


echo 'deb http://download.proxmox.com/debian/pve buster pve-no-subscription' >> /etc/apt/sources.list
apt update
apt -y upgrade
apt -y install git build-essential pve-headers dkms jq mdevctl

git clone https://github.com/DualCoder/vgpu_unlock
git clone https://github.com/mbilker/vgpu_unlock-rs
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

wget http://download.proxmox.com/debian/dists/bullseye/pve-no-subscription/binary-amd64/pve-headers-5.15.30-2-pve_5.15.30-3_amd64.deb 

dpkg -i pve-headers-5.......

Download v14.0 nVidia vGPU Drivers for Linux KVM from https://nvid.nvidia.com
You will need to apply for a 90-day trial to have access to the drivers
A business email address is required

The file needed from the ZIP file is "NVIDIA-Linux-x86_64-510.47.03-vgpu-kvm.run"


REBOOT


---CONFIGURE IOMMU---

nano /etc/default/grub

GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
	- OR -
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"

Save file and close

update-grub

-Load VFIO modules at boot-

nano /etc/modules

echo 'vfio' >> /etc/modules
echo 'vfio_iommu_type1' >> /etc/modules
echo 'vfio_pci' >> /etc/modules
echo 'vfio_virqfd' >> /etc/modules

Save file and close

echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf

update-initramfs -u

REBOOT


---INSTALL NVIDIA + VGPU_UNLOCK---


chmod -R +x vgpu_unlock
chmod +x NVIDIA------.run

./NVIDIA------.run --dkms

nano /usr/src/nvidia-510.85.03/nvidia/os-interface.c
#include "/root/vgpu_unlock/vgpu_unlock_hooks.c"

nano /usr/src/nvidia-450.80/nvidia/nvidia.Kbuild
ldflags-y += -T /root/vgpu_unlock/kern.ld

cd vgpu_unlock-rs
cargo build --release

mkdir /etc/systemd/system/nvidia-vgpud.service.d
mkdir /etc/systemd/system/nvidia-vgpu-mgr.service.d

nano /etc/systemd/system/nvidia-vgpud.service.d/vgpu_unlock.conf

[Service]
Environment=LD_PRELOAD=/root/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so

nano /etc/systemd/system/nvidia-vgpu-mgr.service.d/vgpu_unlock.conf

[Service]
Environment=LD_PRELOAD=/root/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so


REBOOT


---DEFINE GPU PROFILES---

mkdir /etc/vgpu_unlock
nano /etc/vgpu_unlock/profile_override.toml

[profile.nvidia-18]
num_displays = 1
display_width = 1920
display_height = 1080
max_pixels = 2073600
cuda_enabled = 1
frl_enabled = 60
framebuffer = 11811160064
pci_id = 0x17F011A0
pci_device_id = 0x17F0


Resolution
	- width x height = max_pixels#


Video Memory
	- framebuffer sizes
		- 1GB = 984263338       0x3AAAAAAA
		- 2GB = 1968526677      0x75555555
		- 3GB = 2952790016      0xB0000000
		- 4GB = 3937053354      0xEAAAAAAA
		- 6GB = 5905580032      0x160000000
		- 8GB = 7874106708      0x1D5555554
		- 10GB = 9842633380     0x24AAAAAA4
		- 11GB = 10826896718    0x28555554E
		- 12GB = 11811160064    0x2C0000000
		- 16GB = 15748213408    0x3AAAAAAA0
		- 24GB = 23622320124    0x57FFFFFFC


PCI IDs
	- pci_id = 0x####@@@@ (Device ID followed by SubSystem ID)
	- pci_device_id = 0x#### (Device ID only)

		Architecture	Card		pci_device_id	pci_id
		- Maxwell	Quadro M6000	0x17F011A0	    0x17F0
		- Pascal	Quadro P6000	0x1B3011A0	    0x1B30
		- Volta		Quadro GV100	0x1DBA121A	    0x1DBA
		- Turing	Quadro RTX 6000	0x1E3012BA	    0x12BA
		- Kepler			(currently not supported)
		- Ampere 			(currently not supported)


nano /etc/pve/qemu/[VM#].conf

args: -uuid 00000000-0000-0000-0000-000000000###


Add PCIe device to target VM
Select the GPU you added in mdevctl

Launch VM, install either Linux or Windows 10/11
Install nVidia Driver 511.73, matching the Quadro PCI-ID you entered earlier

Disable Display #1 in Display Settings
Install Parsec, Sunshine/Moonlight, SteamPlay, or other streaming server

Parsec
https://parsec.app/

Sunshine Streaming Server
https://github.com/loki-47-6F-64/sunshine

Moonlight Streaming Client
https://moonlight-stream.org/
```

</details>
