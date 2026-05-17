[edit](https://github.com/2cld/netstack/edit/master/docs/wan/zerotier/bridge.md)
# ZeroTier Bridge Configuration

How to bridge a ZeroTier overlay network with a local LAN segment, allowing non-ZeroTier devices to reach the overlay network through a bridge node.

## Concept

```
[LAN devices] ←→ [Bridge Node (ZT + LAN)] ←→ [ZeroTier Network] ←→ [Remote nodes]
```

A bridge node has both a LAN interface and a ZeroTier interface, and forwards traffic between them.

## Prerequisites

- ZeroTier installed on the bridge node
- Bridge node joined to the ZeroTier network
- ZeroTier Central: enable "Allow Ethernet Bridging" for the bridge node
- IP forwarding enabled on the bridge node

## Linux Bridge Setup (netplan)

```yaml
# /etc/netplan/01-bridge.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    ztXXXXXXXX:    # ZeroTier interface name
      dhcp4: false
  bridges:
    br0:
      dhcp4: false
      interfaces:
        - eth0
        - ztXXXXXXXX
```

Apply: `sudo netplan apply`

## Enable IP Forwarding

```bash
# Temporary
sudo sysctl -w net.ipv4.ip_forward=1

# Permanent
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## ZeroTier Central Configuration

1. Go to ZeroTier Central → Network → Members
2. Find the bridge node
3. Check "Allow Ethernet Bridging"
4. Add a managed route: `<LAN-subnet>/24 via <bridge-ZT-IP>`

## Verification

```bash
# Check bridge status
brctl show
ip addr show br0

# Check ZeroTier
zerotier-cli status
zerotier-cli listnetworks
zerotier-cli listpeers

# Test connectivity
ping <remote-ZT-IP>      # from bridge node
ping <LAN-device-IP>     # from remote ZT node (should route through bridge)
```

## Troubleshooting

- **No forwarding**: Check `sysctl net.ipv4.ip_forward` = 1
- **Firewall blocking**: `sudo ufw disable` for testing, then add proper rules
- **Bridge not working**: Verify both interfaces are in the bridge (`brctl show`)
- **ZeroTier not bridging**: Confirm "Allow Ethernet Bridging" is checked in Central
- **ARP issues**: Check ARP tables (`arp -n`) on both sides of the bridge
- **Route missing**: Verify managed route in ZeroTier Central points to bridge node

## Notes

- Detailed lab notes with specific IPs and configurations are in the private site repos
- Each site's bridge configuration is documented in its own `docs/network.md`
- See [ZeroTier documentation](https://docs.zerotier.com/bridging/) for official guide

## Related

- [ZeroTier README](./README.md) — general ZeroTier setup
- [Federation Node Topology](../../ops/deployments/federation-node-topology.md) — how nodes connect
