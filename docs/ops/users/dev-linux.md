Linux user crap
```
usermod -a -G examplegroup exampleusername
usermod -aG sudo username
$ useradd appadmin1 -u 4100 -g 4100 -m -s /bin/bash
https://stackoverflow.com/questions/23601844/how-to-create-user-in-linux-by-providing-uid-and-gid-options
https://linuxize.com/post/how-to-list-groups-in-linux/
Usage: /sbin/mkhomedir_helper <username> [<umask> [<skeldir>]]
https://serverfault.com/questions/63764/create-home-directories-after-create-users
sudo passwd vivek
https://www.cyberciti.biz/faq/linux-set-change-password-how-to/#google_vignette
lsb_release -a
```

ssh key
```
ssh-keygen -t ed25519 -C "your_email@example.com"
```

git setup
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
