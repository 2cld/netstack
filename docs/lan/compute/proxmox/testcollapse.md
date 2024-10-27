
<details>
  <summary>301 win11cfPlex.cf2.2cld.net - ssd passthrough of old cfPlex</summary>

  ## win11cfPlex.cf2.2cld.net
  uses old cfPlex with ssd drive pass-through [youtube](https://www.youtube.com/watch?v=eFDcCxRS5Xk)
  Tutorial on how to virtualise an old existing Windows install you might want to recover data from.
  VirtIO Drivers: [https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers)
  
  - CMD to mount SATA drives to VM (-sata can be interchanged with -scsi):
    ````bash
    qm set "VM ID" -sata1 /dev/disk/by-id/ata-"MODEL"_"SN"
    ````
  - CMD I used to connect the cfPlex SSD to 301
    ````bash
    qm set 301 -sata1 /dev/disk/by-id/ata-WDC_WDBNCE0010PNC_2017A5808811
    ````
  - Run the virtio-win-gt-x64 installer for 64-bit or -x86 for 32-bit. 

</details>
