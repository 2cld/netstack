[edit]()

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
```
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
