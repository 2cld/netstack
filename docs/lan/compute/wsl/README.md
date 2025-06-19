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
