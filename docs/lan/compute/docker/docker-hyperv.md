[edit]()

- ssh nsadmin@192.168.6.106
- cockpit [http://192.168.6.106:9090](http://192.168.6.106:9090)

# Docker Hyper-V
- nsdockerhv	192.168.6.106	00:15:5d:c0:01:05
- nsUb2404hv NetStack Ubuntu 24.04.3 Hyper-V vm on ? Cyber Truck ?
- Installed via quick start using D:\vmhv\ubuntu-24.04.3-desktop-amd64.iso
- CyberTruck C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\nsUb2404hv_806410E7-BDBF-44D8-88C6-C115BBD90382.avhdx

```powershell
PS C:\WINDOWS\system32> Get-VMIntegrationService nsUB2404hv

VMName     Name                    Enabled PrimaryStatusDescription SecondaryStatusDescription
------     ----                    ------- ------------------------ --------------------------
nsUb2404hv Guest Service Interface False   OK
nsUb2404hv Heartbeat               True    OK
nsUb2404hv Key-Value Pair Exchange True    No Contact
nsUb2404hv Shutdown                True    OK
nsUb2404hv Time Synchronization    True    OK
nsUb2404hv VSS                     True    OK                       The protocol version of the component installed in the virtual machine does not match the version expected by t...

PS C:\WINDOWS\system32> Enable-VMIntegrationService -VMName "nsUb2404hv" -Name "Guest Service Interface"
PS C:\WINDOWS\system32> Get-VMIntegrationService nsUB2404hv

VMName     Name                    Enabled PrimaryStatusDescription SecondaryStatusDescription
------     ----                    ------- ------------------------ --------------------------
nsUb2404hv Guest Service Interface True    No Contact
nsUb2404hv Heartbeat               True    OK
nsUb2404hv Key-Value Pair Exchange True    No Contact
nsUb2404hv Shutdown                True    OK
nsUb2404hv Time Synchronization    True    OK
nsUb2404hv VSS                     True    OK                       The protocol version of the component installed in the virtual machine does not match the version expected by t...


PS C:\WINDOWS\system32>
```

# ssh
- ssh install
```bash
sudo apt update
```
```bash
sudo apt install openssh-server -y
```
- ssh check
```bash
sudo systemctl status ssh
```
- mod config
```bash
sudo vi /etc/ssh/sshd_config
```
- restart
```bash
sudo systemctl restart ssh
```
- firewall
```bash
sudo ufw allow ssh
sudo ufw enable
sudo ufw status
```

# docker
-  Install necessary packages for the repository
```bash
sudo apt install apt-transport-https ca-certificates curl gnupg -y
```
- Add Docker's official GPG key
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```
- Add the Docker repository to the APT sources list
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
- Install Docker and plug-ins
```bash
# Update the package index with the Docker repository
sudo apt update
# Install the latest version of Docker and its plugins
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```
- Manage docker as a non-root user
```bash
# Add your user to the docker group
sudo usermod -aG docker $USER
# Apply the new group membership
newgrp docker
```
- Verify
```bash
# Verify Docker Engine is working
docker run hello-world

# Verify the Docker Compose plugin is working
docker compose version
```

# cockpit
- apt update and install
```bash
sudo apt update
sudo apt install cockpit -y
```
- enable
```bash
sudo systemctl enable --now cockpit.socket
```
- firewall
```bash
sudo ufw allow 9090/tcp
sudo ufw reload
```
- verify
```bash
sudo systemctl status cockpit
```
- Test [http://192.168.6.106:9090](http://192.168.6.106:9090)

# zerotier [https://my.zerotier.com/](https://my.zerotier.com/)
- install
```bash
curl -s https://install.zerotier.com | sudo bash
```
- status
```bash
sudo zerotier-cli status
```
- Join
```bash
sudo zerotier-cli join <network_id>
```
- Test [https://10.147.17.176:9090](https://10.147.17.176:9090)

# template
- tbd
```bash
```
- tbd
```bash
```
- tbd
```bash
```

