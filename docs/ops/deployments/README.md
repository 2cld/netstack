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

WIP:
1. Look at IPv6 connectivity (goal gitea access)
2. Get direct access to tuners working (goal no plex)
  - Look at NAS (look at direct recording to NAS)
  - mermaid live edit [link](https://mermaid.live/edit#pako:eNqtksFqAjEQhl9lyckFFfS4V3stFPRUt4cxmcRgklkmSa2I796sW7uV4qX0tvPl5x--Zc5CkkLRCG-D8tC1oaqYKNU2JOSAadKTprGSwkRDpWEmHWVV97hES6K-Au2AcTLQh3Gpg6mlni-lU_Nb-fAQzXadiMHg2w3e1ShIsIOI9e21qgLExd20HOuk2a7Idzk9qCvLj8SH2dEyqh-dq9MOecNZHkY2NL44_BjZ0YbF4t2P4N55WM1fxdEV7eh-a0f3r9rR_VU7uqvQCEyOM8PwSNBBl6grBWIqPLIHq8oNnft0K9IePbaiKZ8KNWSXWtGGS4lCTrQ-BSmaxBmngimbvWg0uFim3BVbfLLQL_6mHYRXonFGZcsPex6u9nq8l08kmNl_)
  - see diagram rendered via [github](https://github.com/2cld/netstack/tree/master/docs/ops/deployments)

![](https://mermaid.live/edit#pako:eNqtVMGO2jAQ_RXLJ5BCSpJCIKp6oVJ7aVVpqx526WFwJt4Ix45sB5ZF_HudmAC7AtRDT_G8zJs3fjPJnjKVI81oVcq8gnopCdFK2WEpLWqJdtAiWVYyJQcFkAJGTKgmH7awS3UZww4oBGgcePRKegtfUCQnUToOo08r_eHzpjah1aVch0xVt0v4F4QYz407Li8twpntc1gheSsxPQr8QLtVek2-gsUt7DqMFWHMRB72V3wnKT1ltC01nqVZYfiTaQt79QerNHD8079_UyIHCysweGITIsFEb6K4jxa7FepfumHrwfnYaWxLGY2dYjLuwm-7GvXvc1wLfLEbooSACsirHV7txVlTN26gF720daNNNTg-u2KuanSRcr8EKxh_Yq0ZSUde-ITe5eumcARtLiTqwqB0Hkkek_ndccWnefl7e2J3Htxo-foQ--5_Ouc8ZoTfl-jYgBF3d-PdOgq3E_9vEYxwrh6t_DcLjehGeAZ4Y0ZcQ3XDFQG1VbUrQANaoa6gzN33v2-zl9Q-Y4VLmrljjgU0wi7pUh5cKjRWPewko5nVDQZUq4Y_06wAYVzU1O6W-KWEVviE1iAflap6igtptqcvNItmSTiZRbM4nqTxdBKnAd3RLJmGMwdOo_k8ST8m08khoK8dfxzO0klAMS-d0d_9H6v7cQWU67b_Y08oc9QL1UhLszhNDn8BfEh7zA)

<!-- version 20250219pm
```mermaid
mindmap
  root)internet(
  ::icon(fa fa-cloud)
    rnet)cloudflare(
    ::icon(fa fa-cloud)
    cfng)ng 6.1<br/>Network Gateway<br/>cf.2cld.net(
    ::icon(fa fa-network-wired)
      cfsg[sg 6.2<br/>Storage]
      ::icon(fa fa-database)
        nas1
        nas2
      CyberTruck(CyberTruck<br/>win10 6.30)
      ::icon(fa fa-computer)
      cfcg[cg 6.3<br/>Compute Gateway<br/>HyperV 6.30<br/>plextv ollama zt]
      ::icon(fa fa-gears)
        win11vm(win11vm<br/>6.31)
        ::icon(fa fa-computer)
        pfsense)ng2 9.1<br/>Network Gateway<br/>cf2.2cld.net<br/>pfsense<br/>(
        ::icon(fa fa-network-wired)
            cfPlex
    slng)ng 1.1<br/>sl.2cld.net(
    ::icon(fa fa-cloud)
      slsg[Storage]
      ::icon(fa fa-database)
        nas1
        nas2
      slcg[Compute]
      ::icon(fa fa-gears)
        slwin11
        gus-gram
        ::icon(fa fa-laptop)
```
-->

<!-- version 20250219
```mermaid
mindmap
  root)internet(
  ::icon(fa fa-cloud)
    rnet)cloudflare(
    ::icon(fa fa-cloud)
    cfng)ng 6.1<br/>cf.2cld.net(
    ::icon(fa fa-network-wired)
      cfsg[sg 6.2<br/>Storage]
      ::icon(fa fa-database)
        nas1
        nas2
      cfcg[CyberTruck<br/>HyperV 6.30<br/>cg 6.3<br/>Compute]
      ::icon(fa fa-gears)
        pfsense(pfsense)
        ::icon(fa fa-network-wired)
            cfPlex
        win11vm(win11vm<br/>6.31)
        ::icon(fa fa-computer)
    slng)sl.2cld.net(
    ::icon(fa fa-cloud)
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
-->

<!-- version 20250218
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
-->
