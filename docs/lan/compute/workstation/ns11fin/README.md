# ns11fin workstation

- cyber-truck hyper-v cat9fin vm
- unattend.iso in ct/ghadmin/downloads will arch gitea.cat9.me
  - create [unattend.iso or .xml](https://schneegans.de/windows/unattend-generator/) tutorial by [yt](https://www.youtube.com/watch?v=h9SpKVEc_Yo&t=185s)
- nsadmin, cat, treesaes, hwpc
- control panel, documents and downloads
- should be bare min with only:
  - Remote Desktop App
  - OpenSSH client
  - windows terminal
  - powershell 2.0
  - snipping tool
  - calculator

## Install Network
- Zerotier [my.zerotier.com](https://my.zerotier.com/login)
  - winget install  -e --id=ZeroTier.ZeroTierOne
  - zerotier-cli join <network ID>

## Install Browsers / Remote
- [Google chrome](https://winget.run/pkg/Google/Chrome) [remotedesktop.google.com](https://remotedesktop.google.com/access)
- winget install -e --id=Google.Chrome
- winget install -e --id=Google.ChromeRemoteDesktopHost
- [brave](https://winget.run/pkg/Brave/Brave)
- winget install -e --id=Brave.Brave
- winget install -e --id RustDesk.RustDesk
- winget install -e --id ZeroTier.ZeroTierOne

## Install Tools
- winget install --id Git.Git -e --source winget
- winget install Amazon.Kiro
- winget install Amazon.Kiro.CLI
- winget install Microsoft.VisualStudioCode
- winget install Python.Python.3

## Install Intuit
- [https://downloads.quickbooks.com/app/qbdt/products](https://downloads.quickbooks.com/app/qbdt/products)
- [https://turbotax.intuit.com/personal-taxes/cd-download/install-turbotax/](https://turbotax.intuit.com/personal-taxes/cd-download/install-turbotax/)

## Backup and Restore
- hwpc
- cat9 / cat services
- FHKlopFarms
- TreesAES
- THTwig / BHay
- FletcherMC / BFletch
