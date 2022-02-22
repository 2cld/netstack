# Proxmox

- [https://www.proxmox.com/en/downloads/category/iso-images-pve](https://www.proxmox.com/en/downloads/category/iso-images-pve)
- [Youtube - Plex on ProxMox Tutorial WITH nVidia Hardware Encoding](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=77s)
- [Youtube - Proxmox vGPU Gaming Tutorial - Share Your GPU With Multiple VMs](https://www.youtube.com/watch?v=cPrOoeMxzu0)
- [Youtube - Virtualizing An Internal Network With pfSense In ProxMox](https://www.youtube.com/watch?v=V6di1EAovN8)
- [Youtube - Virtualize Windows 10 with Proxmox VE](https://www.youtube.com/watch?v=6c-6xBkD2J4)
- [Youtube - ]()
- [Youtube - ]()
- [Youtube - ]()
- [Youtube - ]()
- [Youtube - ]()


## Setup
- [Youtube - Before I do anything on Proxmox, I do this first](https://www.youtube.com/watch?v=GoZaMgEgrHw)

- [01:26](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=86s) Install the latest version of [Proxmox - iso-images-pve](https://www.proxmox.com/en/downloads/category/iso-images-pve)
- [01:51](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=111s) How to update Proxmox without a subscription
    - ssh root@192.168.2.3
    - root@cg:~# vi /etc/apt/sources.list  add following
      ```
      # not for production
      deb http://download.proxmox.com/debian bullseye pve-no-subscription
      ```
    - vroot@cg:~# vi /etc/apt/sources.list.d/pve-enterprise.list  comment out line
      ```
      # deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise
      ```      
    - root@cg:~# apt update
    - root@cg:~# apt dist-upgrade
    - This can be done through the UI under Update
- [03:10](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=190s)  How to configure Proxmox storage (ZFS + RAID10)
- [05:32](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=332s)  How to setup SMART monitoring with proxmox
- [06:18](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=378s)  How to turn on PCI Passthrough with Proxmox (IOMMU)
    - [Plex on ProxMox Tutorial WITH nVidia](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=679s)
    - [ProxMox PCIpassthrough docs](https://pve.proxmox.com/wiki/Pci_passthrough)
    - [Guide to GPU in ProxMox](https://www.reddit.com/r/homelab/comments/b5xpua/the_ultimate_beginners_guide_to_gpu_passthrough/)
    - Turn on VT-d in Bios
    - root@cg:~# vi /etc/default/grub
      ```
      GRUB_DEFAULT=0
      GRUB_TIMEOUT=5
      GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
      # GRUB_CMDLINE_LINUX_DEFAULT="quiet"
      GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
      GRUB_CMDLINE_LINUX=""
      ```
    - root@cg:~# update-grub
    - root@cg:~# vi /etc/modules
      ```
      vfio
      vfio_iommu_type1
      vfio_pci
      vfio_virqfd
      ```
    - IOMMU interrupt remapping
      ```
      echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
      echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
      ```
    - Blacklist NVidia drivers
      ```
      echo "blacklist radeon" >> /etc/modprobe.d/blacklist.conf
      echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
      echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
      ```
    - shutdown computer and install NVidia Quadro NVS 295
    - Find the video card via: 
      ```
      root@cg:~# lspci -v
      ```
    - Find NVidia card
      ```
        01:00.0 VGA compatible controller: NVIDIA Corporation G98 [Quadro NVS 295] (rev a1) (prog-if 00 [VGA controller])
          Subsystem: Device 30de:0000
          Flags: bus master, fast devsel, latency 0, IRQ 32, IOMMU group 1
          Memory at 96000000 (32-bit, non-prefetchable) [size=16M]
          Memory at 90000000 (64-bit, prefetchable) [size=64M]
          Memory at 94000000 (64-bit, non-prefetchable) [size=32M]
          I/O ports at 2000 [size=128]
          Expansion ROM at 000c0000 [disabled] [size=128K]
          Capabilities: [60] Power Management version 3
          Capabilities: [68] MSI: Enable+ Count=1/1 Maskable- 64bit+
          Capabilities: [78] Express Endpoint, MSI 00
          Capabilities: [100] Virtual Channel
          Capabilities: [128] Power Budgeting <?>
          Capabilities: [600] Vendor Specific Information: ID=0001 Rev=1 Len=024 <?>
          Kernel driver in use: nouveau
          Kernel modules: nvidiafb, nouvea
      ```
   - Take card out of os pool
     ```
     root@cg:~# lspci -n -s 01:00
     01:00.0 0300: 10de:06fd (rev a1)
     ```
   - Disable card so it can be used by vm update and reboot
     ```
     echo "options vfio-pci ids=10de:06fd disable_vga=1"> /etc/modprobe.d/vfio.conf
     update-initramfs -u
     reset
     ```
- [07:57](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=477s)  How to use VLANs with Proxmox and VLAN Aware
- [09:01](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=541s)  How to set up a NFS share with Proxmox
- [09:54](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=594s)  - How to schedule backups with Proxmox
- [10:53](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=653s)  - How to back up a virtual machine on Proxmox (initial backup)
- [11:13](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=673s)  - How to upload the VirtIO ISO to Proxmox
- [11:45](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=705s)  - How to upload Windows / Ubuntu ISO to Proxmox
- [11:52](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=712s)  - How to create a NIC team (LACP, LAG) on Proxmox
- [13:51](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=831s)  - How to set up an aggregate (LACP, Team) on Unifi Switch Pro
- [15:10](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=910s)  - How to edit your NIC bond in Proxmox for NIC teaming
- [17:26](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=1046s)  - How to create a virtual machine template on Proxmox
- [17:59](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=1079s)  - How to clone a virtual machine in Proxmox
- [18:42](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=1122s)  - How to fix Proxmox Linux clone NIC, machine ID, and ssh keys after cloning
- [19:46](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=1186s)  - How to create a Proxmox Cluster
