# casaos

### slcg-vm100 [http://casaos.local/](http://casaos.local/)
- From [https://tteck.github.io/Proxmox/](https://tteck.github.io/Proxmox/) Docker -> CasaOS
	```
	bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/ct/casaos.sh)"
	```
- MAC: BC-24-11-B4-B1-E4 DHCPres: 192.168.0.70
- [BigBearTech - CasaOS Install on Proxmox using tteck script](https://www.youtube.com/watch?v=EF-b9VymLpc)
	- [ssh setup gist](https://gist.github.com/dragonfire1119/8962678cf914e88fe7cccb649c9f5236)
	- set root pw in pve console (root - Time2Invest)
	```
	sudo passwd root
	```
	- edit /etc/ssh/sshd_config set "PermitRootLogin yes"
	- Restart sshd
	```
	systemctl restart sshd
	```
	```
	systemctl status sshd
	```
	- end ssh enable
- [HardwareHaven - CasaOS Setup](https://www.youtube.com/watch?v=w44CypRO5l4)
- casaos - Time2Invest (user for terminal)

### guacamole on casaos via docker
- [BigBearTechWorld - github scripts](https://github.com/bigbeartechworld/big-bear-scripts) - [BigBear Guacamole yml](https://github.com/bigbeartechworld/big-bear-casaos/tree/master/Apps/guacamole)
- [https://hub.docker.com/r/guacamole/guacamolev](https://hub.docker.com/r/guacamole/guacamole)

- [https://github.com/grasshorse/CasaOS-catStore/archive/refs/heads/main.zip](https://github.com/grasshorse/CasaOS-catStore/archive/refs/heads/main.zip)
---

- Install big-bear-casaos [Appstore tc 4:40](https://youtu.be/6cu0kfP50Jg?t=270) via github zip link on [bigbeartechworld - github](https://github.com/bigbeartechworld/big-bear-casaos)
- Install Guacamole
- Connect to app to guacamole path [tc 6:37](https://youtu.be/6cu0kfP50Jg?t=397)
- Refresh page 
- Copy the SQL "/DATA/AppData/big-bear-guacamole/mysql" host path from settings [tc 8:30](https://youtu.be/6cu0kfP50Jg?t=510)
- run command
```
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
```
- then load sql db in /var/lib/mysql/ [tc :11:40](https://youtu.be/6cu0kfP50Jg?t=700)
```
mysql -u guacamole_user -p guacamole_db < initdb.sql
```
- password is "some_password" found in app settings -> mysql
- app should work now
- user: guacadmin - pw: guacadmin
- connections RDP ip port 3389
- [TechnoTim - Guacamole - Windows RDP - tc 7:11](https://youtu.be/LWdxhZyHT_8?t=431)
- [NetworkChuck - Guacamole - Windows RDP - tc 25:46](https://youtu.be/gsvS2M5knOw?t=1546)
- [Using Guacamole docs](https://guacamole.apache.org/doc/gug/using-guacamole.html)

