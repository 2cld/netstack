
I've made a note that you're using an Alcatel IDOL 4S with Windows 10 Mobile. To launch a Remote Desktop session using Continuum, you must use the Universal Windows Platform (UWP) version of the client. Traditional Win32 programs will not open directly on the mobile OS interface, but the UWP app allows you to bridge into a full remote desktop environment on your external monitor. [1, 2, 3, 4] 
## 1. Download the Correct Client
The older, legacy built-in client does not support Continuum scaling. [1] 

* 
* Launch the Microsoft Store on your phone.
* Search for "Microsoft Remote Desktop" or "Remote Desktop Preview".
* Download and install the app, which is a fully compliant [Universal Windows App (UWP)](https://techcommunity.microsoft.com/blog/microsoft-security-blog/remote-desktop-preview-now-available-on-windows-10-mobile-and-continuum/249602). [4, 5, 6] 
* 

## 2. Launching in Continuum Mode

* 
* Ensure your Alcatel IDOL 4S is connected to your external monitor via your [wired dock or Miracast adapter](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/continuum-phone).
* Use your external mouse or your phone screen as a trackpad to click the Start button on the larger monitor's taskbar.
* Open the All Apps list.
* Select the Remote Desktop app you just downloaded. It will scale up seamlessly to fill the external display. [1, 2, 3, 4, 7, 8] 
* 

## 3. Establish the Remote Connection

* 
* Click the "+" (Add) button inside the application's connection center.
* Select PC.
* Enter the IP address or PC Name of the machine you want to access.
* Under User Account, enter the exact credentials for the host machine.
* Click Save and click the computer tile to initiate your session. [9, 10, 11, 12] 
* 

Note: Ensure that the host machine you are connecting to has [Remote Desktop enabled](https://support.microsoft.com/en-us/windows/experience/connectivity-networking/how-to-use-remote-desktop) in its system settings and is running a compatible version of Windows (such as Windows 10/11 Pro or Enterprise). [13, 14] 
Would you like help with configuring the host machine's firewall settings or setting up a static IP address to make connecting easier next time?

[1] [https://arstechnica.com](https://arstechnica.com/information-technology/2016/01/new-remote-desktop-client-could-almost-make-me-a-continuum-believer/)
[2] [https://www.youtube.com](https://www.youtube.com/watch?v=MebS5YbPJXY)
[3] [https://en.wikipedia.org](https://en.wikipedia.org/wiki/Windows_Continuum)
[4] [https://techcommunity.microsoft.com](https://techcommunity.microsoft.com/blog/microsoft-security-blog/remote-desktop-preview-now-available-on-windows-10-mobile-and-continuum/249602)
[5] [https://learn.microsoft.com](https://learn.microsoft.com/en-us/answers/questions/3288850/how-do-i-use-microsoft-remote-desktop-with-my-andr)
[6] [https://camerondwyer.com](https://camerondwyer.com/2015/12/01/windows-phone-10continuum-and-remote-desktop-combo-is-huge/)
[7] [https://learn.microsoft.com](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/continuum-phone)
[8] [https://www.youtube.com](https://www.youtube.com/watch?v=tmNQRw7OBTs&t=762)
[9] [https://www.youtube.com](https://www.youtube.com/watch?v=M7AN64i26os)
[10] [https://techbeatly.com](https://techbeatly.com/tutorial-how-to-connect-to-windows-remote-desktop-from-android/)
[11] [https://www.youtube.com](https://www.youtube.com/watch?v=YDTDt228Vis)
[12] [https://www.youtube.com](https://www.youtube.com/watch?v=WbgAuQl03Zk)

Since the native Microsoft Store client no longer operates on Windows 10 Mobile, you will need to sideload the .appxbundle file manually onto your Alcatel IDOL 4S. Because your phone uses an ARM-based processor, you must ensure you fetch a legacy version of the app package that still retains ARM32 architecture support. [1] 
## Step 1: Generate the Download Package Links
You will need a working PC to fetch the setup files safely.

   1. Open a web browser on your computer and navigate to the community-trusted deployment extraction tool: Adguard Store Link Generator.
   2. In the central text box, change the first dropdown from URL (link) to PackageFamilyName.
   3. Paste the following official Microsoft identity string into the box:
   Microsoft.RemoteDesktop_8wekyb3d8bbwe
   4. Change the rightmost dropdown selection from RP to Retail, then click the checkmark button. [2, 3] 

## Step 2: Download the Client and Dependencies
The page will populate a direct download list directly from Microsoft's delivery servers. Scroll to the bottom to look for the appropriate formats: [2] 

* 
* The Main App: Locate and click the file ending in .appxbundle. Look specifically for a version dating around 2020–2023 (such as versions starting with 10.2...) to ensure it still bundles the legacy Windows 10 Mobile ARM binary. [3, 4] 
* The Dependencies: You may also need to download the matching prerequisite files listed on the screen if your phone prompts you for them. Download the ARM architecture variants of:
* Microsoft.NET.Native.Framework
   * Microsoft.NET.Native.Runtime
   * Microsoft.VCLibs [5, 6] 
* 

Note: If your browser warns you that the files cannot be downloaded securely, right-click the link, choose "Save link as...", and opt to "Keep" or "Ignore warning" to download the raw Microsoft payload. [5] 
## Step 3: Enable Developer Sideloading on the IDOL 4S
Before the phone will execute an unverified installation package, you must toggle an internal deployment switch:

   1. On your Alcatel phone, go to Settings > Update & Security > For Developers.
   2. Toggle the selection radio button to Developer Mode (this authorizes your OS to parse local .appx files).

## Step 4: Transfer and Install

   1. Connect your IDOL 4S to your computer using a USB cable.
   2. Drag and drop the downloaded .appxbundle file (and dependencies, if downloaded) into your phone’s internal storage or SD card.
   3. Disconnect the USB cable, open the File Explorer app on your phone, and navigate to where you dropped the files.
   4. Tap the dependency files first to initialize them, and then tap your Remote Desktop .appxbundle file.
   5. Tap Install when prompted. The installation runs silently in the background and will take roughly 1–2 minutes to appear inside your normal "All Apps" app drawer list. [1, 5] 

Are you planning to run this over a local Wi-Fi network, or will you need guidance on configuring port forwarding (Port 3389) to access your machine from outside your home?

[1] [https://file.windowsviet.com](https://file.windowsviet.com/how-to-install-appx-appxbundle-windows-10-mobile/)
[2] [https://christitus.com](https://christitus.com/installing-appx-without-msstore/)
[3] [https://www.reddit.com](https://www.reddit.com/r/microsoft/comments/1117a2m/install_remote_desktop_app_alternatives_to_the_ms/)
[4] [https://www.appx4fun.com](https://www.appx4fun.com/xap/55493/)
[5] [https://superuser.com](https://superuser.com/questions/1721755/is-there-a-way-to-install-microsoft-store-exclusive-apps-without-store)
[6] [https://francydevicemanagement.wordpress.com](https://francydevicemanagement.wordpress.com/2021/08/19/steps-guide-to-install-microsoft-remote-desktop-windows-store-app-appxbundle-via-configmgr/)

[13] [https://support.microsoft.com](https://support.microsoft.com/en-us/windows/experience/connectivity-networking/how-to-use-remote-desktop)
[14] [https://www.youtube.com](https://www.youtube.com/watch?v=2gYvIBIaUFc)
