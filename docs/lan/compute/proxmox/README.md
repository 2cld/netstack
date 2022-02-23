# Proxmox

- [https://www.proxmox.com/en/downloads/category/iso-images-pve](https://www.proxmox.com/en/downloads/category/iso-images-pve)
- [Youtube - Plex on ProxMox Tutorial WITH nVidia Hardware Encoding](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=77s)
- [Youtube - Proxmox vGPU Gaming Tutorial - Share Your GPU With Multiple VMs](https://www.youtube.com/watch?v=cPrOoeMxzu0)
- [Youtube - Virtualizing An Internal Network With pfSense In ProxMox](https://www.youtube.com/watch?v=V6di1EAovN8)
- [Youtube - Virtualize Windows 10 with Proxmox VE](https://www.youtube.com/watch?v=6c-6xBkD2J4)
- [Youtube - Proxmox Full Course](https://www.youtube.com/playlist?list=PLT98CRl2KxKHnlbYhtABg6cF50bYa8Ulo)
- [Youtube - ]()
- [Youtube - ]()
- [Youtube - ]()
- [Youtube - ]()

## Network
- [ng - ASUS - http://192.168.2.1/Advanced_DHCP_Content.asp](http://192.168.2.1/Advanced_DHCP_Content.asp)
- [sg - truenas scale - http://192.168.2.2/ui/dashboard](http://192.168.2.2/ui/dashboard)
- [cg - proxmox - https://192.168.2.3:8006/](https://192.168.2.3:8006/)
- 
## Setup
- [Youtube - Before I do anything on Proxmox, I do this first](https://www.youtube.com/watch?v=GoZaMgEgrHw) commandline document [Techno Tim - Document](https://docs.technotim.live/posts/first-11-things-proxmox/) quickstart documents [Techno Tim - launchpad](https://github.com/techno-tim/launchpad)

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
   - [Proxmox Windows VirtIO Drivers](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers) download [virtio-win latest stable](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)
- [11:45](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=705s)  - How to upload Windows / Ubuntu ISO to Proxmox
- [11:52](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=712s)  - How to create a NIC team (LACP, LAG) on Proxmox
- [13:51](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=831s)  - How to set up an aggregate (LACP, Team) on Unifi Switch Pro
- [15:10](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=910s)  - How to edit your NIC bond in Proxmox for NIC teaming
- [17:26](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=1046s)  - How to create a virtual machine template on Proxmox
- [17:59](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=1079s)  - How to clone a virtual machine in Proxmox
- [18:42](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=1122s)  - How to fix Proxmox Linux clone NIC, machine ID, and ssh keys after cloning
- [19:46](https://www.youtube.com/watch?v=GoZaMgEgrHw&t=1186s)  - How to create a Proxmox Cluster


## Ubuntu nsweb100 - VM 100
- After first boot
    ```
    nsadmin@nsweb100:~$ sudo apt update && sudo apt dist-upgrade
    nsadmin@nsweb100:~$ sudo dpkg --configure -a
    nsadmin@nsweb100:~$ systemctl status qemu-guest-agent.service 
    ● qemu-guest-agent.service - QEMU Guest Agent
         Loaded: loaded (/lib/systemd/system/qemu-guest-agent.service; static; vendor preset: enabled)
         Active: inactive (dead)
    nsadmin@nsweb100:~$ sudo poweroff
    ```
- In VM 100 Options -> OEMU Guest Agent Enabled
- Restart VM

## Ubuntu nsweb100 - VM 100 [Create Template](https://www.youtube.com/watch?v=t3Yv4OOYcLs&list=PLT98CRl2KxKHnlbYhtABg6cF50bYa8Ulo&index=7)
- Verify cloud-init is installed
   ```
   nsadmin@nsweb100:~$ apt search cloud-init
   ```
- Remove ssh host keys
   ```
   nsadmin@nsweb100:~$ cd /etc/ssh
   nsadmin@nsweb100:/etc/ssh$ sudo rm ssh_host_*
   [sudo] password for nsadmin: 
   nsadmin@nsweb100:/etc/ssh$ 
   ```
- Empty the machine-id verify dbus is link
   ```
   nsadmin@nsweb100:/etc/ssh$ cat /etc/machine-id 
   685018d745174d9e95f638d501a91d42
   nsadmin@nsweb100:/etc/ssh$ sudo truncate -s 0 /etc/machine-id
   nsadmin@nsweb100:/etc/ssh$ ls -l /var/lib/dbus/machine-id 
   lrwxrwxrwx 1 root root 15 Feb 22 22:25 /var/lib/dbus/machine-id -> /etc/machine-id
   ```
- Cleanup
   ```
   nsadmin@nsweb100:/etc/ssh$ sudo apt clean
   nsadmin@nsweb100:/etc/ssh$ sudo apt autoremove
   Reading package lists... Done
   Building dependency tree       
   Reading state information... Done
   0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
   nsadmin@nsweb100:/etc/ssh$ sudo poweroff
   ```
- In Proxmox UI right-click vm 100 -> Convert to Template
- Hardware -> Remove CD/DVD with install iso
- Hardware -> Add -> CloudInit Drive use same storage as old vm
- Cloud-Init -> Edit User and Password -> Regenerate Image

---

## Plex on Proxmox [Youtube - Plex on ProxMox Tutorial WITH nVidia Hardware Encoding](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=77s)


[01:46](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=106s) - Plex Install
- CPU - 4
- Memory - 4096
- [Plex repo for linux](https://support.plex.tv/articles/235974187-enable-repository-updating-for-supported-linux-server-distributions/)
- Generate new ssh hosts keys
   ```
   sudo ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
   sudo ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
   ```
- Add Repo and apt-key
   ```
   echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
   
   curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
   
   sudo apt update
   
   sudo apt install plexmediaserver
   
   sudo apt upgrade
   ```
- Open web [https://192.168.2.87:32400/web]()

[06:20](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=380s) - Plex Mount Network Share
- Add Storage
  ```
  nsadmin@nsweb100:~$ sudo vi /etc/fstab
  
  # PlexMedia mount
  //192.168.2.2/cfplex /PlexMedia cifs username=xxx,password=xxx 0 0
  ```
- sudo mkdir /PlexMedia
- Restart
- Verify Storage
   ```
   nsadmin@nsweb100:~$ cd /PlexMedia
   nsadmin@nsweb100:/PlexMedia$ ls
   'Application Support'   DVRAnimation   DVRDrWho   DVRSitCom   DVRStarTrek   plexdatabackup
   ```
- Add Libraries via Plex interface 
- nsadmin@nsweb100:~$ sudo service plexmediaserver stop
- nsadmin@nsweb100:~$ sudo umount /PlexMedia
- nsadmin@nsweb100:~$ sudo mount -a

[09:22](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=562s) - CPU Transcoding
[11:19](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=679s) - PCIe Passthrough - ProxMox settings
- nsadmin@nsweb100:~$ sudo halt -p
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
- tbd
- tbd

[16:37](https://www.youtube.com/watch?v=-HCzLhnNf-A&t=997s) - PCIe Passthrough - VM Settings
- Go to plexnvidia vm 901
- Hardware -> Add -> PCIDevice -> 0000:01:00.0 NVidia G98 
- Start VM
- lspci and confirm NVidia card is showing up
   ```
    nsadmin@nsweb100:~$ lspci
    00:00.0 Host bridge: Intel Corporation 440FX - 82441FX PMC [Natoma] (rev 02)
    00:01.0 ISA bridge: Intel Corporation 82371SB PIIX3 ISA [Natoma/Triton II]
    00:01.1 IDE interface: Intel Corporation 82371SB PIIX3 IDE [Natoma/Triton II]
    00:01.2 USB controller: Intel Corporation 82371SB PIIX3 USB [Natoma/Triton II] (rev 01)
    00:01.3 Bridge: Intel Corporation 82371AB/EB/MB PIIX4 ACPI (rev 03)
    00:02.0 VGA compatible controller: Device 1234:1111 (rev 02)
    00:03.0 Unclassified device [00ff]: Red Hat, Inc. Virtio memory balloon
    00:05.0 SCSI storage controller: Red Hat, Inc. Virtio SCSI
    00:08.0 Communication controller: Red Hat, Inc. Virtio console
    00:10.0 VGA compatible controller: NVIDIA Corporation G98 [Quadro NVS 295] (rev a1)
    00:12.0 Ethernet controller: Red Hat, Inc. Virtio network device
    00:1e.0 PCI bridge: Red Hat, Inc. QEMU PCI-PCI bridge
    00:1f.0 PCI bridge: Red Hat, Inc. QEMU PCI-PCI bridge
   ```
- Download NVidia Drivers [https://www.nvidia.com/download/index.aspx](https://www.nvidia.com/download/index.aspx)
   ```
   wget https://us.download.nvidia.com/XFree86/Linux-x86_64/340.108/NVIDIA-Linux-x86_64-340.108.run
   
   sudo chmod +x NVIDIA-Linux-x86_64-###.##.##.run
   ```
- Disable nouveau drivers [tbd]()
   ```
   sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
   sudo bash -c "echo options nouveau modset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
   
   sudo update-initramfs -u
   
   sudo reboot
   ```
- Install nVidia Drivers
   ```
   sudo apt update
   sudo apt install build-essential libglvnd-dev pkg-config

   ./NVIDIA-Linux-x86_64-###.##.##.run

   ```
- Confirm GPU is using nvidia drivers
   ```
   lspci -v
   
   Kernel driver in use: nvidia
   ```
- Fix nVidia vm issue
   ```
   nsadmin@nsweb100:~$ nvidia-smi
   Unable to determine the device handle for GPU 0000:00:10.0: Unknown Error
   
   sudo halt -p
   ```
- SSH into ProxMox ssh root@192.168.2.3
   ```
  cd /etc/pve/qemu-server

  vi ###.conf (# is the VM identifier of your Plex server)
    root@cg:~# cd /etc/pve/qemu-server
    root@cg:/etc/pve/qemu-server# ls
    100.conf  901.conf
    root@cg:/etc/pve/qemu-server# vi 901.conf
  Modify cpu line...

  cpu: host,hidden=1

  Save file and exit.
  ```
- Start Plex VM.
- nvidia-smi to confirm GPU is working this basically froze the vm

## Attempt cleanup [Proxmox GPU/PCIE passthrough](https://www.youtube.com/watch?v=5ce-CcYjqe8)
- [Proxmox PCI passthrough doc](https://pve.proxmox.com/wiki/Pci_passthrough)
- [reddit GPU Passthrough Proxmox Windows 10](https://www.reddit.com/r/homelab/comments/b5xpua/the_ultimate_beginners_guide_to_gpu_passthrough/)
- Updates to proxmox grub
   ```
   vi /etc/default/grub
   
   GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off"
   
   update-grub
   
   reboot
   ```
- Verify modules
   ```
    root@cg:~# cat /etc/modules
    # /etc/modules: kernel modules to load at boot time.
    #
    # This file contains the names of kernel modules that should be loaded
    # at boot time, one per line. Lines beginning with "#" are ignored.
    vfio
    vfio_iommu_type1
    vfio_pci
    vfio_virqfd
    
    reboot
   ```
- [tbd]()
   ```
   ```
- [tbd]()
   ```
---

## New Topic [tbd]()

- [tbd]()
   ```
   ```
- [tbd]()
   ```
   ```
