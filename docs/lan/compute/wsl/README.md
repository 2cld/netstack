# wsl windows subsytem for linux

- Enable
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux


- Enable wsl
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All
  ```
- Enable wsl2
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
  ```
- Verify install
  ```
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  ```
- check version should be 2
  ```
  wsl --version
  ```
- switche to 2 if no
  ```
  wsl --install
  wsl --set-default-version 2
  ```
- Install Distro (will list) or [download a distribution](https://learn.microsoft.com/en-us/windows/wsl/install-manual#downloading-distributions)
  ```
  wsl --install
  ```
- Place the distribution other than C: [Reference](https://medium.com/@sharansh.sinha/wsl-2-installation-on-different-drive-3d9f0cc88850) 
- Changing the extension from .AppxBundle or .Appx to .zip and extract it.
- copy the extracted folder to your any drive where you like to have WSL Linux and run .exe

- put crap in gui
```
Open terminal and go to settings
Step 1: add a new profile > new empty profile
Step 2: change name as you want
Step 3: change the command line to C:\WINDOWS\system32\wsl.exe -d Ubuntu
Step 4: Change starting directory to ~
Step 5: Change Icon if you want to, you can find icons folder (.\Assets) in your distro folder.
Step 6: Save the changes and that's all.
After installation, there will be an ext4.vhdx file which is the main virtual disk.
If you ever wish to reset Linux simply run

wsl --list --verbose #to check all the installed distro
wsl --unregister Ubuntu #to remove the distro

The ext4.vhdx file will be deleted, and you can again run Ubuntu.exe setup file to start over.
```

- ext4.vhdx filenames by referencing the registry, ex: powershell:
```powershell
(Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object {Get-ItemProperty $_.PSPath}) | select DistributionName,BasePath,VhdFileName
```

---
## wsl portproxy
wsl portproxy from windows os
- show portproxy on winos
  ```powershell
  netsh interface portproxy show all
  ```
- find the_wsl_ip (usually eth0) on wsl
  ```bash
  ip a
  ```
- add port to unix firewall ufw on wsl
  ```bash
  sudo ufw allow 8000
  ```
- add port to windows firewall in powershell on winos
  ```powershell
  New-NetFirewallRule -DisplayName "Allow Inbound Port 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
  ```
- forward port to wsl in powershell on winos.
  ```powershell
  netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=<the_wsl_ip> 
  ```
- show portproxy on winos
  ```powershell
  netsh interface portproxy show all
  ```
  
---
---
## Backup / Move

To move a WSL (Windows Subsystem for Linux) distribution to a new computer, you can export it as a .tar file and then import it on the new machine. This process involves using the wsl --export command to create the backup, transferring the file, and then using wsl --import to restore it. 

### Steps to Backup and Move WSL:
1. Backup on the old machine:
  - Open PowerShell or Command Prompt as an administrator.
  - Stop the WSL instance: If the distribution is running, stop it using
  ```
  wsl --shutdown or wsl --terminate <DistributionName>
  ```
  - Export the distribution command to create a .tar backup. Replace <DistributionName> with the name of your WSL distribution (e.g., "Ubuntu-20.04") and <FileName> with the desired path and filename for the backup (e.g., "C:\backups\ubuntu_backup.tar").
  ```
  wsl --export <DistributionName> <FileName>
  ```
2. Transfer the generated .tar file to the new computer using your preferred method (e.g., USB drive, network share). 
3. Import on the new machine:
  - Open PowerShell or Command Prompt as an administrator on the new computer. 
  - Unregister any existing distribution with the same name: if needed:
  ```
  wsl --unregister <DistributionName>
  ```
  - Import the distribution: Use the import command. Replace <NewDistributionName> with a new name for the distribution, <InstallLocation> with the desired directory for the installation (e.g., "D:\WSL\Ubuntu"), and <BackupFilePath> with the path to the .tar file. 
  ```
  wsl --import <NewDistributionName> <InstallLocation> <BackupFilePath>
  ```
4. Set the default user: If needed, configure the default user for the imported distribution using ubuntu.exe config --default-user <your-wsl-username>. 
5. Launch the distribution: Run to start the imported distribution.
  ```
  wsl --distribution <NewDistributionName>
  ```
 
#### Important Notes:
- WSL Version:
These instructions generally apply to WSL2. If you have a WSL1 distribution, you'll need to back up the %localappdata%\\lxss directory instead of using wsl --export, says Ask Ubuntu. 

- File System:
WSL uses a virtual hard disk (VHD) file for its file system. For WSL2, you can also use the --vhd flag with wsl --import to import the VHD directly, which can be faster. 

- Permissions:
When restoring a WSL1 backup, you might need to manually reset file permissions. 

- Disk Space:
The .tar backup file can be quite large, so ensure you have enough disk space on both the source and destination machines. 

- New Name:
When importing, it's recommended to use a new name for the distribution to avoid potential conflicts, according to a Reddit user. 
