[edit](https://github.com/2cld/netstack/edit/master/docs/lan/compute/docker/dockerdesktop.md) - [../docker](../) - [../../compute](../../)
# docker desktop

https://forums.docker.com/t/updates-on-how-to-install-docker-to-other-drive-on-windows-11-pro-24h2/148281



Here's how to install Docker Desktop to a custom location using the installer:
1. Download the Docker Desktop Installer from the official website.
2. Open a terminal or Command Prompt as Administrator and navigate to the installer's directory using the cd command.
3. Run the installation command, specifying your desired installation path with the --installation-dir flag. For example:
  ```
  start /w "" "Docker Desktop Installer.exe" install --accept-license --installation-dir=D:\Docker\Docker
  ```

Even with a custom installation path, the docker-desktop-data folder, containing images and containers, will be on the system drive by default. To move this data, you'll need to manage the WSL2 virtual hard disk (VHDX) where Docker stores its data. 
To move docker-desktop-data to another drive:
1. Stop all WSL subsystems by running wsl --shutdown in a terminal.
2. Export docker-desktop-data to a temporary file on your desired drive using: (replace the path with your chosen location)
   ```
   wsl --export docker-desktop-data D:\Docker-Data\docker-desktop-data.tar 
   ```
4. Unregister the old distribution with
   ```
   wsl --unregister docker-desktop-data
   ```
5. Import docker-desktop-data to the new location using a command like: (replace paths as needed)
   ```
   wsl --import docker-desktop-data D:\Docker\data D:\Docker-Data\docker-desktop-data.tar --version 2 
   ```
6. Verify the new location by running:
   ```
   wsl -v -l
   ```
By following these steps, you can install Docker Desktop and move its data to a different drive on Windows 11. 
