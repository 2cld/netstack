# Repo Lifecycle Management

**Applies to:** All repos in the 2cld federation

## Principle

Repos should be intentionally created, actively maintained, or explicitly archived. Prevent "repo sprawl" — abandoned repos with no clear status.

## Lifecycle States

```
Active → Merge Candidate → Archived
```

| State | Meaning | Indicators |
|-------|---------|------------|
| **Active** | Being worked on, has open issues or recent commits | Commits in last 90 days |
| **Merge Candidate** | Could be absorbed into another repo | No unique purpose, overlaps with another |
| **Archived** | Read-only, preserved for history | No commits needed, repo archived in settings |

## Creating a New Repo

Before creating a repo, ask:
1. Does this work belong in an existing repo?
2. Is this a new project or a sub-component?
3. Who will maintain it?
4. What's the Definition of Done for this repo's purpose?

### Setup checklist:
- [ ] Create on GitHub or Gitea
- [ ] Add README with purpose statement
- [ ] Add .gitignore (use standard pattern from [sensitive-data-pattern](../security/sensitive-data-pattern.md))
- [ ] Add docs/ structure (follow [site template](../deployments/site-template/))
- [ ] Add to coordination repo's inventory (repo map)
- [ ] Create initial issue(s) defining scope

## Flagging for Merge/Archive

1. Create an issue on the repo: "Consider merge into [target-repo] and archive"
2. Describe what the repo does and why it could merge
3. Tag with `lifecycle` or `cleanup`
4. Review during weekly review

## Stale Detection

During weekly review or via status scripts:
- **No commits in 90+ days** → flag for review
- **No open issues** → is this done or abandoned?
- **Overlaps with another repo** → merge candidate

Decision: keep active, merge, or archive.

## Merging

1. Move relevant code/docs into the target repo
2. Create a final commit noting the merge source
3. Update any references in coordination docs
4. Archive the source repo

## Archiving

1. In GitHub/Gitea repo settings → Archive repository
2. Repo becomes read-only, stays accessible for history
3. Remove from active inventory
4. Note in coordination docs: "archived [date], merged into [target]"

## Related
- [Contributor Setup](../tools/contributor-setup.md) — how to work with repos
- [Federation Node Topology](../deployments/federation-node-topology.md) — repo-per-site pattern
- [Session Logging](../tools/session-logging.md) — documenting lifecycle decisions
