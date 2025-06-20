# netstack windows 11 compute gateway
netstack ops setup for a windows 11 compute gateway configuration

- cat-win11-autounattend [config gen](https://schneegans.de/windows/unattend-generator/)
  - file:///I:/catSurfaceBackup/chris-Downloads/autounattend.xml
- massgravel [github repo](https://github.com/massgravel/Microsoft-Activation-Scripts/blob/master/README.md) via [grc sn-1004 show notes](https://www.grc.com/sn/sn-1004-notes.pdf)
  ```
  irm https://get.activated.win | iex
  ```
- Enable Hyper-V [netstack hyper-v](../hyper-v)
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
  ```
- Enable wsl via [netstack wsl](../wsl)
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All
  ```
- Enable wsl2 via [netstack wsl](../wsl)
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
  ```
- Install Distro (will list)
  ```
  wsl --install
  ```
- Installs [winget pkg](https://winget.run)
  - winget search
  - zerotier [my.zerotier.com](https://my.zerotier.com/login)
    ```
    winget install  -e --id=ZeroTier.ZeroTierOne
    ```
    ```
    zerotier-cli join <network ID>
    ```
  - [Google chrome](https://winget.run/pkg/Google/Chrome) [remotedesktop.google.com](https://remotedesktop.google.com/access)
    ```
    winget install -e --id Google.Chrome
    winget install -e --id Google.ChromeRemoteDesktopHost
    ```
  - [brave](https://winget.run/pkg/Brave/Brave)
    ```
    winget install -e --id Brave.Brave
    ```
  - [vscode](https://winget.run/pkg/Microsoft/VisualStudioCode)
    ```
    winget install -e --id Microsoft.VisualStudioCode
    ```
- tbd

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
