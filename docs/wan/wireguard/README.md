[edit](https://github.com/2cld/netstack/edit/master/docs/wan/wireguard/README.md)

# WireGuard - Federation VPN

WireGuard provides site-to-site VPN connectivity between netstack federation nodes. This enables:
- Access to remote gitea instances (e.g., gitea.trink.com from nsdockerhv)
- Backup replication between sites
- Service federation across cf/wf/sl nodes
- Shared identity and access management

## Federation Topology

```
cf.2cld.net (Cedar Falls)  ←──WireGuard──→  trink (Trink's node)
     ↕                                           ↕
wf.2cld.net (Winfield)    ←──WireGuard──→  sl.2cld.net (O'Fallon)
```

## Use Case: nsdockerhv → gitea.trink.com

**Goal:** Wip (running on nsdockerhv at cf) needs to reach https://gitea.trink.com/trink/stack to pull Trink's federation commits.

**Prerequisite:** Trink provides:
- WireGuard public key for his endpoint
- Endpoint IP:port (his WireGuard listener)
- Allowed IPs (his internal subnet)
- gitea.trink.com internal IP

### Configuration (nsdockerhv - cf node)

```ini
# /etc/wireguard/wg-trink.conf

[Interface]
# nsdockerhv's WireGuard identity
PrivateKey = <nsdockerhv-private-key>
Address = 10.100.0.1/24
# ListenPort = 51820  # optional if only initiating

[Peer]
# Trink's endpoint
PublicKey = <trink-public-key>
Endpoint = <trink-public-ip>:51820
AllowedIPs = 10.100.0.2/32, <trink-internal-subnet>
PersistentKeepalive = 25
```

### Configuration (Trink's node)

```ini
# /etc/wireguard/wg-cat.conf

[Interface]
PrivateKey = <trink-private-key>
Address = 10.100.0.2/24
ListenPort = 51820

[Peer]
# nsdockerhv (cf)
PublicKey = <nsdockerhv-public-key>
Endpoint = 192.111.21.62:51820
AllowedIPs = 10.100.0.1/32, 192.168.6.0/24
PersistentKeepalive = 25
```

## Setup Steps

### 1. Generate keys (on each node)

```bash
wg genkey | tee privatekey | wg pubkey > publickey
```

### 2. Exchange public keys + endpoint info
- Share public keys between nodes (never share private keys)
- Confirm endpoint IPs and ports
- Agree on tunnel subnet (suggest: 10.100.0.0/24 for federation)

### 3. Configure and start

```bash
# Install wireguard (Ubuntu/Debian)
sudo apt install wireguard

# Place config
sudo cp wg-trink.conf /etc/wireguard/

# Start tunnel
sudo wg-quick up wg-trink

# Verify
sudo wg show

# Enable on boot
sudo systemctl enable wg-quick@wg-trink
```

### 4. Verify connectivity

```bash
# Ping Trink's WireGuard IP
ping 10.100.0.2

# Test gitea access
curl -s https://gitea.trink.com/trink/stack | head -20

# Or if gitea is on internal IP behind the tunnel:
curl -s http://10.100.0.2:3000/trink/stack
```

### 5. DNS (optional)

Add to `/etc/hosts` or local DNS:
```
10.100.0.2  gitea.trink.com
```

## Federation VPN Subnet Plan

| Node | WireGuard IP | Location | Public Endpoint |
|------|-------------|----------|-----------------|
| nsdockerhv (cf) | 10.100.0.1 | Cedar Falls | 192.111.21.62:51820 |
| trink | 10.100.0.2 | Trink's site | TBD |
| wf | 10.100.0.3 | Winfield | TBD |
| sl | 10.100.0.4 | O'Fallon | 24.216.208.251:51820 |

## Security Notes

- WireGuard keys are per-node, not per-user
- Rotate keys if a node is compromised
- Use `AllowedIPs` to restrict what traffic flows through the tunnel
- PersistentKeepalive keeps NAT mappings alive for nodes behind NAT
- Consider firewall rules to limit WireGuard port exposure

## Troubleshooting

```bash
# Check tunnel status
sudo wg show

# Check if interface is up
ip addr show wg-trink

# Check routing
ip route | grep 10.100

# Debug handshake issues (usually key mismatch or endpoint unreachable)
sudo journalctl -u wg-quick@wg-trink

# Restart tunnel
sudo wg-quick down wg-trink && sudo wg-quick up wg-trink
```

## Related

- [netstack#3 Federation deployment](https://github.com/2cld/netstack/issues/3)
- [Trink's stack repo](https://gitea.trink.com/trink/stack) (requires this VPN)
- [docs/lan/README.md](../docs/lan/README.md) - LAN overview + site subnets
- [docs/wan/openvpn/](../openvpn/) - legacy OpenVPN configs
- [WireGuard official docs](https://www.wireguard.com/install/)
