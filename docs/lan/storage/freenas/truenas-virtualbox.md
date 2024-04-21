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
