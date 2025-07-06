[edit](https://github.com/2cld/netstack/edit/master/docs/ops/users/dev-linux.md)

## linux user
```
usermod -a -G examplegroup exampleusername
```
```
usermod -aG sudo username
```
```
useradd appadmin1 -u 4100 -g 4100 -m -s /bin/bash
```
- https://stackoverflow.com/questions/23601844/how-to-create-user-in-linux-by-providing-uid-and-gid-options
- https://linuxize.com/post/how-to-list-groups-in-linux/

## ssh
### ssh server
- check status
```
systemctl status sshd
```
- check port
```
ss -tulnp | grep LISTEN
```
```
netstat -tulnp | grep LISTEN
```
- check firewall
```
sudo ufw status verbose
```
```
sudo ufw status numbered
```
- open port
```
sudo ufw allow 22/tcp
```
- install
```
sudo apt install openssh-server
```
```
sudo systemctl enable ssh --now
```
- install if rpi
```
sudo raspi-config
```

### ssh key
```
ssh-keygen -t ed25519-C "your_email@example.com"
```

### git setup
```
git config --global user.name "your name"
```
```
git config --global user.email "your_email@example.com"
```
- add pub key to github https://github.com/settings/keys
- set remote to use ssh
- check where remote is set
```
git remote -v
```
- set remote to ssh url
```
git remote set-url origin git@github.com:2cld/ai.git
```
