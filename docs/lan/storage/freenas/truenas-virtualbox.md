TrueNAS Scale on virtualBox

- [TrueNAS Scale Download](https://www.truenas.com/_download-truenas-scale/?va-red=NDk1Mjo1MzIy)
- [TrueNAS Scale in VirtualBox](https://i12bretro.github.io/tutorials/0609.html)
- Create a New VM by selecting Machine > New
```
Name: TrueNAS SCALE
Machine Folder: C:\VMs
Type: Linux
Version: Debian (64-bit)
Memory Size: 8192 MB
Hard disk: Create a virtual hard disk now
```
- Video Memory: 128 MB
- Network: Bridged - (Physical one)
- System: Enable EFI (and let TrueNAS be EFI also)
- [VirtualBox HardDrive passthrough](https://i12bretro.github.io/tutorials/0365.html)

```ps
PS C:\Windows\system32> Get-PhysicalDisk

Number FriendlyName         SerialNumber    MediaType CanPool OperationalStatus HealthStatus Usage            Size
------ ------------         ------------    --------- ------- ----------------- ------------ -----            ----
8      WDC  WDBNCE0010PNC   2017A5808811    SSD       False   OK                Healthy      Auto-Select 931.51 GB
3      ATA ST6000VN0033-2EE ZADB5XSN        HDD       False   OK                Healthy      Auto-Select   5.46 TB
11     WDC WD40EZRZ-00GXCB0 WD-WCC7K7ZHJNLJ HDD       False   OK                Healthy      Auto-Select   3.64 TB
4      ATA ST6000DX000-1H21 Z4D07ESL        HDD       False   OK                Healthy      Auto-Select   5.46 TB
1      ATA ST6000VN0033-2EE ZADB4512        HDD       False   OK                Healthy      Auto-Select   5.46 TB
7      ATA ST6000DX000-1H21 Z4D0830X        HDD       False   OK                Healthy      Auto-Select   5.46 TB
9      ST4000DM005-2DP166   ZGY0H29Y        HDD       False   OK                Healthy      Auto-Select   3.64 TB
10     ST4000DM005-2DP166   ZGY0H6BY        HDD       False   OK                Healthy      Auto-Select   3.64 TB
5      ATA ST6000DX000-1H21 Z4D0BSBQ        HDD       False   OK                Healthy      Auto-Select   5.46 TB
6      ATA ST6000DX000-1H21 Z4D0825P        HDD       False   OK                Healthy      Auto-Select   5.46 TB
2      ATA ST6000VN0033-2EE ZADB4Z76        HDD       False   OK                Healthy      Auto-Select   5.46 TB
0      ATA ST6000VN0033-2EE ZADB5FVJ        HDD       False   OK                Healthy      Auto-Select   5.46 TB
```

```ps
cd "$ENV:ProgramFiles\Oracle\VirtualBox"
# create a vmdk disk pointing to the target physical disk
.\VBoxManage.exe internalcommands createrawvmdk -filename "D:\VMs\SSD.vmdk" -rawdisk \\.\PhysicalDrive2
```

Removed all drive but primary and test zfs 4

```ps
PS C:\Windows\system32> Get-PhysicalDisk

Number FriendlyName         SerialNumber    MediaType CanPool OperationalStatus HealthStatus Usage            Size
------ ------------         ------------    --------- ------- ----------------- ------------ -----            ----
0      WDC  WDBNCE0010PNC   2017A5808811    SSD       False   OK                Healthy      Auto-Select 931.51 GB
4      ST4000DM005-2DP166   ZDH1XZRW        HDD       False   OK                Healthy      Auto-Select   3.64 TB
3      WDC WD40EZRZ-00GXCB0 WD-WCC7K7ZHJNLJ HDD       False   OK                Healthy      Auto-Select   3.64 TB
1      ST4000DM005-2DP166   ZGY0H29Y        HDD       False   OK                Healthy      Auto-Select   3.64 TB
2      ST4000DM005-2DP166   ZGY0H6BY        HDD       False   OK                Healthy      Auto-Select   3.64 TB
```

```ps
.\VBoxManage.exe internalcommands createrawvmdk -filename "C:\Users\ghadmin\VirtualBox VMs\catNAS\catboxD1-ZGY0H29Y.vmdk" -rawdisk \\.\PhysicalDrive1
```

```ps
.\VBoxManage.exe internalcommands createrawvmdk -filename "C:\Users\ghadmin\VirtualBox VMs\catNAS\catboxD2-ZGY0H6BY.vmdk" -rawdisk \\.\PhysicalDrive2
```

```ps
.\VBoxManage.exe internalcommands createrawvmdk -filename "C:\Users\ghadmin\VirtualBox VMs\catNAS\catboxD3-WD-WCC7K7ZHJNLJ.vmdk" -rawdisk \\.\PhysicalDrive3
```

```ps
.\VBoxManage.exe internalcommands createrawvmdk -filename "C:\Users\ghadmin\VirtualBox VMs\catNAS\catboxD4-ZDH1XZRW.vmdk" -rawdisk \\.\PhysicalDrive4
```

---
---
---
---
# Running a TrueNAS SCALE VM in VirtualBox

1.  <a id="li_114874_0"></a>Download TrueNAS SCALE <a id="li_114874_0"></a>[Download](https://www.truenas.com/download-tn-scale/)
2.  <a id="li_215779_1"></a>Launch Virtualbox
3.  <a id="li_942501_2"></a>Create a New VM by selecting Machine > New<a id="li_942501_2"></a>
    
    Name: TrueNAS SCALE  
    Machine Folder: C:\\VMs  
    Type: Linux  
    Version: Debian (64-bit)  
    Memory Size: 8192 MB  
    Hard disk: Create a virtual hard disk now
    
4.  <a id="li_33950_3"></a>Click Create
5.  <a id="li_666012_4"></a>On the Create Virtual Hard Disk dialog<a id="li_666012_4"></a>
    
    Name the virtual disk image TrueNAS SCALE.vdi  
    File size: 16 GB  
    Hard disk file type: VDI  
    Storage on physical hard disk: Dynamically Allocated
    
6.  <a id="li_443260_5"></a>Click Create
7.  <a id="li_852094_6"></a>Select the VM and Click Settings
8.  <a id="li_341911_7"></a>Selec System
9.  <a id="li_74082_8"></a>Slide the Processor(s) to 2
10. <a id="li_714558_9"></a>Select Display
11. <a id="li_679651_10"></a>Slide the Video Memory to 128 MB
12. <a id="li_707929_11"></a>Select Storage
13. <a id="li_190787_12"></a>Click on the CD-ROM drive
14. <a id="li_502659_13"></a>Select the disc dropdown to the right > Choose a virtual optical disc file...
15. <a id="li_884991_14"></a>Browse to and select the downloaded TrueNAS SCALE .iso file
16. <a id="li_968437_15"></a>Select Network
17. <a id="li_22646_16"></a>Set the attached to dropdown to Bridged Adapter
18. <a id="li_190689_17"></a>Click OK
19. <a id="li_387682_18"></a>Make sure the TrueNAS SCALE VM is selected and click Start > Normal
20. <a id="li_866406_19"></a>At the menu, press Enter to start the TrueNAS SCALE Installation
21. <a id="li_50389_20"></a>Select Install/Upgrade > OK
22. <a id="li_956435_21"></a>Press the space bar to select the VBOX HARDDISK > Press Enter
23. <a id="li_840350_22"></a>Select Yes to continue the installation > Press Enter
24. <a id="li_302154_23"></a>Enter a root password twice > Press Enter
25. <a id="li_141918_24"></a>After the installation completes select Devices > Optical Drives > Remove disk from virtual drive
26. <a id="li_814071_25"></a>Click Force Unmount
27. <a id="li_134441_26"></a>Press Enter to reboot the VM
28. <a id="li_333272_27"></a>Once TrueNAS SCALE has finished booting, note the URL on the screen
29. <a id="li_409144_28"></a>Open a web browser and navigate to the TrueNAS SCALE URL
30. <a id="li_537256_29"></a>Log into the Web UI with username root and the password set during the installation
31. <a id="li_385819_30"></a>Welcome to TrueNAS SCALE

<img width="44" height="50" src=":/64a52672767f4db1b2542560e6e5de55"/>](https://discord.com/invite/EzenvmSHW8)<img width="50" height="50" src=":/a192de9cf2bc4b47955969b4bd43c5ab"/>](https://i12bretro.github.io/tutorials)<img width="50" height="50" src=":/a14b7726b36d41a49cb6599bbe4671f6"/>](https://reddit.com/r/i12bretro)<img width="50" height="50" src=":/8bb0f74e68f9493db6910d6db02f6fe2"/>](https://twitter.com/i12bretro)<img width="50" height="50" src=":/a256df6400aa4ff5a2ce585987593562"/>](https://i12bretro.wordpress.com)<img width="66" height="50" src=":/b6d7e34b1cce44cfb3a77fc0bd954d52"/>](https://youtube.com/c/i12bretro)<img width="50" height="50" src=":/849d3485bf5b4d428b93bdeb3098903c"/>](https://i12bretro.wordpress.com/tools/)<img width="50" height="50" src=":/34e6729228da471291f6b319496ee00c"/>](https://i12bretro.wordpress.com/author/i12bretro/feed/)

