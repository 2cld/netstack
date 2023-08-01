[edit](https://github.com/2cld/netstack/edit/master/docs/ops/backup/vortexbox/README.md)

## ISO for proxmox
VBA 2.4 is based on Fedora 23 so compare processor and MOBO requirements to Fedora 23. Minimum Requirements: 
- Processor 1 Gigahertz x86_64
- RAM 1 Gigabyte (2-4GB)
- Operating System 10GB HDD space (30GB)
- Video 800 by 600

- [vortexbox download for ovf template](https://wiki.vortexbox.org/available_images#vortexbox_23_ovf_templates)

## OVA for VirtualBox on win11 gusGram
1. Copy OVA to gusGram node [vortexbox download](https://wiki.vortexbox.org/available_images#vortexbox_23_ovf_templates)
2. On gusGram node
   - Unzip vortexbox23.ova
   - import vortexbox23.ovf
3. On VirtualBox GUI 
   - change display name
   - Hardware: add network device vmbr0
   - Options: verify boot order
4. boot vm and verify

## OVA for ProxMox
1. Copy OVA to proxmox node
   - scp vortexbox23.ova ghadmin@192.168.0.3:/tmp/
2. On proxmox node
   - ssh ghamdin@192.168.0.2
   - tar -xvf vortexbox23.ova
   - qm importovf 110 vortexbox23.ovf local-lvm --format qcow2
3. On proxmox GUI [https://192.168.0.3:8006/](https://192.168.0.3:8006/)
   - change display name
   - Hardware: add network device vmbr0
   - Options: verify boot order
4. boot vm and verify

   
## OVA for Hyper-V
1. Convert OVA to VHD Format
   - download gemu-img.exe at [https://qemu.weilnetz.de/w64/](https://qemu.weilnetz.de/w64/)
   - qemu-img.exe convert filename.ova -O vhdx -o subformat=dynamic filename.vhdx
2. Prepare Hyper-V Environment
   - Create Virtual Network
   - Verify Hyper-V is running
3. Create Virtual Machine
   - Set CPU
   - Set Memory
   - Set Network
   - Use existing virtual hard disk set to filename.vhdx
4. Configure the Imported Virtual Machine
   - Tweak configs
5. Verify
