[edit](https://github.com/2cld/netstack/edit/master/docs/lan/compute/wsl/wsl-docker-install.md)  - [../wsl](../) - [../../compute](../../)
# wsl docker install

- Open PowerShell as administrator verify vhdx dist and path
- wsl list distributions
  ```
  wsl --list
  ```
  should get
  ```
  Windows Subsystem for Linux Distributions:
  Ubuntu-24.04 (Default)
  PS C:\WINDOWS\system32>
  ```
- Find location
  ```
  (Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object {Get-ItemProperty $_.PSPath}) | select DistributionName,BasePath,VhdFileName
  ```
  shoud get
  ```
  DistributionName BasePath                                       VhdFileName
  ---------------- --------                                       -----------
  Ubuntu-24.04     E:\wsl\Ubuntu2404-240425\Ubuntu_2404.0.5.0_x64 ext4.vhdx
  ```
- Open PowerShell as administrator and run to ensure your Ubuntu distribution is using WSL2
  ```
  wsl --set-version Ubuntu-24.04 2
  ```
- Update Package List and Install Dependencies:
  ```
  sudo apt update && sudo apt upgrade -y
  ```
- Install necessary dependencies.
  ```
  sudo apt install -y ca-certificates curl gnupg
  ```
- Add Docker's GPG Key and Repository:
  ```
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  ```
- Add the Docker repository.
  ```
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  ```
- Install Docker Engine, CLI, and containerd: Update the package list again:
  ```
  sudo apt update
  ```
- Install Docker.
  ```
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ```
- Test Docker
  ```
  sudo docker run hello-world
  ```

# wsl docker backup
- reference https://www.mslinn.com/blog/2022/01/10/wsl-backup.html
- wsl export Ubuntu-24.04 F:\backup\ubuntu-20250630.tar
  ```
  wsl --export 
  ```
- wsl unregister
- setup net location
- wsl set version 2 to avoid import error
  ```
  wsl --set-version Ubuntu-24.04 2
  ```
- wsl import standard way
  ```
  wsl --import Ubuntu-24.04 E:\wsl\ F:\backup\ubuntu-20250630.tar
  ```
- test


---
- import issues option
- wsl import through vhd ?? [see article - I did not test](https://www.mslinn.com/blog/2022/01/10/wsl-backup.html)
  ```
  wsl --import Ubuntu-24.04-d^
  D:\WSL\Ubuntu-22.04\^
  %HOMEDRIVE%%HOMEPATH%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu20.04onWindows_79rhkp1fndgsc\LocalState\ext4.vhdx^
  --vhd
  ```
---

# issue with docker not running
- ai prompt [google aimode](https://www.google.com/search?q=I%27m+a+windows+admin+working+with+docker+running+under+wsl.++how+do+i+start+the+docker+daemon+under+wsl%3F&sourceid=chrome&ie=UTF-8&udm=50&aep=48&cud=0&qsubts=1762698651748&mstk=AUtExfDoYFPUliPJ1lqtOdz5PAg-VGSSouCxzkPjdFO9quCVaBhaam3PNmyQSPK8GwtJ-UZp9Zq9VyjEsKC7yVzhrw-1uFTBsZfwauo3bJ6lv_QRGhtAAm7-cWb3h6KydrbmlagJ0OGxoIRMplZcH52oQAdGXRmJeYkkPhU&csuir=1&mtid=xqUQaYqbK4KrptQPk6WZuQg)
- Step 1: Enable systemd in WSL
- sudo nano /etc/wsl.conf
```
[boot]
systemd=true
```
- edit, exit, shudown, restart wls in windows cmd check docker ps
```
ghadmin@Cybertruck:/mnt/c/Users/ghadmin$ sudo vi /etc/wsl.conf
[sudo] password for ghadmin:
ghadmin@Cybertruck:/mnt/c/Users/ghadmin$ exit
logout
C:\Users\ghadmin>wsl --shutdown
C:\Users\ghadmin>wsl
ghadmin@Cybertruck:/mnt/c/Users/ghadmin$ docker ps
```

other crap
---
OLD install
---

```
 12  sudo apt-get update
 13  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
 14  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
 15  sudo apt-get update
 16  sudo apt-get install ca-certificates curl
 17  sudo install -m 0755 -d /etc/apt/keyrings
 18  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
 19  sudo chmod a+r /etc/apt/keyrings/docker.asc
 20  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
 21  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
 22  sudo apt-get update
 23  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
 24  docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
 25  docker --status
 26  docker ps
 27  sudo docker ps
 28  sudo docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
 29  ip a
 30  docker container ls
 31  suso docker container ls
```
