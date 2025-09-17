[edit](https://github.com/2cld/netstack/edit/master/docs/ops/users/README.md) - [ops](../)

# User Management

- email
- keys
- storage
- remote access
- [dev-linux](./dev-linux)
- [dev-win-ps](./dev-win-ps)
- [dev-win-wrk](./dev-win-wrk)
- [dev-win-wsl](./dev-win-wsl)
- [ops-win11-cg](./ops-win11-cg)
- [user-win10-pad](./user-win10-pad)
- [tbd](./)


### ssh key pair
1. Check for existing ssh keys
```
ls -al ~/.ssh/id_*.pub
```
2. Generate ssh key pair
```
ssh-keygen -t rsa -b 4096 -C "your_email@domain.com"
```
3. Upload ssh pub key to remote
```
ssh-copy-ide [remote_username]@[server_ip_address]
```
```
ssh [remote_username]@[server_ip_address] mkdir -p .ssh
```
```
cat .ssh/id_rsa.pub | ssh [remote_username]@[server_ip_address] 'cat >> .ssh/authorized_keys'
```
4. Verify remote login
```
ssh [remote_username]@[server_ip_address]
```
5. Permission 700 for .ssh and 640 for authorized_keys
```
ssh [remote_username]@[server_ip_address] "chmod 700 .ssh; chmod 640 .ssh/authorized_keys"
```

### git user setup
1. setup git name and email
```
git config --global user.name "Mona Lisa"
git config --global user.email "Mona@example.com"
```
2. tbd
3. tbd
4. tbd

### ssh for gitea.trink.com
- https://gitea.trink.com/user/settings/keys
- add ssh key

### github setup with Joplin export
github-setup

```
cat@catSurface:/mnt/c$ mkdir code
cat@catSurface:/mnt/c$ cd code/
cat@catSurface:/mnt/c/code$ ls
cat@catSurface:/mnt/c/code$ mkdir wip
cat@catSurface:/mnt/c/code$ cd wip/
cat@catSurface:/mnt/c/code/wip$ git init
Initialized empty Git repository in /mnt/c/code/wip/.git/
cat@catSurface:/mnt/c/code/wip$ git status
On branch master

Initial commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)

        wip.2cld.net/

nothing added to commit but untracked files present (use "git add" to track)
cat@catSurface:/mnt/c/code/wip$ git status
On branch master

Initial commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)

        _resources/
        wip.2cld.net/

nothing added to commit but untracked files present (use "git add" to track)
cat@catSurface:/mnt/c/code/wip$ git add *
cat@catSurface:/mnt/c/code/wip$ git status
On branch master

Initial commit

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)

        new file:   _resources/6ccd8e7ece5d4d65a53fa79c7addee46.jpg
        new file:   wip.2cld.net/README.md
        new file:   wip.2cld.net/docs/README.md

cat@catSurface:/mnt/c/code/wip$ git commit -m "first test commit"
[master (root-commit) 5c20971] first test commit
 3 files changed, 13 insertions(+)
 create mode 100644 _resources/6ccd8e7ece5d4d65a53fa79c7addee46.jpg
 create mode 100644 wip.2cld.net/README.md
 create mode 100644 wip.2cld.net/docs/README.md
cat@catSurface:/mnt/c/code/wip$ git branch -M main
cat@catSurface:/mnt/c/code/wip$ git remote add origin git@github.com:2cld/wip.git
cat@catSurface:/mnt/c/code/wip$ git push -u origin main
The authenticity of host 'github.com (140.82.113.4)' can't be established.
ECDSA key fingerprint is 7b:99:81:1e:4c:91:a5:0d:5a:2e:2e:80:13:3f:24:ca.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'github.com,140.82.113.4' (ECDSA) to the list of known hosts.
Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

- now new key

```
cat@catSurface:/mnt/c/code/wip$ ssh-keygen -t ed25519 -C "christrees@yahoo.com"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/cat/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/cat/.ssh/id_ed25519.
```

- move old keys so it does not use them
```
cat@catSurface:/mnt/c/code/wip$ mkdir ~/.ssh/old
cat@catSurface:/mnt/c/code/wip$ mv ~/.ssh/id_rs* ~/.ssh/old/
cat@catSurface:/mnt/c/code/wip$ ls ~/.ssh/
config-githuberror  id_ed25519  id_ed25519.pub  known_hosts  old
```
 
 - update key to github https://github.com/settings/keys
 - now push repo
 ```
 cat@catSurface:/mnt/c/code/wip$ git push -u origin main
Warning: Permanently added the ECDSA host key for IP address '140.82.112.3' to the list of known hosts.
Counting objects: 8, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (6/6), done.
Writing objects: 100% (8/8), 533.21 KiB | 0 bytes/s, done.
Total 8 (delta 0), reused 0 (delta 0)
remote: To git@github.com:2cld/wip.git
 * [new branch]      main -> main
Branch main set up to track remote branch main from origin.
cat@catSurface:/mnt/c/code/wip$
```

- add CNAME wip.2cld.net file and README.md
- enable githubpages https://github.com/2cld/wip/settings/pages
