[edit](https://github.com/2cld/netstack/edit/master/docs/ops/users/dev-win-wsl.md)

# dev-win-wsl
Developer users using wsl (win subsystem for linux) on windows workstation.

## Install wsl on Windows
- https://learn.microsoft.com/en-us/windows/wsl/install
- Powershell cmd to check wsl version

  ```powershell
  PS C:\WINDOWS\system32> wsl -l -v
    NAME      STATE           VERSION
  * Legacy    Stopped         1
  PS C:\WINDOWS\system32>
  ```
- Powershell cmd to check os version
  ```powershell
  PS C:\WINDOWS\system32> systeminfo | Select-String "OS Name", "OS Version"
  
  OS Name:                   Microsoft Windows 10 Pro
  OS Version:                10.0.19045 N/A Build 19045
  BIOS Version:              American Megatrends Inc. 2.05.0250, 4/10/2015
  
  PS C:\WINDOWS\system32>
  ```
- You must be running Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11
- Powershell cmd to install wsl
  ```powershell
  wsl --install
  ```
- as of 204.11.20 the above installed 22.04
- WHere is the user [article link](https://askubuntu.com/questions/1380253/where-is-wsl-located-on-my-computer)
- In this case
  ```powershell
  PS C:\WINDOWS\system32> Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" -Recurse
  
      Hive: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Lxss
  
  Name                           Property
  ----                           --------
  {12345678-1234-5678-0123-45678 State            : 1
  9abcdef}                       DistributionName : Legacy
                                 Version          : 0
                                 BasePath         : C:\Users\chris\AppData\Local\lxss
                                 DefaultUid       : 1000
                                 Flags            : 7
  {71a28cc4-5d65-4efb-a5a9-0490d State             : 1
  67fe7d3}                       DistributionName  : Ubuntu
                                 Version           : 2
                                 BasePath          : C:\Users\chris\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu_7
                                 9rhkp1fndgsc\LocalState
                                 Flags             : 15
                                 DefaultUid        : 1000
                                 PackageFamilyName : CanonicalGroupLimited.Ubuntu_79rhkp1fndgsc
  
  PS C:\WINDOWS\system32>
  ```
- wsl storage from windows use the \\wsl$\Ubuntu path
  ```powershell
  dir \\wsl$\Ubuntu\home\cat
  ```
  ```powershell
  PS C:\WINDOWS\system32> cat '\\wsl$\Legacy\home\cat\test.txt'
  written by cat ubuntu user
  PS C:\WINDOWS\system32>
  ```
  ```powershell
  PS C:\WINDOWS\system32> cat \\wsl.localhost\Legacy\home\cat\test.txt
  written by cat ubuntu user
  PS C:\WINDOWS\system32>
  ```

- Updated note: Under Windows 11, \\wsl$\<distro_name> still works, but there is also a new \\wsl.localhost\<disro_name> path as well. Both work the same, but wsl.localhost should be a bit more robust in certain situations.
- Powershell cmd to list distributions
  ```powershell
  wsl --list --online
  wsl -l -o
  ```
- Install distro
  ```powershell
  wsl --install -d Ubuntu-22.04
  ```
- set default disto
  ```powsershell
  wsl -s <DistributionName>
  wsl --set-default <DistributionName>
  ```
- run specific distro
  ```powsershell
  wsl -d <DistributionName>
  ```
- steptemplate
  ```powsershell
  dir
  ```

## wsl user check
- Check distribution
  ```powsershell
  cat@catSurface:~$ sudo cat /etc/*-release
  [sudo] password for cat:
  DISTRIB_ID=Ubuntu
  DISTRIB_RELEASE=24.04
  DISTRIB_CODENAME=noble
  DISTRIB_DESCRIPTION="Ubuntu 24.04.1 LTS"
  PRETTY_NAME="Ubuntu 24.04.1 LTS"
  NAME="Ubuntu"
  VERSION_ID="24.04"
  VERSION="24.04.1 LTS (Noble Numbat)"
  VERSION_CODENAME=noble
  ID=ubuntu
  ID_LIKE=debian
  HOME_URL="https://www.ubuntu.com/"
  SUPPORT_URL="https://help.ubuntu.com/"
  BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
  PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
  UBUNTU_CODENAME=noble
  LOGO=ubuntu-logo
  cat@catSurface:~$
  ```
- Path to windows storage
  ```powershell
  cat@catSurface:~$ ls /mnt/c/Users/chris/code
  docker
  cat@catSurface:~$
  ```
