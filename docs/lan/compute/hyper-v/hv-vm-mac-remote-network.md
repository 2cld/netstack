
<details>
  <summary>Use Microsoft Remote Desktop app to access Ubuntu</summary>
  <p>Can I use Microsoft Remote Desktop app to my Ubuntu 24.04 workstation?</p>
  <p></p>Yes, you can use the Microsoft Remote Desktop app to connect directly to your Ubuntu 24.04 workstation. [1, 2] 
Ubuntu 24.04 includes a native, built-in RDP (Remote Desktop Protocol) server backed by GNOME, meaning you do not need to install laggy third-party software like VNC or manually configure XRDP. [3, 4] 
You can set this up using either Desktop Sharing (to mirror and control your current physical screen) or Remote Login (to log into a fresh, independent session). [4] </p>

- Step 1: Enable Remote Desktop on Ubuntu 24.04 [5] 
   1. Open the Ubuntu Settings app.
   2. Navigate to System on the left sidebar, then click on Remote Desktop.
   3. Choose your preferred connection style:
   * Desktop Sharing Tab: Turn on Desktop Sharing and toggle Remote Control on. This shares your existing active desktop.
      * Remote Login Tab: Click Unlock (requires admin password) and toggle Remote Login on. This allows you to log in remotely even if the physical machine is currently sitting on the lock screen or restarted.
   4. Set a custom Username and Password at the bottom of the window. (Note: For security, this RDP password can be totally different from your main Linux user login password). [4, 5, 6, 7, 8, 9] 

- Step 2: Open the Ubuntu Firewall [10] 
By default, Ubuntu's firewall may block incoming RDP traffic. Open your terminal and allow the standard RDP port (3389): [7, 11, 12, 13] 
```
sudo ufw allow 3389/tcp
```
- Step 3: Get your Ubuntu IP Address [14] 
You will need your workstation's IP address to connect. Find it by running: [5, 7, 15] 
```
ip a
```
Look for your local IP address (usually starts with 192.168.x.x or 10.x.x.x) under your active Wi-Fi or Ethernet interface. [16] 

- Step 4: Connect from Microsoft Remote Desktop [17] 
   1. Open the Microsoft Remote Desktop app (or the classic mstsc Remote Desktop Connection app) on your Windows, Mac, or iOS device.
   2. Type your Ubuntu workstation's IP address into the "PC Name" or "Computer" field and click Connect.
   3. When prompted for credentials, choose Use a different account and enter the Username and Password you created in Ubuntu's Remote Desktop settings.
   4. Accept any security certificate warnings to launch your remote session. [5, 9, 18, 19, 20] 

<details>
  <summary>Click to expand more info</summary>
  <p>Would you like help setting this up to work securely outside your home local network, or are you running into any credential connection errors?</p>

[1] [https://www.reddit.com](https://www.reddit.com/r/Proxmox/comments/1cd614v/psa_the_remote_access_feature_in_ubuntu_2404_is/)
[2] [https://linuxconfig.org](https://linuxconfig.org/ubuntu-20-04-remote-desktop-access-from-windows-10)
[3] [https://documentation.ubuntu.com](https://documentation.ubuntu.com/desktop/en/latest/how-to/share-your-desktop-remotely/)
[4] [https://www.youtube.com](https://www.youtube.com/watch?v=uXiecykVK6I)
[5] [https://www.youtube.com](https://www.youtube.com/watch?v=PBIk5TLSbm8)
[6] [https://askubuntu.com](https://askubuntu.com/questions/1513484/accessing-an-ubuntu-24-04-machine-via-rdp-port-selection)
[7] [https://linuxconfig.org](https://linuxconfig.org/ubuntu-20-04-remote-desktop-access-from-windows-10)
[8] [https://www.youtube.com](https://www.youtube.com/watch?v=-2CEfDiomq4&t=194)
[9] [https://documentation.ubuntu.com](https://documentation.ubuntu.com/desktop/en/latest/how-to/access-a-remote-desktop/)
[10] [https://www.reddit.com](https://www.reddit.com/r/rustdesk/comments/12zyss1/can_connect_to_windows_over_direct_ip_but_not/)
[11] [https://www.youtube.com](https://www.youtube.com/watch?v=-2CEfDiomq4&t=194)
[12] [https://vsys.host](https://vsys.host/how-to/how-to-access-ubuntu-via-remote-desktop-from-windows)
[13] [https://www.hostwinds.com](https://www.hostwinds.com/tutorials/windows-remote-desktop-connection-to-a-linux-server)
[14] [https://medium.com](https://medium.com/swe-insights/remote-login-to-ubuntu-from-windows-e768203b7545)
[15] [https://medium.com](https://medium.com/swe-insights/remote-login-to-ubuntu-from-windows-e768203b7545)
[16] [https://documentation.ubuntu.com](https://documentation.ubuntu.com/desktop/en/latest/how-to/access-a-remote-desktop/)
[17] [https://monovm.com](https://monovm.com/blog/rdp-ubuntu/)
[18] [https://www.dnsstuff.com](https://www.dnsstuff.com/how-to-access-linux-desktop-remotely)
[19] [https://www.digitalocean.com](https://www.digitalocean.com/community/tutorials/how-to-enable-remote-desktop-protocol-using-xrdp-on-ubuntu-22-04)
[20] [https://learn.microsoft.com](https://learn.microsoft.com/en-ie/answers/questions/2192429/remote-desktop-app-connects-but-not-remote-desktop)

</details>
</details>

<details>
  <summary>Fix MAC Address Collisions in Hyper-V to access Ubuntu</summary>
  <p>That 'almost' worked.  I think my issues is my ubuntu machine is running under Hyper-V, so I think the zerotier IP used on the ubuntu machine goes through hyper-v vswitch, then to host (which also has a zerotier).  Anyway when I used the zerotier IP on an external workstation (also with a zerotier IP), the Microsoft remote connection connected to a different Hyper-V vm on the same Hyper-V node as the ubuntu machine.  Can you help me figure out why?</p>

  <p>This routing confusion happens because Hyper-V dynamically generates MAC address pools for Virtual Machines, occasionally leading to a phenomenon known as MAC Address Mapping Confusion or ARP Bleeding across the virtual switch (vSwitch). [1]  When your external workstation attempts to reach the Ubuntu ZeroTier IP, the Hyper-V node's virtual switch intercepts the Layer 2 traffic. If the Virtual Switch is processing overlapping dynamic MAC addresses or caching wrong ARP tables, it will erroneously route port 3389 traffic straight to the other virtual machine instead of your Ubuntu target. [1, 2]  Follow these steps on your Hyper-V host and the Ubuntu VM to force proper separation and route the traffic correctly.</p>

- Step 1: Fix MAC Address Collisions in Hyper-V
Hyper-V hosts generate a restricted range of dynamic MAC addresses. If multiple VMs were created or imported around the same time, they might be clashing over the same virtual port profile. [1] 

   1. Open Hyper-V Manager on your host machine.
   2. Right-click your Ubuntu 24.04 VM and select Settings.
   3. Expand the Network Adapter dropdown menu and click on Advanced Features.
   4. Look under MAC address. If it is set to Dynamic, switch it to Static.
   5. Manually alter the very last block of the MAC address hex pairs to a completely unique number (e.g., change 00-15-5D-01-02-**AA** to 00-15-5D-01-02-**FF**).
   6. Click Apply. Repeat this verification for the other VM that you accidentally connected to, ensuring its static MAC address is entirely different. [1, 3, 4] 

- Step 2: Enable MAC Address Spoofing
Because ZeroTier operates by creating a virtual network tap (ztana, zt3g, etc.) inside your Ubuntu guest OS, the Hyper-V switch may drop or misroute its packets if it thinks the guest is emitting traffic from unapproved MAC addresses. [2] 

   1. In that same Advanced Features tab of your Ubuntu VM Network Adapter settings...
   2. Scroll down to the MAC address spoofing section.
   3. Check the box for Enable MAC address spoofing.
   4. Click OK and restart the Ubuntu VM.

- Step 3: Flush the Host and External Workstation ARP Caches
Your Windows host and your external workstation have likely cached the "wrong" combination of ZeroTier IP and MAC hardware addresses. You need to clear them out.

   1. On your External Workstation, open PowerShell or Command Prompt as an Administrator.
   2. Flush the network neighbor cache by running:
   ```
   arp -d *
   ```
   3. On your Hyper-V Host machine, open an Administrator PowerShell and clear its virtual switch tables by running:
   
   Clear-DnsClientCache
   Remove-NetNeighbor -AddressFamily IPv4
   
   [5] 

- Step 4: Verify the ZeroTier Identity (Crucial)
Double-check your [ZeroTier Central Console](https://www.zerotier.com/) to make absolutely sure you didn't accidentally clone a ZeroTier identity file when spinning up your VMs.

   1. Log into your ZeroTier dashboard.
   2. Look at the Node IDs (10-digit hexadecimal strings) for both virtual machines.
   3. If they share the exact same Node ID or are sharing an IP allocation rule, delete one of the nodes from the dashboard, open the terminal in Ubuntu, and clear the identity files so it generates a unique identity:
   ```
   sudo systemctl stop zerotier-one
   sudo rm /var/lib/zerotier-one/identity.secret /var/lib/zerotier-one/identity.public
   sudo systemctl start zerotier-one
   ```
   4. Re-authorize the new Node ID in your dashboard


<details>
  <summary>Reference Detail</summary>
  <p>Would you like to review your Hyper-V Virtual Switch Manager settings to see if it's built as an Internal or External switch, or should we verify the netplan routing configuration inside Ubuntu? [5, 6] 

[1] [https://murison.wordpress.com](https://murison.wordpress.com/2014/05/01/duplicate-mac-addresses-in-hyper-v/)
[2] [https://learn.microsoft.com](https://learn.microsoft.com/en-au/answers/questions/5793870/hyper-v-external-virtual-switch-managing-of-mac-ad)
[3] [https://community.spiceworks.com](https://community.spiceworks.com/t/hyper-v-duplicate-mac-issue/456987)
[4] [https://www.experts-exchange.com](https://www.experts-exchange.com/questions/27394718/Hyper-V-duplicates-host-mac-address.html)
[5] [https://www.reddit.com](https://www.reddit.com/r/HyperV/comments/1dpn5lm/ubuntu_server_2404_unable_to_connect_to_internet/)
[6] [https://learn.microsoft.com](https://learn.microsoft.com/en-us/answers/questions/4142238/hyper-v-vms-have-no-internet-connection-with-defau)

</details>
</details>
