[edit]()

# Docker Hyper-V

- nsUb2404hv NetStack Ubuntu 24.04.3 Hyper-V vm on ? Cyber Truck ?
- Installed via quick start using D:\vmhv\ubuntu-24.04.3-desktop-amd64.iso
- CyberTruck C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\nsUb2404hv_806410E7-BDBF-44D8-88C6-C115BBD90382.avhdx

```powershell
PS C:\WINDOWS\system32> Get-VMIntegrationService nsUB2404hv

VMName     Name                    Enabled PrimaryStatusDescription SecondaryStatusDescription
------     ----                    ------- ------------------------ --------------------------
nsUb2404hv Guest Service Interface False   OK
nsUb2404hv Heartbeat               True    OK
nsUb2404hv Key-Value Pair Exchange True    No Contact
nsUb2404hv Shutdown                True    OK
nsUb2404hv Time Synchronization    True    OK
nsUb2404hv VSS                     True    OK                       The protocol version of the component installed in the virtual machine does not match the version expected by t...

PS C:\WINDOWS\system32> Enable-VMIntegrationService -VMName "nsUb2404hv" -Name "Guest Service Interface"
PS C:\WINDOWS\system32> Get-VMIntegrationService nsUB2404hv

VMName     Name                    Enabled PrimaryStatusDescription SecondaryStatusDescription
------     ----                    ------- ------------------------ --------------------------
nsUb2404hv Guest Service Interface True    No Contact
nsUb2404hv Heartbeat               True    OK
nsUb2404hv Key-Value Pair Exchange True    No Contact
nsUb2404hv Shutdown                True    OK
nsUb2404hv Time Synchronization    True    OK
nsUb2404hv VSS                     True    OK                       The protocol version of the component installed in the virtual machine does not match the version expected by t...


PS C:\WINDOWS\system32>
```

# ssh
- ssh install
```bash
sudo apt update
```
```bash
sudo apt install openssh-server -y
```
- ssh check
```bash
sudo systemctl status ssh
```
- firewall
```bash
sudo ufw allow ssh
sudo ufw enable
sudo ufw status
```

# docker
- tbd
```bash
```
