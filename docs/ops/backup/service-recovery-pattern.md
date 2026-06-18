# Service Recovery Pattern

**Applies to:** Any federation service that needs to be rebuilt after failure.

## Principle

Every service must be recoverable from: **backup data + repo config + documented steps.** If you can't recover a service by following a doc, the service isn't properly documented.

## Recovery Requirements

Every service needs these three things documented:

```
1. DATA    - what to restore (database, files, secrets)
2. CONFIG  - how to rebuild the environment (repo, compose, scripts)
3. STEPS   - ordered procedure to go from nothing to running
```

## Recovery Document Template

Each service's repo (or site docs) should have a recovery section:

```markdown
## Recovery: <service-name>

### What You Need
- [ ] Backup data from: <location> (describe what files/DB)
- [ ] Repo access: <repo URL> (code + config)
- [ ] Secrets: <where .env/tokens live> (vault, private backup)
- [ ] Host: <what to run it on> (specs, OS, network requirements)

### Backup Locations
| Data | Primary backup | Secondary backup |
|------|---------------|-----------------|
| <database> | <location> | <location> |
| <files> | <location> | <location> |
| <secrets> | <location> | <location> |

### Recovery Steps
1. Stand up host per [ops-node-setup](https://netstack.org/docs/ops/users/ops-node-setup/)
2. Clone repo: `git clone <repo>`
3. Restore secrets (.env) from <vault/backup location>
4. Restore data from backup: <specific commands>
5. Start service: <specific commands>
6. Verify: <how to confirm it's working>
7. Update DNS/access if host IP changed

### Recovery Time Estimate
- Host setup: X hours
- Data restore: X hours (depends on backup size + transfer speed)
- Verification: X minutes
- Total: X hours

### Last Tested
- Date: <when was this procedure last verified>
- Result: <pass/fail + notes>
```

## Site-Level Recovery

For full site recovery (everything at a site is gone):

1. Follow [federation-setup-guide](../deployments/federation-setup-guide.md) for infrastructure
2. Recover each service per its recovery doc
3. Verify monitoring comes back green
4. Update federation status

## Integration with Other Patterns

| Pattern | Role in recovery |
|---------|-----------------|
| [federation-setup-guide](../deployments/federation-setup-guide.md) | Node/OS standup |
| [ops-node-setup](../users/ops-node-setup.md) | User environment |
| [docker-service-pattern](../../lan/compute/docker/docker-service-pattern.md) | Container rebuild |
| [ssh-rsync-pattern](../backup/ssh-rsync-pattern.md) | How backup data transfers |
| [federation-backup-plan](../backup/federation-backup-plan.md) | Where backups live |
| [service-lifecycle-pattern](../tools/service-lifecycle-pattern.md) | Migration gates |
| Site `site-config.yml` | Service definitions + dependencies |

## Verification (DR Test)

Per the recovery template, every service should have "Last Tested" documented. Schedule DR tests periodically:

- **Critical services:** test recovery annually minimum
- **After major changes:** test recovery after any architecture change
- **New services:** test recovery before declaring "production ready"

A service without a tested recovery procedure is a **risk, not an asset.**

## Related

- [federation-backup-plan](../backup/federation-backup-plan.md) - where data lives
- [docker-service-pattern](../../lan/compute/docker/docker-service-pattern.md) - container rebuild
- [service-lifecycle-pattern](../tools/service-lifecycle-pattern.md) - migration gates
- [ops-node-setup](../users/ops-node-setup.md) - host environment
