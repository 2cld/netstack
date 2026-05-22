[edit](https://github.com/2cld/netstack/edit/master/docs/ops/tools/remote-desktop.md) or [./](./)

# Remote Desktop Access Pattern

Three methods for remote workstation access across the federation. Choose based on network path and client device.

## Methods

| Method | Protocol | Port | Best For | Client Platforms |
|--------|----------|:----:|----------|-----------------|
| Microsoft Remote Desktop (MRD) | RDP | 3389 | ZeroTier LAN, best performance | Windows, Mac, iOS, Android |
| RustDesk | Proprietary (relay) | 21118 | NAT traversal, no VPN needed | Windows, Mac, Linux, iOS, Android |
| Google Remote Desktop (GRD) | WebRTC | — | Browser-only, no install | Any browser (Chrome preferred) |

## When to Use What

| Scenario | Use |
|----------|-----|
| On ZeroTier network, need full desktop | **MRD** (fastest, best quality) |
| Off-network, no VPN, need quick access | **RustDesk** (punches through NAT) |
| On someone else's machine, can't install | **GRD** (browser only) |
| Clipboard/file transfer needed | **MRD** or **RustDesk** |
| Mobile device (phone/tablet) | **RustDesk** app or **MRD** app |

## Setup: Linux Host (Ubuntu 24.04+)

### GNOME Remote Desktop (for MRD clients)

GNOME Remote Desktop provides native RDP server on Ubuntu 22.04+.

```bash
# Install (usually pre-installed on Ubuntu Desktop)
sudo apt install gnome-remote-desktop

# Enable and configure (system-level for headless)
grdctl --system rdp enable
grdctl --system rdp set-port 3389
grdctl --system rdp disable-port-negotiation
grdctl --system rdp set-credentials <username> <password>
grdctl --system rdp disable-view-only

# Enable and start service
sudo systemctl enable gnome-remote-desktop
sudo systemctl restart gnome-remote-desktop

# Verify
grdctl --system status
ss -tlnp | grep 3389
```

**Troubleshooting:**
- If port shows 3390 instead of 3389: port negotiation bumped it. Run `grdctl --system rdp set-port 3389` + `grdctl --system rdp disable-port-negotiation` + restart service.
- If user-session instance conflicts: kill the user-session `gnome-remote-de` process (check `ss -tlnp`).
- TPM warning is cosmetic (falls back to GKeyFile) — ignore it.
- TLS cert auto-generated on first start.

### RustDesk

```bash
# Install (download .deb from rustdesk.com)
sudo dpkg -i rustdesk-<version>.deb

# Service runs automatically after install
systemctl status rustdesk

# Get device ID
rustdesk --get-id

# Set permanent password (optional, for unattended access)
rustdesk --password <password>
```

**Ports:** 21118 (TCP signaling), 21119 (TCP relay)

### Google Remote Desktop (Chrome Remote Desktop)

```bash
# Install Chrome Remote Desktop host
# Download from: https://remotedesktop.google.com/access
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
sudo dpkg -i chrome-remote-desktop_current_amd64.deb
sudo apt -f install

# Configure via browser at https://remotedesktop.google.com/access
# Requires Chrome browser + Google account sign-in on host
```

**Note:** Requires active Google account session. Best as backup method.

## Setup: Windows Host

### RDP (built-in)

```powershell
# Enable Remote Desktop (Settings > System > Remote Desktop > On)
# Or via PowerShell:
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Verify
Get-Service TermService | Select Status
netstat -an | findstr 3389
```

### RustDesk

Download from [rustdesk.com](https://rustdesk.com), install, note the ID.

### Google Remote Desktop

Install via [remotedesktop.google.com](https://remotedesktop.google.com/access) in Chrome browser.

## Connection Strings (via ZeroTier)

Format: `<zerotier-ip>:3389` for MRD, or RustDesk ID for RustDesk.

| Node | ZeroTier IP | MRD Address | RustDesk ID |
|------|:-----------:|-------------|:-----------:|
| (fill per node) | 10.147.17.x | 10.147.17.x:3389 | (from rustdesk --get-id) |

## Security Notes

- MRD over ZeroTier is encrypted end-to-end (ZT encryption + TLS)
- RustDesk uses end-to-end encryption (key exchange on connection)
- GRD uses Google's WebRTC encryption
- Never expose RDP (3389) to public internet without VPN
- ZeroTier network provides the access control layer
- Use strong passwords for RDP credentials

## Related

- [webproxy-ssh.md](./webproxy-ssh.md) — SSH tunnel for web services
- [../deployments/](../deployments/) — per-site node inventory
