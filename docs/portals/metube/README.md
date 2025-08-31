# metube

- [https://metube.klopfenstein.org/](https://metube.klopfenstein.org/) on [https://sg.klopfenstein.org/](https://sg.klopfenstein.org/)
- hardware [ns synology ds411](https://netstack.org/docs/lan/storage/synology/)
- docker cf-metube1 [https://hub.docker.com/r/alexta69/metube](https://hub.docker.com/r/alexta69/metube)
  - port 8081:8081
  - Volume File/Folder: docker/catMetube <-> Mount path: /downloads Type: rw
  - Links: <none>
  - Network Network Name: bridge - Driver: bridge
  - tbd
- to rebuild on [https://sg.klopfenstein.org/](https://sg.klopfenstein.org/)
  - launch docker UI from top bar
  - stop cf-metube1 container
  - delete container
  - delete image
  - add image
  - launch image
  - put in cf-metube1 configs
- C:\Users\chris>ssh -p 2020 buadmin@192.168.9.2
```
buadmin@sg:/volume1/docker/catMetube/.metube$ ls -alu
total 128
drwxrwxrwx+ 2 1000 1000  4096 Aug 31 12:30 .
drwxrwxrwx+ 4 1000 1000 12288 Aug 31 15:15 ..
-rwxrwxrwx+ 1 1000 1000 65536 Aug 31 12:46 completed
-rwxrwxrwx+ 1 1000 1000 16384 Aug 31 12:30 pending
-rwxrwxrwx+ 1 1000 1000 28672 Aug 31 12:46 queue
buadmin@sg:/volume1/docker/catMetube/.metube$ cd ..
buadmin@sg:/volume1/docker/catMetube$ ls -alu
total 27876632
drwxrwxrwx+ 4 1000 1000      12288 Aug 31 10:04 .
drwxrwxrwx+ 6 root root       4096 Aug 31 10:06 ..
-rwxrwxrwx+ 1 1000 1000   40257207 Feb  6  2025 8 Ways to Make WINDOWS in SketchUp!.webm
-rwxrwxrwx+ 1 1000 1000   60047000 Feb 17  2025 Adding DOORS AND WINDOWS to a Floor Plan in SketchUp Free!.webm
-rwxrwxrwx+ 1 1000 1000   38967280 Sep 27  2024 Animating Doors and Windows with DYNAMIC COMPONENTS in SketchUp!.webm
-rwxrwxrwx+ 1 1000 1000  349695799 Feb  1  2025 ATSC 3 DRM Workaround with the Channels App! Restore gateway functionality.webm
-rwxrwxrwx+ 1 1000 1000 2476436381 Feb  3  2025 Build and Deploy a Banking App with Finance Management Dashboard Using Next.js 14.webm
-rwxrwxrwx+ 1 1000 1000  137853237 Feb  1  2025 Create a BLE app for your mobile phone! Control an ESP32 with BLE.webm
-rwxrwxrwx+ 1 1000 1000  102262853 Jun 27  2020 Creating Floor Plans FROM IMAGES in SketchUp Free!.webm
-rwxrwxrwx+ 1 1000 1000  322451029 Feb  3  2025 Deploy PiHole with a Cloudflare Tunnel to Protect Your Privacy - Tutorial.webm
-rwxrwxrwx+ 1 1000 1000  540652509 Feb  1  2025 DON'T Expose Internal Applications To The Internet! Restrict Access NOW!.webm
-rwxrwxrwx+ 1 1000 1000  522705240 Feb  1  2025 Don't Let Apple & Google Harvest Your Photos, Use Immich to Self-Host Your Own Cloud!.webm
-rwxrwxrwx+ 1 1000 1000  139647355 Sep  7  2024 Duane & Floppy, WHO-TV. PM Magazine, 1980.mp4
-rwxrwxrwx+ 1 1000 1000  207299634 Feb  2  2025 Easily Manage And Search All Of Your Documents - Paperless-NGX.webm
-rwxrwxrwx+ 1 1000 1000   28134455 Jul 11  2024 Ford on the Phone - SNL.webm
-rwxrwxrwx+ 1 1000 1000   47040100 Mar 27  2024 GETTING STARTED with SketchUp Free - Lesson 1 - BEGINNERS Start Here!.webm
-rwxrwxrwx+ 1 1000 1000   63379922 Feb 17  2025 GETTING STARTED with SketchUp Free - Lesson 2 - Creating a House Model.webm
-rwxrwxrwx+ 1 1000 1000   57594037 Feb 17  2025 GETTING STARTED with SketchUp Free - Lesson 3 - Components, Copies, and Curves.webm
-rwxrwxrwx+ 1 1000 1000  103310861 Feb 17  2025 GETTING STARTED with SketchUp Free - Lesson 4 - Working with Materials in the Online Version.webm
-rwxrwxrwx+ 1 1000 1000   25243795 Feb 17  2025 GETTING STARTED with SketchUp Free - Lesson 5 - Free Models from the 3D Warehouse.webm
-rwxrwxrwx+ 1 1000 1000   93576370 Mar 16  2024 Getting Started with SketchUp Pro in 2024 Part 6 - Doors and Windows!.webm
-rwxrwxrwx+ 1 1000 1000  110566057 Nov 11  2024 Gitea - Keep Your Repo Private At Home!.webm
-rwxrwxrwx+ 1 1000 1000  347655618 Nov 11  2024 GPU Acceleration in Kubernetes with Jellyfin (or Anything!) - Intel, Nvidia, AMD.webm
-rwxrwxrwx+ 1 1000 1000  562579085 Nov 11  2024 Homelab Monitoring Made Easy - Part 1： Tools Overview - Grafana, Prometheus, InfluxDB, Telegraf.webm
-rwxrwxrwx+ 1 1000 1000  585060795 Nov 11  2024 Homelab Monitoring Made Easy - Part 2： Creating Dashboards For Docker, Crowdsec, and Sophos XG.webm
-rwxrwxrwx+ 1 1000 1000    8921555 Feb 17  2025 How to CHANGE UNITS in SketchUp Free (Online Version Tutorial).mkv
-rwxrwxrwx+ 1 1000 1000   87892263 Feb 19  2025 How to Model ROOFS in SketchUp! (9 Different Kinds!).webm
-rwxrwxrwx+ 1 1000 1000  300139244 Dec  9  2024 How To Navigate 100's of Plex Free Live TV Channels - NFL Recently Added!.webm
-rwxrwxrwx+ 1 1000 1000   28656781 Feb 17  2025 How to PRINT from the Web Version of SketchUp! (Online Version Tutorial).mkv
-rwxrwxrwx+ 1 1000 1000   44206241 Feb 17  2025 How to Render Models from SketchUp Free - FOR FREE!.webm
-rwxrwxrwx+ 1 1000 1000   28086918 Feb 17  2025 Importing and Using IMAGES in SketchUp Free!.webm
drwxrwxrwx+ 2 1000 1000       4096 Aug 31 10:04 Learn SketchUp in 30 Days!
-rwxrwxrwx+ 1 1000 1000   82804227 Aug  5  2022 Learn SketchUp in 30 Days DAY 8 - STAIR AND RAILING!.mkv
-rwxrwxrwx+ 1 1000 1000 6083405119 Feb  7  2025 Light of the Mind, Light of the World： Illuminating Science Through Faith ｜ Spencer Klavan ｜ EP 489.webm
-rwxrwxrwx+ 1 1000 1000  341271374 Dec  9  2024 Manage Your Plex Server with Plex Dash on Your Smartphone - New Update!.webm
-rwxrwxrwx+ 1 1000 1000   97181147 Feb 18  2025 Messy SketchUp Models？ Learn to Organize Geometry the Right Way!.webm
drwxrwxrwx+ 2 1000 1000       4096 Aug 31 10:04 .metube
-rwxrwxrwx+ 1 1000 1000  373469964 May  1 08:57 Modern All Rust Stack - Dioxus, Axum, Warp, SurrealDB.webm
-rwxrwxrwx+ 1 1000 1000  221665530 Nov 16  2024 Mosquitto MQTT Broker - Explanation and Setup.webm
-rwxrwxrwx+ 1 1000 1000  622529620 Dec 13  2024 Moving Plex Docker Containers is Easy! Here's How..webm
-rwxrwxrwx+ 1 1000 1000 1033265683 Nov 13  2024 my local, AI Voice Assistant (I replaced Alexa!!).webm
-rwxrwxrwx+ 1 1000 1000   87239754 Feb 16  2025 nRF Connect SDK hands-on, part 1： Rapid prototyping with nRF Connect SDK.webm
-rwxrwxrwx+ 1 1000 1000   87438102 Nov 19  2024 nRF Connect SDK hands-on, part 2： Sensors in nRF Connect SDK.mkv
-rwxrwxrwx+ 1 1000 1000   76335396 Nov 19  2024 nRF Connect SDK hands-on, part 3：  Send and receive data through Bluetooth LE.mkv
-rwxrwxrwx+ 1 1000 1000   82379942 Nov 19  2024 nRF Connect SDK hands-on, part 4： Storing data on non-volatile memory.mkv
-rwxrwxrwx+ 1 1000 1000  108607518 Nov 19  2024 nRF Connect SDK hands-on, part 5： Power Optimization and the PPK2.mkv
-rwxrwxrwx+ 1 1000 1000  114845551 Nov 23  2024 nRF Connect SDK hands-on, part 6： Adding FOTA over Bluetooth LE.mkv
-rwxrwxrwx+ 1 1000 1000  667372873 Dec  9  2024 Plex Free Movies and TV How To & Tutorial： Organize All of Your Entertainment!.webm
-rwxrwxrwx+ 1 1000 1000  302992211 Dec 13  2024 Plex Pass quality of life features： skip control, passout protection and Plexamp mix builders!.webm
-rwxrwxrwx+ 1 1000 1000  159949132 Nov 11  2024 Protecting Homelab Apps with BunkerWeb.webm
-rwxrwxrwx+ 1 1000 1000  218762387 Nov 11  2024 Proxmox Backup Server Saves You Money And Time!.webm
-rwxrwxrwx+ 1 1000 1000  198999058 Nov 16  2024 Proxmox LXC - How To Guide - Better Than A VM？.webm
-rwxrwxrwx+ 1 1000 1000  455958548 Nov 11  2024 Secure Cloudflare Tunnels with vLANs and an Internal Firewall Before It's Too Late!.webm
-rwxrwxrwx+ 1 1000 1000  505514179 Oct 17  2024 Security Now 287： BitCoin CryptoCurrency.mp4
-rwxrwxrwx+ 1 1000 1000  392510055 Nov 11  2024 Serve Plex Media to Legacy Devices Via DLNA ! No Plex Client Required!.webm
-rwxrwxrwx+ 1 1000 1000  246067373 Nov 16  2024 SMB Server In Docker with ZFS! Simple, Cheap, and Efficient!.webm
-rwxrwxrwx+ 1 1000 1000  195113427 Nov 11  2024 Software Defined Network Guide - SDN - How To Create.webm
-rwxrwxrwx+ 1 1000 1000  292966634 Nov 11  2024 Split A GPU Between Multiple Computers - Proxmox LXC (Unprivileged).webm
-rwxrwxrwx+ 1 1000 1000  114971025 Nov 11  2024 Split a GPU Between Multiple Pods in Kubernetes.webm
-rwxrwxrwx+ 1 1000 1000  582439930 Nov 16  2024 SSL Certificates Made EASY With Traefik Proxy, Clouflare, and Let's Encrypt - Tutorial.webm
-rwxrwxrwx+ 1 1000 1000  213972231 Feb  7  2025 Star Trek： The Last Voyage - SNL.webm
-rwxrwxrwx+ 1 1000 1000 2230850454 Feb  3  2025 Superintelligence is Upon Us ｜ Marc Andreessen ｜ EP 515.webm
-rwxrwxrwx+ 1 1000 1000   42324467 Feb  9  2014 THE FLOPPY SHOW  WITH DUANNE ELLETT- Aired in the 1980s #floppyshow #1980s #80s #cartoons.mp4
-rwxrwxrwx+ 1 1000 1000   32282770 Mar 18  2024 The Floppy Show with guest Adam West as Batman - November 5 1977.webm
-rwxrwxrwx+ 1 1000 1000    5510446 Oct 10  2024 The Floppy Xmas Show (End).mp4
-rwxrwxrwx+ 1 1000 1000   10108020 Nov  6  2024 The Floppy Xmas Show (＂Twas The Night Before Xmas＂).mp4
-rwxrwxrwx+ 1 1000 1000  170095969 Jan  4  2025 The Killer Bees： Home Invasion - SNL.webm
-rwxrwxrwx+ 1 1000 1000   30771318 Jan 25  2025 The Wolverines - Saturday Night Live.webm
-rwxrwxrwx+ 1 1000 1000  579386309 Jan 22  2025 The YouTube Alternative Nobody's Talking About ! Peertube.webm
-rwxrwxrwx+ 1 1000 1000  412050502 Nov 16  2024 Use Proxmox Cloud-Init to Deploy Your Virtual Machines! Kubernetes At Home - Part 2.webm
-rwxrwxrwx+ 1 1000 1000  382451954 Dec  9  2024 Using Plex on a Personal VPN Like Tailscale.webm
-rwxrwxrwx+ 1 1000 1000   27059822 Dec  1  2024 Weekend Update： John Belushi On March - Saturday Night Live.webm
-rwxrwxrwx+ 1 1000 1000   51613238 Jan 25  2025 Weekend Update with Chevy Chase - Saturday Night Live.webm
-rwxrwxrwx+ 1 1000 1000 1502179525 Feb  4  2025 We Who Wrestle With God： In the Image of God.webm
-rwxrwxrwx+ 1 1000 1000 1009959253 Feb 16  2025 You Need to Learn This! Cloudflare Tunnel Easy Tutorial.webm
-rwxrwxrwx+ 1 1000 1000  638352881 Dec 13  2024 Youtube Alternative Peertube Questions Answered! Copyright Strikes, Monetization, Costs and More.webm
buadmin@sg:/volume1/docker/catMetube$
```
