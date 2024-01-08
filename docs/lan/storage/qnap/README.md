[edit](https://github.com/2cld/netstack/edit/master/docs/lan/storage/qnap/README.md)

- [https://www.qnap.com/en/utilities/essentials](https://www.qnap.com/en/utilities/essentials)
- [https://www.qnap.com/en/how-to/tutorial/article/how-to-search-and-manage-a-qnap-nas-using-qfinder-pro](https://www.qnap.com/en/how-to/tutorial/article/how-to-search-and-manage-a-qnap-nas-using-qfinder-pro)
- test
- test

## [qnap reset doc](https://docs.qnap.com/operating-system/qts/4.4.x/en-us/GUID-78B53FB8-F009-43A5-AC57-3EAA0CA00C26.html#:~:text=all%20disk%20volumes.-,Go%20to%20Control%20Panel%20%3E%20System%20%3E%20Backup%2FRestore%20%3E%20Restore,Click%20OK.)
- Poweron press and hold reset (back of unit) for 3 sec (hear a beep)
- IPAddress:8080 is UI
- admin and admin is pw

## Zerotier on qnap [qnap docs](https://docs.zerotier.com/qnap/)
- Install QVPN Service
- For TS-431 - ARMv7 [arm-x31 zerotier package](https://download.zerotier.com/dist/qnap/)
- Enable ssh
- use zerotier-cli to [Start zerotier network](https://docs.zerotier.com/start/)
- ssh admin@192.168.6.35
- Join 52b337794f721ef7 cattv
  ```
  sudo zerotier-cli join 52b337794f721ef7
  ```
- zerotier cloud sees it but cannot ping or access
- turned off
- 

## Plex on qnap
```
/share/CACHEDEV2_DATA/plex/gusMusic
```

- [https://discuss.zerotier.com/t/guide-setup-zerotier-to-connect-3-sites-with-ipv4-and-ipv6/14099](https://discuss.zerotier.com/t/guide-setup-zerotier-to-connect-3-sites-with-ipv4-and-ipv6/14099)
- [zerotier not working on qnap 5.0.1](https://forum.qnap.com/viewtopic.php?t=167752)
- tbd

## Nuke Plex on qnap
- [plex_is_eating_up_all_my_resources](https://www.reddit.com/r/qnap/comments/17rg6i9/ts462_plex_is_eating_up_all_my_resources_and_wont/)
- Powershell on slwin11 ssh into slsg2
```
ssh admin@192.168.0.6
```
- Kill plex
```
sudo /etc/init.d/plex.sh stop
```
- Go back to [buadmin slsg2 web http://192.168.0.6:8080](http://192.168.0.6:8080)
- Uninstall Plex Media Server app
