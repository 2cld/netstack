# netstack windows 11 compute gateway
netstack ops setup for a windows 11 compute gateway configuration

- cat-win11-autounattend [config gen](https://schneegans.de/windows/unattend-generator/)
  - file:///I:/catSurfaceBackup/chris-Downloads/autounattend.xml
- massgravel [github repo](https://github.com/massgravel/Microsoft-Activation-Scripts/blob/master/README.md)
  ```
  irm https://get.activated.win | iex
  ```
- Enable wsl
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All
  ```
- Enable wsl2
  ```
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
  ```
- Install Distro (will list)
  ```
  wsl --install
  ```
- Installs [winget pkg](https://winget.run)
- winget search "Google Chrome"
  - [winget chrome](https://winget.run/pkg/Google/Chrome)
    ```
    winget install -e --id Google.Chrome
    ```
  - [winget brave](https://winget.run/pkg/Brave/Brave)
    ```
    winget install -e --id Brave.Brave
    ```
  - [winget docker desktop](https://winget.run/pkg/Docker/DockerDesktop)
    ```
    winget install -e --id Docker.DockerDesktop
    ```
    - put on drive other than c
  - [winget vscode](https://winget.run/pkg/Microsoft/VisualStudioCode)
    ```
    winget install -e --id Microsoft.VisualStudioCode
    ```
- tbd

## backup
https://www.google.com/search?q=run+windows+backup+from+command+line&rlz=1C1GCEA_enUS1065US1065&oq=running+windows+backup+fro&gs_lcrp=EgZjaHJvbWUqCAgBEAAYFhgeMgYIABBFGDkyCAgBEAAYFhgeMggIAhAAGBYYHjIICAMQABgWGB4yCAgEEAAYFhgeMggIBRAAGBYYHjIICAYQABgWGB4yDQgHEAAYhgMYgAQYigUyDQgIEAAYhgMYgAQYigUyBwgJEAAY7wXSAQg4ODcxajBqN6gCALACAA&sourceid=chrome&ie=UTF-8

https://www.youtube.com/watch?v=hBaLTcNHSL4&t=56

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

Install Google (ghadmin)

Install VSCode
