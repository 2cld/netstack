# catwin
catwin is a docker windows 11 node on nsdockerhv vm on hyper-v cybertruck

- GUI nsadmin zt [http://10.147.17.176:8007/](http://10.147.17.176:8007/)
- based on [netstack docker-portal-windows](https://netstack.org/docs/lan/compute/docker/docker-portal-windows.md) [github](https://github.com/2cld/netstack/blob/master/docs/lan/compute/docker/docker-portal-windows.md)

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

## Install Development
- winget install -e --id Microsoft.VisualStudioCode
- winget install -e --id GitHub.GitHubDesktop
