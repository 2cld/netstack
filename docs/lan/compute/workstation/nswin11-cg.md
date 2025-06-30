[edit](https://github.com/2cld/netstack/edit/master/docs/lan/compute/workstation/nswin11-cg.md)
# netstack windows 11 compute gateway
netstack ops setup for a windows 11 compute gateway configuration
- deployment [slwin11ops-notes](https://sl.2cld.net/ops/install/slwin11ops-notes.html)

## Install OS
- cat-win11-autounattend [config gen](https://schneegans.de/windows/unattend-generator/)
  - file:///I:/catSurfaceBackup/chris-Downloads/autounattend.xml
- massgravel [github repo](https://github.com/massgravel/Microsoft-Activation-Scripts/blob/master/README.md) via [grc sn-1004 show notes](https://www.grc.com/sn/sn-1004-notes.pdf)
  ```
  irm https://get.activated.win | iex
  ```
## Install Virtual
- Enable Hyper-V [netstack hyper-v](../hyper-v)
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
  ```
- Enable wsl 2 via [netstack wsl](../wsl)
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All
  ```
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
  ```
  ```
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  ```
- check version should be 2
  ```
  wsl --version
  ```
## Install Network
- Zerotier [my.zerotier.com](https://my.zerotier.com/login)
  - winget install  -e --id=ZeroTier.ZeroTierOne
  - zerotier-cli join <network ID>
- Proton [account.proton.me](https://account.proton.me/login)
  - winget install  -e --id=Proton.ProtonVPN
  - proton user login
- Cloudflare [one.dash.cloudflare.com](https://dash.cloudflare.com/login)
  - winget install  -e --id=Cloudflare.cloudflared

## Install Browsers
- [Google chrome](https://winget.run/pkg/Google/Chrome) [remotedesktop.google.com](https://remotedesktop.google.com/access)
- winget install -e --id=Google.Chrome
- winget install -e --id=Google.ChromeRemoteDesktopHost
- [brave](https://winget.run/pkg/Brave/Brave)
- winget install -e --id=Brave.Brave

## Install media Services
- winget install -e --id=Plex.Plex
- winget install -e --id=Plex.PlexMediaServer 
  - Get-NetFirewallRule -DisplayName "Plex Media Server (Remote Access)"
  - New-NetFirewallRule -DisplayName "Plex Media Server (Remote Access)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 32400 -Program "C:\Program Files\Plex\Plex Media Server\Plex Media Server.exe" -Profile Any
- winget install -e --id=Silicondust.HDHomeRun
- winget install -e --id=OBSProject.OBSStudio
- winget install -e --id=VideoLAN.VLC
- winget install -e --id=BlueStack.BlueStacks
- winget install -e --id=ch.LosslessCut
- I just extracted zip to F:\slMedia\LosslessCut-win-x64
- winget install -e --id=GuinpinSoft.MakeMKV
- Notes:
  - Plex.Plex is plex app
  - Plex.PlexMediaServer is Server
  - Silicondust.HDHomeRun is for HDTuner
  - OBSProject.OBSStudio is for screencast recording
  - VideoLAN.VLC is for network streamming viewing
  - BlueStack.BlueStacks is android emulator to run phone apps to manage streams
  - ch.LosslessCut is a quick way to cut video
  - GuinpinSoft.MakeMKV is for DVD ripping
- tbd

## Install Development
- winget install -e --id Microsoft.VisualStudioCode
- winget install -e --id GitHub.GitHubDesktop

## wsl
- sudo apt-get install cockpit -y
- sudo systemctl enable --now cockpit.socket
- sudo apt-get install podman cockpit-podman -y
- sudo systemctl enable --now podman
- [wsl docker](./../wsl/wsl-docker-install)
- /home/ghadmin/docker/docker-compose


## backup

- [search reference](https://www.google.com/search?q=run+windows+backup+from+command+line&rlz=1C1GCEA_enUS1065US1065&oq=running+windows+backup+fro&gs_lcrp=EgZjaHJvbWUqCAgBEAAYFhgeMgYIABBFGDkyCAgBEAAYFhgeMggIAhAAGBYYHjIICAMQABgWGB4yCAgEEAAYFhgeMggIBRAAGBYYHjIICAYQABgWGB4yDQgHEAAYhgMYgAQYigUyDQgIEAAYhgMYgAQYigUyBwgJEAAY7wXSAQg4ODcxajBqN6gCALACAA&sourceid=chrome&ie=UTF-8_)
- https://www.youtube.com/watch?v=hBaLTcNHSL4&t=56

### Resources
- https://www.microsoft.com/en-us/software-download/windows11
- autounattend.xml config https://schneegans.de/windows/unattend-generator/
  - https://www.youtube.com/watch?v=h9SpKVEc_Yo
  - TC 3:05 start autounattend.xml config https://youtu.be/h9SpKVEc_Yo?t=185
- Steve Gibson ms activation hack
  - https://www.grc.com/sn/sn-1004-notes.pdf
  - https://github.com/massgravel/Microsoft-Activation-Scripts/blob/master/README.md
- Other helpful if not doing autoattend
  - Bipass-NRO https://www.youtube.com/watch?v=8ePBHDDr6UI
  - Clean windows 11 Install (not used) https://www.youtube.com/watch?v=x1yYkBJ6qfo

### Sort this
Install wsl debian docker
https://docs.docker.com/desktop/features/wsl/ 
https://docs.docker.com/desktop/setup/install/windows-install/

https://netstack.org/docs/ops/users/dev-win-wsl
https://ai.2cld.net/docs/open-webui-install
https://gist.github.com/Athou/022c67de48f1cf6584ce6c194af71a09

https://github.com/2cld/netstack/tree/master/docs/lan/compute/wsl

Install Google (ghadmin)

Install VSCode

surface 4 laptop recovery
https://answers.microsoft.com/en-us/surface/forum/all/surface-laptop-4-hardware-not-working-on-usb-boot/e9f43c89-051b-44e3-af0b-df4a50279e93

https://support.microsoft.com/en-us/surface/creating-and-using-a-usb-recovery-drive-for-surface-677852e2-ed34-45cb-40ef-398fc7d62c07
