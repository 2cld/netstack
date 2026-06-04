# Docker Service Pattern

**Applies to:** Any containerized service running at a federation site.

## Principle

A Docker service must be reproducible from its compose file + config alone. No manual steps hidden in VMs, no notes only in someone's head. If the host dies, `docker compose up` on a new host rebuilds the service.

## Anti-Pattern

```
VM with Docker installed
  └── manually configured services
  └── notes inside the VM (in /root/README or description field)
  └── "it works, don't touch it"
```

**Why this fails:** VM dies, notes are lost, no one knows how to rebuild.

## Correct Pattern

```
<site-compose-repo>/
├── <service-name>/
│   ├── docker-compose.yml    # Service definition (git tracked)
│   ├── .env                  # Secrets (gitignored, backed up per repo-private-data)
│   ├── config/               # Mounted configs (git tracked where possible)
│   └── README.md             # Setup notes, decisions, troubleshooting
```

**Everything needed to rebuild lives in the repo.** The VM/host is disposable.

## Service Definition (docker-compose.yml)

```yaml
# <service-name>/docker-compose.yml
version: "3"
services:
  <service>:
    image: <image>:<pinned-version>
    container_name: <service-name>
    restart: unless-stopped
    ports:
      - "<host-port>:<container-port>"
    volumes:
      - ./config:/config        # config files (git tracked)
      - <named-volume>:/data    # persistent data (backed up)
    env_file:
      - .env                    # secrets (not in git)
    networks:
      - <network-name>

volumes:
  <named-volume>:

networks:
  <network-name>:
    external: true
```

## Key Rules

1. **Pin image versions** - `image: plex:1.32.5` not `image: plex:latest`
2. **Secrets in .env only** - never in compose file or git
3. **Config in git** - mount config files from repo, not from random host paths
4. **Data volumes named** - easy to backup, easy to migrate
5. **README.md per service** - what it does, how to access, dependencies, troubleshooting
6. **No manual steps** - if you had to run something by hand, document it in README as a script

## Per-Site Compose Repo

Each site has a compose repo:

| Site | Repo | Host |
|------|------|------|
| cf | [docker-compose gitea](https://gitea.cat9.me/nsadmin/docker-compose) | nsdockerhv |
| wf | TBD (create when deploying services on cg2) | cg2 or VM on cg2 |
| sl | TBD | slwin11ops (if needed) |

## Rebuild Procedure

If the host dies:
1. Stand up new host per [ops-node-setup](../../ops/users/ops-node-setup.md)
2. Install Docker: `curl -fsSL https://get.docker.com | sh`
3. Clone the compose repo: `git clone <repo>`
4. Restore .env files from private backup (per [repo-private-data](../../ops/tools/repo-private-data.md))
5. Restore data volumes from backup (per [ssh-rsync-pattern](../../ops/backup/ssh-rsync-pattern.md))
6. `cd <service> && docker compose up -d`
7. Verify service is running

**If you can't do step 6 and have it work, your compose repo is incomplete.**

## Migration (VM notes -> compose repo)

When you find a VM with manually configured Docker services:

1. SSH into the VM
2. List running containers: `docker ps`
3. For each container:
   - `docker inspect <container>` - extract volumes, ports, env
   - Find the compose file (if one exists): `find / -name "docker-compose.yml" 2>/dev/null`
   - Find any notes: check VM description, /root/, home dirs
4. Create the proper structure in the compose repo
5. Test: `docker compose down && docker compose up -d` (does it come back clean?)
6. Move notes from VM into the service README.md
7. VM description becomes: "Services defined in <repo>. See README per service."

## Monitoring Integration

Add to site status script:
```bash
# Check Docker services are running
docker ps --format "{{.Names}} {{.Status}}" | grep -v "Up" && echo "CONTAINER DOWN" || echo "All containers UP"
```

## Related

- [ops-node-setup](../../ops/users/ops-node-setup.md) - host environment
- [docker-workflow](./docker-workflow.md) - cf-specific portal setup (legacy)
- [repo-private-data](../../ops/tools/repo-private-data.md) - .env backup
- [ssh-rsync-pattern](../../ops/backup/ssh-rsync-pattern.md) - volume backup
- [service-lifecycle-pattern](../../ops/tools/service-lifecycle-pattern.md) - migration gates
- [backup-cron-pattern](../../ops/backup/backup-cron-pattern.md) - automated backups of volumes
