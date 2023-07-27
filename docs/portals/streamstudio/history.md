from https://github.com/christrees/blog/blob/master/wip/streamstudio.md copied on 2023.07.27


## Review notes
- [epoccam - cellphone web cam](https://www.elgato.com/us/en/s/epoccam)
### Checklist
#### take from cf macci setup
- macci, ac cord, 
- usb kbrd/ms, hdmi cable, machd-vga
- USB dongle with 4 cameras
- 3 other USB cameras
- Black power brick with USB
- USB trip apple charge cable
- 2x USB trip apple, micro, type C charge cable
- 2x iPhone8
- 1x iPhone11
#### take from cf catmini setup
- cat's mac mini, ac cord,
- mac bt keyboard
- mac bt mousepad
- HDMI cable
- Logitech USB speaker/mouse
- usb kbrd/ms, hdmi cable, machd-vga
#### take from cf various
- ethernet case
- portal 8"
- portal TV
- fireTV cube
- HDMI cables
- Windows Surface, ps, dock, docps

# Streaming Studio Setup

## macmini setup
- Last version that supports 10.15.6 Catalina on catmini [download/29.0.2/obs-studio-29.0.2-macos-x86_64.dmg](https://github.com/obsproject/obs-studio/releases/download/29.0.2/obs-studio-29.0.2-macos-x86_64.dmg)
- droid cam app
- [https://www.youtube.com/watch?v=rZ8dd-gq5t4](https://www.youtube.com/watch?v=rZ8dd-gq5t4)
- tbd

## macci setup
- Last version that supports 10.13.6 High Sierra on macci [download/27.2.4/obs-mac-27.2.4.dmg](https://github.com/obsproject/obs-studio/releases/download/27.2.4/obs-mac-27.2.4.dmg)
- droid cam app for obs 27.2 is [DroidCamOBS_1.5.0.pkg](https://github.com/dev47apps/droidcam-obs-plugin/releases/download/1.5.0/DroidCamOBS_1.5.0.pkg) but does not work so well
- DroidApp [remove OBS packages on mac](https://www.dev47apps.com/obs/#:~:text=Use%20Programs%20and%20Features%20in,remove%20the%20DroidCam%20OBS%20plugin.&text=Remove%20'droidcam%2Dobs'%20from,obs%2Dstudio%2Fplugins%2F'.&text=follow%20the%20prompts%20(enter%20%22y,forget%20com.dev47apps.obsdroidcam%20.)
- setup with old usb cheap cameras
- click stream and test
- [https://www.youtube.com/watch?v=rZ8dd-gq5t4](https://www.youtube.com/watch?v=rZ8dd-gq5t4)
- tbd

## Record 
- [Record HDCP Protected](https://www.youtube.com/watch?v=6Kv-8xbiIQU)
- [HDMI Spliter removes HDCP protection](https://www.amazon.com/gp/product/B081RDP2JX/ref=as_li_qf_asin_il_tl?ie=UTF8)
- [HDMI Splter alternate](https://www.amazon.com/Splitter-Amplifier-1080P-Blu-Ray-Player/dp/B082CXZP71/ref=dp_prsubs_2?pd_rd_i=B082CXZP71&psc=1)
- [HDMI Recorder](https://www.amazon.com/dp/B091NX24PC/ref=sspa_dk_detail_2)

## Quickstart [Video Stream Studio Quickstart](https://youtu.be/W2Po0jeB0mU)
1. Start OBS
2. Verify Local Sources
    - IntroScene (blogchrisreesintro.mp4)
    - catminiWebCam (local webcam)
    - catminiOBSScreen  (obs screen for videos... not really needed)
    - catminiShowScreen (main show screen for videos)
    - ComputerAudio (the iShowU Audio capture of midi streaming on computer output)
    - CatSurfaceRemote connect to catsurface via remotedesktop.google.com then bind to that window
3. Test
    1. Click on Intro Scene
    2. Start Recording
    3. Click on TalkingHead and talk
    4. Click on SceneWork to talk and show
    5. Click on CatSurfaceRemote to verify you can annotate using surface
    6. End Record
    7. Verify stream rename if good
4. Upload Stream 
    1. Go to [https://studio.youtube.com/](https://studio.youtube.com/) and upload
    
## Install (catmini) [Video Stream Studio Setup](https://youtu.be/XpUJWuSWywg)
1. Install [OBS](https://obsproject.com/) on catmini catalina
2. Install [iShowU Audio](https://support.shinywhitebox.com/hc/en-us/articles/360030800592)
3. Reboot
4. Audio Midi Setup [TC 1:42](https://youtu.be/1-tnEfV2I_M?t=102)
  - Search for Audio Midi Setup
  - Add multi-output device to capture Computer and Mic
  - Select the Output (Yeti) and iShow Audio Capture
  - Rename to "Streaming"
5. Sytem Preference Sound [TC 3:11](https://youtu.be/1-tnEfV2I_M?t=191)
  - Set Audio Output to "Streaming"
6. OBS Setup Audio
  - Gear -> Device -> Yeti Stereo Microphone
  - Gear -> Advanced Audio -> Click Mono
  - Rename Audio source to "Yeti"
7. OBS Display Capture
  - Sources Add -> Display Capture -> catminiLeftScreen
  - Sources Add -> Display Capture -> catminiRightScreen
8. OBS Computer Audio Capture
  - Sources -> + -> Audio Output -> Create New "ComputerAudio"
  - Device -> iShowU Audio Capture
9. OBS 
  - Sources -> + -> Video Capture Deive -> Create New "catminiWebCam"
  - Device -> USB2.0 UVC PC Camera
10. Setup Scenes
  - Streaming (Screen, WebCam, Mic, Streaming)
  - Talking Head (WebCam, Mic)

## Remote
When streaming it's better to setup a remote workstation and remote in and show that screen in OBS.  Google remote desktop has been the most reliable, but if you can get microsoft remote desktop to connect it has better screen and device managemenet.

- [https://remotedesktop.google.com/](https://remotedesktop.google.com/)
- [Microsoft Remote Desktop - Microsoft Store](https://www.microsoft.com/en-us/p/microsoft-remote-desktop/9wzdncrfj3ps?activetab=pivot:overviewtab)
- [Microsoft Remote Desktop - Apple Store](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12)
- Remote Workstations using [https://my.zerotier.com/](https://my.zerotier.com/)

### Reference
- [OBS](https://obsproject.com/)
- [iShowU Audio Capture](https://support.shinywhitebox.com/hc/en-us/articles/360030800592)
- [P1xelPerfect - OBS tips and tricks](https://www.youtube.com/c/P1xelPerfect/videos)
- [Mac OBS Setup for streaming with computer audio 2020](https://www.youtube.com/watch?v=1-tnEfV2I_M)
- [canva.com - IntroScreenCreation](https://www.canva.com/)
