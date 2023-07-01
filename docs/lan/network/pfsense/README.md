[documents](../../../) [lan](../../) [network](../)

# lan - network - pfsense

- [pfsense - setup](./setup)

## Notes
### enable-pfsense-web-interface-from-wan [source article](https://www.linuxwave.info/2020/04/enable-pfsense-web-interface-from-wan.html)
- Access text console (ssh or head) select option 8 - Shell
- Run command pfctl -d in shell
```
pfctl -d
```
- pfsense GUI should now be availibe via the IP of the WAN interface
- pfsense reboot or reload will disable or type pfctl -e to block WAN interface again

### SSH-tunnels [source article](https://www.techtarget.com/searchsecurity/tutorial/How-to-use-SSH-tunnels-to-cross-network-boundaries)
