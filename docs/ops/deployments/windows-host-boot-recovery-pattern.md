# Pattern: Windows host comes back by itself after a power loss

**Applies to:** a site whose only machine is a Windows host running the [WSL Docker stack](./compute-wsl-docker-pattern.md) and Windows-native add-ons such as Plex.
**Origin:** sl, 2026-11-26 (sl#31). Three unclean power losses in one night, then a reboot test with nobody connecting.

## Goal

After a power loss, with nobody on site and nobody logged in, the site returns to healthy on its own. "Healthy" means the public `status.json` has a timestamp newer than the boot and every check is ok. Target: **5 minutes from boot**. sl measured 3 min 44 s.

## The chain

Each link has one mechanism and one way to see that it worked. A site is only as good as its weakest link, so test the whole chain, not one link.

| # | Link | Mechanism | How to see it worked |
|---|------|-----------|----------------------|
| 1 | Machine powers on | BIOS/UEFI "AC power recovery" set to power on (or last state). Set once, on site. | Event log: `Kernel-Power 41` and `EventLog 6008` (unclean shutdown) followed by a boot (`Kernel-General 12`). The gap is the outage. sl came back 3 of 3 times on 2026-11-26. |
| 2 | Network and overlay | Windows services set to Automatic (ZeroTier). Router and modem recover first. | Node answers ping over the overlay. |
| 3 | WSL and Docker | Scheduled task at startup (1 minute delay) as the **distro owner** with a stored password and highest run level, running `wsl.exe -d <distro> --exec /usr/bin/sleep infinity`. Containers use `restart: unless-stopped`. | `wsl -l -v` shows Running; `docker ps` shows the core containers with a start time from boot. |
| 4 | A signed-in session | Windows auto sign-in for the same user (Sysinternals Autologon: password kept as an LSA secret, not in plain text). Needed only when an add-on starts at logon. | `AutoAdminLogon` is 1 and `DefaultPassword` is absent; a type 2 logon event appears with no RDP session. |
| 5 | Add-ons | Plex starts from its `Run` registry key at that logon. | Plex `/identity` returns 200. |
| 6 | Public proof | The status checker writes `status.json` through the tunnel. | Timestamp newer than boot, tunnel check ok, all checks ok. |

Notes on the links:
- **Link 3: not SYSTEM.** WSL distros belong to a Windows user. A task running as SYSTEM may not see the distro. The user needs the "Log on as a batch job" right. Changing the user's password breaks the stored credential; redo the task.
- **Link 3: why `sleep infinity`.** A WSL distro stops when no `wsl.exe` process is attached. The task keeps one attached.
- **Link 4 is a trade.** The console stays signed in with the password stored on the machine. Accept it when physical access is limited and the account already has admin and RDP. Skip the link when no add-on needs a session.
- **Order seen at sl:** traefik 3 minutes after boot, cloudflared a little later. The first boot of the day took about 6 minutes; the controlled test took 3 min 44 s. Budget for the slower one.

## Testing it

Do this once per site, and again after major Windows or WSL updates. Tell the household first: the backup receiver, tunnel and Plex are off for about 5 minutes.

1. From **another machine**, over SSH ([windows-openssh-setup](../backup/windows-openssh-setup.md)), record `date` and run `shutdown /r /t 20`.
2. Do not connect to the host. Poll every 10 to 15 seconds: ping, the public `status.json` HTTP code, and Plex `/identity` through SSH.
3. When `status.json` is 200, check it: timestamp newer than boot, all checks ok.
4. Prove nobody logged in: `query user` shows only `console`, and the logon events show type 2 (console) and no type 10 (RDP) in the window.
5. Record the table (reboot, boot, sign-in, add-on up, status ok) on the site's issue and in the site's BMR doc.

A tested sl run:

| Time | Event |
|------|-------|
| 11:17:03 | Reboot command |
| 11:18:12 | Windows boot |
| 11:19:09 | Console sign-in by Autologon, no RDP session |
| 11:21:09 | Plex process started |
| 11:21:44 | Plex answered |
| 11:21:56 | `status.json` ok, 11 of 11 checks ok (3 min 44 s from boot) |

## What an unclean power loss breaks

The chain brings the machine back. It does not bring back work that was cut off.
- **Jobs in flight.** On 2026-11-26 the sl host lost power at 02:28, shortly after the 02:00 Docker backups from cf had landed. cf's `hwpc-rp` sync to sl did not land that day (newest file from the day before). The power loss is the likely cause; it was not confirmed from cf's log. The failure was noticed because Wip's contract runner flagged `hwpc-rp-sl not OK` the next morning.
- **Rule.** A sender that cannot reach or finish at the receiver must record the failure and retry the same day, and the receiver's own file times must show what arrived ([service-backup-receiver-pattern](../backup/service-backup-receiver-pattern.md)). Do not rely on a morning flag. This pattern does not build that retry; it is open (below).
- **File system.** NTFS and the WSL disk image recovered cleanly three times at sl. A host with an important WSL data volume should still plan for repair after repeated unclean stops.
- **Power quality.** sl sits on a generator (sl#1 was closed for that), and glitches still reached only this site. A generator transfer can interrupt power for seconds. A small UPS to ride through the transfer is a separate decision; this pattern assumes the loss will happen and makes recovery automatic.

## Monitoring this

- The public `status.json` timestamp and `known_down` rules from [site-status-service-pattern](../monitor/site-status-service-pattern.md) already show a site that has not recovered. After the sl change, an unattended reboot that leaves the tunnel down raises a CRITICAL in Wip.
- Disk health and free space belong in the same file (sl#23) so a power event that damages a disk shows up.
- Not built: a check that counts unexpected shutdowns (`Kernel-Power 41`) per week and puts the number in `status.json`. A site with a rising count has a power problem.

## Open items

- A sender-side retry for interrupted backups (same day), and a way for the receiver to ask for a re-send. Related: [netstack#43](https://github.com/2cld/netstack/issues/43), [netstack#45](https://github.com/2cld/netstack/issues/45).
- Unexpected-shutdown counter in `status.json`.
- Whether to lock the console after auto sign-in (keeps the session and Plex running, adds a lock screen).
- The cause of the sl 2026-11-25 boot-task failure was never captured. If it returns, capture the Task Scheduler history first (`wevtutil sl Microsoft-Windows-TaskScheduler/Operational /e:true`).

## Related

- [compute-wsl-docker-pattern](./compute-wsl-docker-pattern.md): the stack this recovers; Section 4 step 7 and Section 6
- [windows-openssh-setup](../backup/windows-openssh-setup.md): managing the host over SSH, copied `.ps1` files
- [bmr-pattern](./bmr-pattern.md): rebuild from nothing; this pattern covers restart from power loss
- sl runbook: `ops/compute/slwin11ops-bmr.md` sections 4a, 4b (2cld/sl)
- netstack#32: boot-task item in the BMR test-flight list
