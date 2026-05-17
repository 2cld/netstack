# CAVE Principles — Compute Archive Validation Environment

**Status:** Research / Design Pattern
**Applies to:** All federation nodes, dev environments, automation infrastructure

## Thesis

> Security complexity forces more losses than safety.

Modern compute environments are fragile because they depend on layers you don't control. Any upstream update (OS, runtime, IDE, tool) can break a working workflow with zero notice.

## The 5 Principles

### 1. Immutability
The environment doesn't change unless you explicitly allow it. No auto-updates, no background patches. Like a container image with a pinned tag.

### 2. Minimal Surface
Only what's needed to run the workflow. No bloated OS services, no package managers pulling transitive deps. Reduce the number of things that CAN break.

### 3. Validation Gate
Changes go through a staging environment first. Test workflows against the new version BEFORE it touches production. Update is a conscious decision, not something that happens to you.

### 4. Reproducibility
If the environment breaks, you can rebuild it from a spec. Something declarative — Nix flakes, Docker images, VM snapshots, Ansible playbooks.

### 5. Separation of Concerns
The CAVE runs your tools. The IDE/editor is a CLIENT that connects TO the CAVE, not the other way around. If the IDE updates its sandbox rules, your CAVE doesn't care.

## Architecture Options

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| Container-based | Docker/Podman with pinned base image | Lightweight, reproducible | Limited to Linux userspace |
| VM snapshot | Proxmox/Hyper-V with known-good state | Full isolation | Heavier, slower to start |
| Nix-based | Nix flake defines entire environment | Most reproducible | Steep learning curve |
| Bare-metal node | Dedicated machine, manual patching | Simple, full control | Single point of failure |

## Connection to Federation

A CAVE could be a node type in the federation topology:
- **LAN node** — routing, DNS, VPN
- **Storage node** — NAS, backup, media
- **Compute node** — VMs, containers, services
- **Dev/CAVE node** — frozen dev environment, workflow execution

## Real-World Examples

- IDE update broke workspace sandbox → dev scripts stopped working
- TrueNAS Core → Scale upgrade broke backup restoration
- Node.js version bump broke module resolution
- OS update changed permissions on service directories

In each case: the "safety" layer (updates, security patches, version management) created more operational risk than the threat it was protecting against.

## When to Apply CAVE Thinking

- Production services that must not break (hwpc-rp, Route Print)
- Automation scripts that other processes depend on (morning check-in, backups)
- Development environments where reproducibility matters
- Any system where "it was working yesterday" is a common complaint

## When NOT to Apply

- Exploratory development (you want the latest tools)
- Public-facing services that need security patches (web servers)
- Environments where compliance requires current patches

The answer is usually: CAVE for your workflow tools, standard patching for your public-facing services.

## Related
- [Federation Backup Plan](../backup/federation-backup-plan.md) — data protection across nodes
- [Sensitive Data Pattern](../security/sensitive-data-pattern.md) — protecting configs and credentials
- [Storage Indexing](../storage-index/) — knowing what you have before changing it
