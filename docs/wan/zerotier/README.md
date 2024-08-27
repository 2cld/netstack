# ZeroTier 
- [https://www.zerotier.com/](https://www.zerotier.com/)
- [zerotier - debug no ping](https://discuss.zerotier.com/t/node-online-but-unable-to-ping-from-other-nodes/10016)  put this somewhere
```
zerotier-cli peers
```

## ghadmin test
- [https://my.zerotier.com/network/d5e5fb65371eb4a4](https://my.zerotier.com/network/d5e5fb65371eb4a4)
- 10.147.17.0/24 (LAN)	


## docker cmds
- View node status
  ```
  docker exec -it zt zerotier-cli status
  ```
- Join your network
  ```
  docker exec -it zt zerotier-cli join e5cd7a9e1cae134f
  ```
- Authorize the NAS on your network. Then view the network status:
  ```
  docker exec -it zt zerotier-cli listnetworks
  ```
- Show running container (optional)
  ```
  docker ps
  ```
- Enter the container (optional)
  ```
  docker exec -it zt bash
  ```

## Zerotier on DS411+II from [lan/storage/synology](../../lan/storage/synology)
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
  
<!--
```
0c82af27d7
a6:b8:9c:98:42:2c	
catwin2012r2
old 1U Dell
10.147.17.105
10.147.17.x
22 DAYS
1.10.6
208.126.60.28
		1a5db4f324
a6:ae:43:83:96:df	
tesla
gh Win10 Surfacebook Pro
10.147.17.90
10.147.17.x
25 DAYS
1.10.5
208.126.60.28
		1ef47703c3
a6:aa:ea:40:66:38	
slubuntu
ubuntu on slpromox
10.147.17.21
10.147.17.x
ABOUT 1 MONTH
1.10.6
24.216.208.251
		2e6f03bad5
a6:9a:71:34:df:2e	
cattwin10
cattv 2150 machine
10.147.17.1
10.147.17.x
2 MONTHS
1.10.2
24.149.22.11
		38eda056bc
a6:8c:f3:97:33:47	
gusGram
gus i7 win11
10.147.17.190
10.147.17.x
10 DAYS
1.10.6
24.216.208.251
		3a4587b729
a6:8e:5b:b0:d2:d2	
catghwin10
cat Windows 10 Test Workstation on Grasshorse Grid
10.147.17.127
10.147.17.x
22 DAYS
1.10.2
208.126.60.28
		5de48afbac
a6:e9:fa:bd:9e:57	
cfPlex
(description)
10.147.17.228
10.147.17.x
LESS THAN A MINUTE
1.10.6
24.149.22.11
		6b756b8256
a6:df:6b:5c:e7:ad	
catpixel6a
cat farm phone
10.147.17.45
10.147.17.x
9 MONTHS
1.8.9
24.149.22.11
		6cf5d651b2
a6:d8:eb:e1:34:49	
slwin10
Windows 10 slproxox
10.147.17.108
10.147.17.x
2 MONTHS
1.10.6
24.216.208.251
		71d34c8276
a6:c5:cd:7b:e7:8d	
catmini
cat-macci OSX 10.16.6 quad i7 16GB
10.147.17.59
10.147.17.x
1 MINUTE
1.10.1
24.149.22.11
		88000adc23
a6:3c:1e:3d:b9:d8	
macci
catmini workstation
10.147.17.27
10.147.17.x
3 MONTHS
1.10.1
24.217.248.77
		8f29de0511
a6:3b:37:e9:60:ea	
hpi5
win10laptop
10.147.17.102
10.147.17.x
4 MONTHS
1.10.3
24.149.22.11
		9235e19098
a6:26:2b:d6:f5:63	
ghwin11
win11 vm on cg2
10.147.17.246
10.147.17.x
2 MONTHS
1.10.6
24.149.22.11
		9ea54b4640
a6:2a:bb:7c:23:bb	
wool
trink old
10.147.17.92
10.147.17.x
12 MONTHS
1.8.9
156.146.54.100
		a540b8c035
a6:11:5e:8f:a5:ce	
Cybertruck
gh Windows 10 i7 32GB GTX 660
10.147.17.219
10.147.17.x
18 DAYS
1.6.4
24.149.22.11
		b8513b5c72
a6:0c:4f:0c:39:89	
felt
trink
10.147.17.73
10.147.17.x
12 MONTHS
1.10.0
67.188.101.34
		d47f31422d
a6:60:61:06:27:d6	
gusHPlaptop
gus hp aptop in sl
10.147.17.66
10.147.17.x
LESS THAN A MINUTE
1.10.6
24.216.208.251
		f08e26fd5b
a6:44:90:11:98:a0	
nswin11
netstack win11
10.147.17.220
10.147.17.x
6 MONTHS
1.10.3
208.126.60.28
		f0bc1ef1e1
a6:44:a2:29:94:1a	
catsurface
cat Windows 10 Surface Pro
10.147.17.223
10.147.17.x
1 MINUTE
1.4.6
24.149.22.11
```
-->
