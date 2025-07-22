[edit](https://github.com/2cld/netstack/edit/master/docs/portals/eve-ng/README.md) and [../ portals](../)

# eve-ng network simulation

- notebooklm [EVE-NG Lab Setup](https://notebooklm.google.com/notebook/0f519cd9-523e-47f0-a659-aed8146dde49)
- documents  [EVE-NG Documents]((https://www.eve-ng.net/index.php/documentation/)
- cookbook [EVE-NG Cookbook](https://www.eve-ng.net/images/EVE-COOK-BOOK-1.2.pdf)
- EVE-NG [Hyper-V Install on CyberTruck](./install.md)

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

- Install [eve-ng mikrotik] howtos/howto-add-mikrotik-cloud-router/)
- D:\cfops-installs\EVE-NG-LAB>scp chr-6.49.18.img root@192.168.6.89:/opt/unetlab/addons/qemu/mikrotik-6.49.18/
```
root@evelab:/opt/unetlab/addons/qemu/mikrotik-6.49.18# pwd
/opt/unetlab/addons/qemu/mikrotik-6.49.18
root@evelab:/opt/unetlab/addons/qemu/mikrotik-6.49.18# mv chr-6.49.18.img hda.qcow2
root@evelab:/opt/unetlab/addons/qemu/mikrotik-6.49.18# /opt/unetlab/wrappers/unl_wrapper -a fixpermissions
```
