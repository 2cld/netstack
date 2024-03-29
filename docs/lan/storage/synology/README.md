[edit]()

# DS411+II
- User interface on port 5000 [http://192.168.6.6:5000](http://192.168.6.6:5000)
- Control Panel -> Storage for Drive status

## Zerotier on DS411+II from [wan/zerotier](../../../wan/zerotier)
- Instructions [https://docs.zerotier.com/synology/](https://docs.zerotier.com/synology/)
  - [http://www.homeops.tech/2020/07/15/Zero-Tier-On-Synology/](http://www.homeops.tech/2020/07/15/Zero-Tier-On-Synology/)
  - [https://www.reddit.com/r/cordcutters/comments/5877jo/hdhomerun_connect_static_ip/?rdt=36595](https://www.reddit.com/r/cordcutters/comments/5877jo/hdhomerun_connect_static_ip/?rdt=36595)
  - [https://docs.zerotier.com/start/](https://docs.zerotier.com/start/)
  - [https://zerotier.atlassian.net/wiki/spaces/SD/pages/29065282/Command+Line+Interface+zerotier-cli](https://zerotier.atlassian.net/wiki/spaces/SD/pages/29065282/Command+Line+Interface+zerotier-cli)
  - [https://zerotier.atlassian.net/wiki/spaces/SD/pages/193134593/Bridge+your+ZeroTier+and+local+network+with+a+RaspberryPi](https://zerotier.atlassian.net/wiki/spaces/SD/pages/193134593/Bridge+your+ZeroTier+and+local+network+with+a+RaspberryPi)
  - [https://zerotier.atlassian.net/wiki/spaces/SD/pages/224395274/Route+between+ZeroTier+and+Physical+Networks](https://zerotier.atlassian.net/wiki/spaces/SD/pages/224395274/Route+between+ZeroTier+and+Physical+Networks)

- For DSM v 6.2 [zerotier package download](https://download.zerotier.com/dist/synology/)
- What package [https://kb.synology.com/en-nz/DSM/tutorial/What_kind_of_CPU_does_my_NAS_have](https://kb.synology.com/en-nz/DSM/tutorial/What_kind_of_CPU_does_my_NAS_have)
- DS411+II	Intel Atom D525	2	4	✓	X86	DDR2 1GB so [https://download.zerotier.com/dist/synology/zerotier_x86-6.2.4_1.8.7-1.spk](https://download.zerotier.com/dist/synology/zerotier_x86-6.2.4_1.8.7-1.spk)
- no GUI so ssh using buadmin
  ```
  ssh -p 2020 buadmin@192.168.6.6
  ```
- Zerotier cli [zerotier-cli docs](https://zerotier.atlassian.net/wiki/spaces/SD/pages/29065282/Command+Line+Interface+zerotier-cli)
- zerotier status
  ```
  sudo zerotier-cli status
  ```
- zerotier join
  ```
  sudo zerotier-cli join
  ```
- zerotier status
  ```
  sudo zerotier-cli status
  ```
