[edit](https://github.com/2cld/netstack/edit/master/docs/ops/users/README.md)

# User Management

- email
- keys
- storage
- remote access

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
