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
  - mermaid trink add live edit [link](https://mermaid.live/edit#pako:eNqtVMGO2yAU_BXEKZES1xDHjq2ql1RqL60qbdVDNz0QjFkrGCzAyWaj_fdiSOLsKtnuoSfDMG_meXjiAKkqGSxgU8uyIe1KAqCVsuNaWqYls6MeKYqaKjmqCKjIlArVleMedlTHGHugEkSzUUCv0Hv4okRygLI4Qh_X-sOnbWsiq2u5iahqbkuEAwBMqMW-lteWkaE6cGgleW-RHg2-M7tTegO-EMt2ZO8xWkWYijI6_eIrSxlKprtas8GaVobfm144uN9ZpQlnf07nLyRKYsmaGHauBkASg17s8Gm33K-Z_qk7uhkNS--xqyWKneMsDlsjwJN1nfwQ7NEjX_ct078GRusO7BYoIUhDHHd8tTsXVtu5K77orndC22Z0_Hoxp4ouKP-SoFW3xjhOnMqw7FtL3i1CK8rvaZ_xzHewDITT5V3PmjOizYVFWxkmXfSSY5C_OQX4PAYhvFDo16MbLV-bDSPCyKGjmRFvjteriRZurP7fLBnhEjzG9r64jPB3PgC8M1OuSXMjAUFaq9oxnMCG6YbUpXtADj13Be0Da9gKFm5Zsop0wq7gSj47KumsuttLCgurOzaBWnX8ARYVEcbtutb9I_tck972jLZE_laqOZWwsnYpfQsvln-4JpDr3v4oyWTJ9FJ10sICZdgLwOIAH2GBMxwlCCV5lqfzPF3M5hO4h0UaJXmKFhglaJHEeJE-T-CTt4yjPEkWcTLL0DzFWZLh579rC5Kp)
  - see diagram rendered via [github](https://github.com/2cld/netstack/tree/master/docs/ops/deployments)

[![](https://mermaid.ink/img/pako:eNqtVMGO2yAU_BXEKZES1xDHjq2ql1RqL60qbdVDNz0QjFkrGCzAyWaj_fdiSOLsKtnuoSfDMG_meXjiAKkqGSxgU8uyIe1KAqCVsuNaWqYls6MeKYqaKjmqCKjIlArVleMedlTHGHugEkSzUUCv0Hv4okRygLI4Qh_X-sOnbWsiq2u5iahqbkuEAwBMqMW-lteWkaE6cGgleW-RHg2-M7tTegO-EMt2ZO8xWkWYijI6_eIrSxlKprtas8GaVobfm144uN9ZpQlnf07nLyRKYsmaGHauBkASg17s8Gm33K-Z_qk7uhkNS--xqyWKneMsDlsjwJN1nfwQ7NEjX_ct078GRusO7BYoIUhDHHd8tTsXVtu5K77orndC22Z0_Hoxp4ouKP-SoFW3xjhOnMqw7FtL3i1CK8rvaZ_xzHewDITT5V3PmjOizYVFWxkmXfSSY5C_OQX4PAYhvFDo16MbLV-bDSPCyKGjmRFvjteriRZurP7fLBnhEjzG9r64jPB3PgC8M1OuSXMjAUFaq9oxnMCG6YbUpXtADj13Be0Da9gKFm5Zsop0wq7gSj47KumsuttLCgurOzaBWnX8ARYVEcbtutb9I_tck972jLZE_laqOZWwsnYpfQsvln-4JpDr3v4oyWTJ9FJ10sICZdgLwOIAH2GBMxwlCCV5lqfzPF3M5hO4h0UaJXmKFhglaJHEeJE-T-CTt4yjPEkWcTLL0DzFWZLh579rC5Kp?type=png)](https://mermaid.live/edit#pako:eNqtVMGO2yAU_BXEKZES1xDHjq2ql1RqL60qbdVDNz0QjFkrGCzAyWaj_fdiSOLsKtnuoSfDMG_meXjiAKkqGSxgU8uyIe1KAqCVsuNaWqYls6MeKYqaKjmqCKjIlArVleMedlTHGHugEkSzUUCv0Hv4okRygLI4Qh_X-sOnbWsiq2u5iahqbkuEAwBMqMW-lteWkaE6cGgleW-RHg2-M7tTegO-EMt2ZO8xWkWYijI6_eIrSxlKprtas8GaVobfm144uN9ZpQlnf07nLyRKYsmaGHauBkASg17s8Gm33K-Z_qk7uhkNS--xqyWKneMsDlsjwJN1nfwQ7NEjX_ct078GRusO7BYoIUhDHHd8tTsXVtu5K77orndC22Z0_Hoxp4ouKP-SoFW3xjhOnMqw7FtL3i1CK8rvaZ_xzHewDITT5V3PmjOizYVFWxkmXfSSY5C_OQX4PAYhvFDo16MbLV-bDSPCyKGjmRFvjteriRZurP7fLBnhEjzG9r64jPB3PgC8M1OuSXMjAUFaq9oxnMCG6YbUpXtADj13Be0Da9gKFm5Zsop0wq7gSj47KumsuttLCgurOzaBWnX8ARYVEcbtutb9I_tck972jLZE_laqOZWwsnYpfQsvln-4JpDr3v4oyWTJ9FJ10sICZdgLwOIAH2GBMxwlCCV5lqfzPF3M5hO4h0UaJXmKFhglaJHEeJE-T-CTt4yjPEkWcTLL0DzFWZLh579rC5Kp)

<!-- version 20250411pm update
```mermaid
mindmap
  root)internet(
  ::icon(fa fa-cloud)
    rnet)cloudflare(
    ::icon(fa fa-cloud)    
    rnet)ng 170.1<br/>vps.trink.com(
    ::icon(fa fa-cloud)
      sg 170.2<br/>gitea.trink.com
    cfng)ng 6.1<br/>Network Gateway<br/>cf.2cld.net(
    ::icon(fa fa-network-wired)
      cfsg[sg 6.2<br/>Storage]
      ::icon(fa fa-database)
        nas1
        nas2
      CyberTruck(CyberTruck<br/>win10 6.30<br/>wsl zt cfPlex<br/>HyperV 6.30<br/>plextv ollama zt)
      ::icon(fa fa-computer)
        win11vm(win11vm<br/>6.31)
        ::icon(fa fa-computer)
        cfub2204vm(cfub2204vm 6.34)
        ::icon(fa fa-computer)
      cfcg[cg 6.3<br/>Compute Gateway]
      ::icon(fa fa-gears)
        pfsense)ng2 9.1<br/>Network Gateway<br/>cf2.2cld.net<br/>pfsense<br/>(
        ::icon(fa fa-network-wired)
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
<!-- version 20250411am add vps.trink.com
```mermaid
mindmap
  root)internet(
  ::icon(fa fa-cloud)
    rnet)cloudflare(
    ::icon(fa fa-cloud)    
    rnet)ng 170.1<br/>vps.trink.com(
    ::icon(fa fa-cloud)
      sg 170.2<br/>gitea.trink.com
    cfng)ng 6.1<br/>Network Gateway<br/>cf.2cld.net(
    ::icon(fa fa-network-wired)
      cfsg[sg 6.2<br/>Storage]
      ::icon(fa fa-database)
        nas1
        nas2
      CyberTruck(CyberTruck<br/>win10 6.30<br/>HyperV 6.30<br/>plextv ollama zt)
      ::icon(fa fa-computer)
        win11vm(win11vm<br/>6.31)
        ::icon(fa fa-computer)
      cfcg[cg 6.3<br/>Compute Gateway]
      ::icon(fa fa-gears)
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
