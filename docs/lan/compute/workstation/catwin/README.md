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

## Reference
- [yt Windows in Docker Container](https://www.youtube.com/watch?v=xhGYobuG508)
- [Windows autounattend.xml file generation](https://schneegans.de/windows/unattend-generator/)
- [yt Transfer Quickbooks to new computer](https://youtu.be/H6emUQXJkwE)
- [yt Jim's Garage Windows in Docker](https://youtu.be/jOzk8QyAXwc?t=580)
- [gai Quickbooks 2024 backup and restore](https://www.google.com/search?q=quickbooks+2024+backup+and+restore+to+new+computer&rlz=1C1CHFX_enUS1166US1166&oq=quickbooks+2024+backup+and+resotre+to+&gs_lcrp=EgZjaHJvbWUqCQgBECEYChigATIGCAAQRRg5MgkIARAhGAoYoAEyCQgCECEYChigATIJCAMQIRgKGKABMgkIBBAhGAoYqwIyCQgFECEYChirAjIJCAYQIRgKGKsCMgcIBxAhGI8CMgcICBAhGI8CMgcICRAhGI8C0gEJMTU0MzFqMGo3qAIAsAIA&sourceid=chrome&ie=UTF-8)
- [gai enable nested vert](https://www.google.com/search?q=I%27m+a+windows+admin+working+with+hyper-v+and+docker.++How+do+I+enable+nested+virtualization+on+an+Ubuntu+VM+running+on+Hyper-V+so+I+can+use+docker+kvm+on+the+Ubuntu+VM%3F&rlz=1C1CHFX_enUS1166US1166&sourceid=chrome&ie=UTF-8&udm=50&aep=48&cud=0&qsubts=1763831524660&mstk=AUtExfCYOD6Qr02C4L5sAnvNj8fwR8BIM7MGCE3GsA_z0J8E9ohI9Qo22ynFBt1dbcFjcJgdLbG9V4nUv53YTYvD1LtYoxh_a61r4DTxbYvdt6nOQVn7YMb_ZghXwgJzr4zigBHzY7jwq_diZuhcr6mNXFOlW8xF8lIncptDU3hWgX-xA19RItPiDEdGQyqAUZHV8ATTJpiJqAHYpftBVGwcbAqAgaR7BNgOknCEhawjTvoK_E1BzM1mFi6LB6eyDNAXf_miRqb8J_LrJ8CpfHZMc7tGkhGLKcYckSqkmvK8ObcYjW3P3_PiKe68rGcOld6dXrS3UvirIqQr7CmYvWetMU8S7H9cP5oohnU6pZd0qOV0HfinrFucgMubjnJZjuF4gNi3D_IAXYIaoLxWls8WSG5sQWGaQBECow&csuir=1&mtid=N-8haYPiDpisw8cPhrnm2AU)
- 
