relocating truenas disk packs, IP and/or subnet

- https://www.truenas.com/docs/core/coretutorials/network/interfaces/settingstaticip/
- [When to Update Truenas](https://www.youtube.com/watch?v=JcHMNjbizbo)
- 

- Find server on network devices (what DHCP / Static IP does router see)
- Confirm subnet 192.168.1.0/24 or subnet mask 255.255.255.0
- Confirm gateway 192.168.1.1 (lots use this default so should use something else)
- Confirm IP on head of Truenas (cli)
- Confirm web access to truenas
- Confirm Network Settings in Web Access https://www.truenas.com/docs/core/coretutorials/network/
- Confirm Users and user access rights https://www.truenas.com/docs/core/coretutorials/settingupusersandgroups/
- Confirm Settings https://www.truenas.com/docs/core/coretutorials/systemconfiguration/

# Setup remote access
- Remote access via https://remotedesktop.google.com/access/
- Select a machine with access to subnet
- use ghadmin@horseoff.com user to add to remote address (call chris to get pw)
