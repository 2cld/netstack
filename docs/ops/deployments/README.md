[edit](https://github.com/2cld/netstack/edit/master/docs/ops/deployments/README.md)

- [gh.2cld.lan](https://gh.2cld.net/)
  - [docs](https://gh.2cld.net/docs/)
- [cf.2cld.net](https://cf.2cld.net/)
  - [docs](https://cf.2cld.net/docs)
  - [cf.2cld.lan](https://cf.2cld.net/)
- [sl.2cld.lan](https://sl.2cld.net/)
  - [docs](https://sl.2cld.net/docs/)
- [tv.2cld.lan](https://tv.2cld.net/)
  - [docs](https://tv.2cld.net/docs/)

```mermaid
mindmap
  root)internet(
  ::icon(fa fa-cloud)
    rnet)cloudflare(
    ::icon(fa fa-cloud)
    cfng)cf.2cld.net(
      cfsg[Storage]
      ::icon(fa fa-database)
        nas1
        nas2
      cfcg[Compute]
      ::icon(fa fa-network-wired)
        CyberTruck
            cfPlex
        win11vm
        ::icon(fa fa-computer)
    slng)sl.2cld.net(
      slsg[Storage]
      ::icon(fa fa-database)
        nas1
        nas2
      slcg[Compute]
      ::icon(fa fa-network-wired)
        slwin11
        gus-gram
        ::icon(fa fa-laptop)
```
