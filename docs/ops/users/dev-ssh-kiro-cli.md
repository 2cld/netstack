[edit](https://github.com/2cld/netstack/edit/master/docs/ops/users/dev-ssh-kiro-cli.md) or [./](./)

# SSH + Kiro CLI Workflow

Connect to a federation dev node via SSH and use Kiro CLI for AI-assisted development. No GUI needed — pure terminal, zero lag.

## Why

- RDP/VNC adds video encoding latency (especially over ZeroTier)
- SSH is text-only — instant response, works on any connection quality
- Kiro CLI provides the same AI assistant capabilities as the full IDE
- Works from any device with an SSH client (laptop, tablet, phone)

## Prerequisites

- ZeroTier installed and joined to federation network on your client device
- SSH client (built into Windows 10+, macOS, Linux)
- Target node has OpenSSH server + Kiro CLI installed

## Quick Connect

```bash
# Connect to nsdockerhv (primary dev node)
ssh nsadmin@10.147.17.176

# Start Kiro CLI chat (from the SSH session)
cd ~/code/wip
kiro-cli chat
```

## One-liner (direct to Kiro chat)

```bash
ssh nsadmin@10.147.17.176 -t "cd ~/code/wip && kiro-cli chat"
```

## Setup: SSH Key Auth (passwordless)

### From Windows (PowerShell)

```powershell
# Generate key (if you don't have one)
ssh-keygen -t ed25519

# Copy public key to target node
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh nsadmin@10.147.17.176 "cat >> ~/.ssh/authorized_keys"

# Test (should connect without password)
ssh nsadmin@10.147.17.176
```

### From WSL / Linux / macOS

```bash
# Generate key (if you don't have one)
ssh-keygen -t ed25519

# Copy public key to target node
ssh-copy-id nsadmin@10.147.17.176

# Test
ssh nsadmin@10.147.17.176
```

## Setup: Windows Terminal Profile (optional)

Add to Windows Terminal `settings.json` for one-click access:

```json
{
    "name": "Wip (nsdockerhv)",
    "commandline": "ssh nsadmin@10.147.17.176 -t \"cd ~/code/wip && kiro-cli chat\"",
    "icon": "🤖"
}
```

## Kiro CLI Commands

Once in `kiro-cli chat`:

| Command | What |
|---------|------|
| (just type) | Chat with Kiro (same as IDE chat) |
| `/quit` | Exit chat |
| `/clear` | Clear conversation |

Other kiro-cli subcommands:

```bash
kiro-cli chat          # Start chat session
kiro-cli agent         # Manage AI agents
kiro-cli doctor        # Debug installation issues
kiro-cli settings      # Customize behavior
```

## Federation Node SSH Addresses

| Node | ZeroTier IP | User | Purpose |
|------|:-----------:|------|---------|
| nsdockerhv | 10.147.17.176 | nsadmin | Primary dev (Wip, Docker, Gitea) |
| CyberTruck | 10.147.17.219 | ghadmin | Host (Hyper-V, Plex, backups) |
| cat9fin | 10.147.17.218 | nsadmin | HWPC production (hwpc-rp, QB) |
| slwin11ops | 10.147.17.94 | ghadmin | SL ops (backup target) |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Connection refused | Verify ZeroTier is connected: `zerotier-cli status` |
| Permission denied | Copy your SSH public key (see Setup above) |
| kiro-cli not found | Add to PATH: `export PATH="$HOME/.local/bin:$PATH"` |
| Session drops | Use `tmux` or `screen` for persistent sessions |

## Persistent Sessions with tmux

```bash
# Start a named session
ssh nsadmin@10.147.17.176 -t "tmux new-session -A -s wip"

# Inside tmux, start Kiro
cd ~/code/wip && kiro-cli chat

# Detach: Ctrl+B then D
# Reconnect later — session persists even if SSH drops
ssh nsadmin@10.147.17.176 -t "tmux attach -t wip"
```

## Related

- [remote-desktop.md](../tools/remote-desktop.md) — GUI remote access (when you need it)
- [../backup/windows-openssh-setup.md](../backup/windows-openssh-setup.md) — enabling SSH on Windows nodes
- [contributor-setup.md](../tools/contributor-setup.md) — full dev environment setup

## Mobile Access: Termius (iOS/Android)

[Termius](https://termius.com/) is an SSH client for mobile devices that supports:
- Saved host profiles (one-tap connect)
- Snippets (saved commands)
- SFTP file browsing
- **Siri Shortcuts integration** (voice-triggered SSH sessions)

### Setup

1. Install Termius from App Store / Play Store
2. Add host:
   - Label: `nsdockerhv (Wip)`
   - Hostname: `10.147.17.165` (requires ZeroTier on phone)
   - Port: 22
   - Username: `nsadmin`
   - Auth: SSH key (import or generate in Termius)
3. Save and test connection

### Siri Integration (iOS)

Termius supports Siri Shortcuts. You can create a shortcut that:
1. Opens Termius
2. Connects to nsdockerhv
3. Runs a command (e.g., starts tmux session)

**Setup:**
- Open iOS Shortcuts app
- Create new shortcut: "Hey Siri, open Wip"
- Action: Open Termius → Connect to saved host "nsdockerhv (Wip)"

**Voice paste pattern:**
- Dictate to Siri → text goes to clipboard
- Paste into Termius terminal (SSH session)
- This enables voice-to-terminal input from phone

### Alternative: SSH from iOS without Termius

iOS has no built-in SSH client, but options include:
- **Termius** (recommended — best UX, Siri support)
- **Blink Shell** (power user, mosh support)
- **a]Shell** (free, basic)

## tmux Best Practices for Wip Sessions

### Named Sessions

```bash
# Create/attach to named session
tmux new-session -A -s wip

# Multiple sessions for different contexts
tmux new-session -A -s wip      # Wip coordination
tmux new-session -A -s dev      # Development work
tmux new-session -A -s ops      # Ops/monitoring
```

### Useful tmux Commands

| Key | Action |
|-----|--------|
| `Ctrl+B d` | Detach (session keeps running) |
| `Ctrl+B c` | New window |
| `Ctrl+B n` | Next window |
| `Ctrl+B p` | Previous window |
| `Ctrl+B "` | Split horizontal |
| `Ctrl+B %` | Split vertical |
| `Ctrl+B [` | Scroll mode (q to exit) |

### Reconnect After Disconnect

```bash
# From any device (phone, laptop, tablet):
ssh nsadmin@10.147.17.176 -t "tmux attach -t wip"

# If session doesn't exist, create it:
ssh nsadmin@10.147.17.176 -t "tmux new-session -A -s wip"
```

### Why tmux + SSH > RDP

| | RDP | SSH + tmux |
|-|-----|-----------|
| Bandwidth | High (video stream) | Minimal (text only) |
| Latency feel | Laggy on slow links | Instant |
| Session persistence | Lost on disconnect | Survives disconnect |
| Mobile | Clunky (small screen + desktop UI) | Natural (terminal fits any screen) |
| Voice input | No | Yes (Siri → paste into terminal) |
| Multiple sessions | One desktop | Many tmux windows |
