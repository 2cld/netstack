[edit](https://github.com/2cld/netstack/edit/master/docs/portals/eve-ng/README.md) and [../ portals](../)

# eve-ng network simulation

- notebooklm [EVE-NG Lab Setup](https://notebooklm.google.com/notebook/0f519cd9-523e-47f0-a659-aed8146dde49)
- documents  [EVE-NG Documents](https://www.eve-ng.net/index.php/documentation/)
- cookbook [EVE-NG Cookbook](https://www.eve-ng.net/images/EVE-COOK-BOOK-1.2.pdf)
- EVE-NG [Hyper-V Install on CyberTruck](./install.md)
- VM on ct evelab - root eve
- VMWorkstation win10 network bridge enable vnet0 issue [yt video](https://www.youtube.com/watch?v=VVa1Q1wYgEY)
  - the setting does not seem to 'stick'
  - leave auto but use button to access ethernet windows net and toggle
- Connect lab to internet
  - [yt](https://www.youtube.com/watch?v=zDyEkyJizRQ)
  - Use Management(Cloud0) this connects to vmNet0 which needs to be a bridge on vmware host
  - Other nets are vnets on eve-ng host
- tbd

```
root@evelab:/opt/unetlab/addons# ls -alu
total 20
drwxr-xr-x  5 root root 4096 Jul 21 22:28 .
drwxr-xr-x 13 root root 4096 Jul 21 22:28 ..
drwxr-xr-x  2 root root 4096 Jul 21 21:16 dynamips <--For Routers
drwxr-xr-x  4 root root 4096 Jul 11 01:28 iol      <--For Switches
drwxr-xr-x  2 root root 4096 Jul 21 21:16 qemu     <--For OS
root@evelab:/opt/unetlab/addons#
```

# mikrotik node
- Install [eve-ng mikrotik](https://www.eve-ng.net/index.php/documentation/howtos/howto-add-mikrotik-cloud-router/)
- Good refs
  - [yt network berg](https://www.youtube.com/@TheNetworkBerg/videos)
  - [yt network berg basic mikrotik cli](https://www.youtube.com/watch?v=EYCjuvTd3dY)
  - [yt MikroTik Default Config](https://www.youtube.com/watch?v=H7Od7HtxEMc)
  - Basic [txt Mikrotik Config](https://docs.sim-cloud.net/en/solutions-virtual-router/mikrotik/basic-setting.html)
- mikrotik [cloud router download](https://mikrotik.com/download)
- D:\cfops-installs\EVE-NG-LAB>scp chr-6.49.18.img root@192.168.6.89:/opt/unetlab/addons/qemu/mikrotik-6.49.18/
```
root@evelab:/opt/unetlab/addons/qemu/mikrotik-6.49.18# pwd
/opt/unetlab/addons/qemu/mikrotik-6.49.18
root@evelab:/opt/unetlab/addons/qemu/mikrotik-6.49.18# mv chr-6.49.18.img hda.qcow2
root@evelab:/opt/unetlab/addons/qemu/mikrotik-6.49.18# /opt/unetlab/wrappers/unl_wrapper -a fixpermissions
```
- Start and login admin <> nopasswd - will force pw change eve (admin eve)
- Default should enable dhcp-client on ether1
```
[admin@MikroTik] > ip service print 
Flags: X - disabled, I - invalid 
 #   NAME                  PORT ADDRESS                                                     CERTIFICATE                
 0   telnet                  23
 1   ftp                     21
 2   www                     80
 3   ssh                     22                                              
 4 XI www-ssl                443                                                             none                       
 5   api                   8728
 6   winbox                8291
 7   api-ssl               8729                                                             none                       
[admin@MikroTik] > 
```
- Enable ssh on WAN subnet (does not work for windows ssh clients)
```
[admin@MikroTik] > ip ssh set always-allow-password-login=yes
[admin@MikroTik] > ip service set ssh address=192.168.6.0/24
```
- DHCP client
```
[admin@MikroTik] > ip  dhcp-client print
```
- DHCP client set
```
ip dhcp-client add interface-ether1 disabled=no use-peer-dns=yes use-peer-ntp=yes add-default-route=yes
```
```
ip address print
```
```
ip route print
```
```
interface bridge add name=LAN
```
```
interface bridge port add interface=ether2 bridge=LAN
interface bridge port add interface=ether3 bridge=LAN
interface bridge port add interface=ether4 bridge=LAN
```
```
ip address add address=192.168.88.1/24 interface=LAN
```
```
ip dhcp-server setup
```
- interface: LAN
- address space: 192.168.88.0/24
- gateway: 192.168.88.1
- pool: 192.168.88.130-192.168.88.189
- DNS: 8.8.8.8,1.1.1.1
- lease: 8h
```
ip dhcp-server export
```
```
ip dhcp-server lease print
```
```
ip arp print
```
```
ip firewall nat add chain=srcnat action=masquerade out-interface=ether1 src-address=192.168.88.0/24
```
```
export
```
- tbd
## mikrotik zt config
- [yt network berg](https://www.youtube.com/watch?v=QKjWLfGfkF0)
- docker on mikrotik

# pfsense node
- Install
- tbd

# ubuntu node
- Install [eve-ng ubuntu](https://www.eve-ng.net/index.php/documentation/howtos/howto-create-own-linux-host-image/)

# windows node
- Install [eve-ng windows](https://www.eve-ng.net/index.php/documentation/howtos/howto-create-own-windows-host-on-the-eve/)
