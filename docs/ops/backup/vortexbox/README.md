
- [vortexbox download for ovf template](https://wiki.vortexbox.org/available_images#vortexbox_23_ovf_templates)

OVA for Hyper-V

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
