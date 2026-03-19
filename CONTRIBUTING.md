# Contributing to netstack.org

Thanks for your interest in improving netstack.org documentation. This project documents home lab and small network patterns using the ng/sg/cg architecture. Contributions from real-world deployments make the docs better for everyone.

## Ways to Contribute

### 1. Quick Fixes (typos, broken links, small edits)

Use the `[edit]` links at the top of any doc page. These link directly to the GitHub editor. Make your change and submit a PR.

### 2. GitHub Issues (questions, bugs, feature requests)

Open an issue at [github.com/2cld/netstack/issues](https://github.com/2cld/netstack/issues) for:
- Questions about the ng/sg/cg pattern
- Missing documentation you need
- Errors or outdated information
- Feature requests for new sections

Structure your issue clearly so both humans and AI assistants can parse it:

```markdown
## Context
What part of the docs this relates to (include links)

## Current Behavior
What exists now (or what's missing)

## Suggested Change
Your proposal

## Impact
What sites or deployments this affects
```

### 3. Issue → Branch → Feedback Doc → PR (the full lifecycle)

This is our preferred workflow for substantial contributions. It ties GitHub's issue tracking to a working branch where humans and AI assistants can collaborate on structured markdown before merging to main.

#### The Process

```
GitHub Issue (discovery & discussion)
    │
    ▼
Working Branch (collaboration space)
    │
    ├── Feedback doc (context & reasoning)
    ├── .md notes from contributors
    └── Actual doc changes
    │
    ▼
Pull Request (review & merge)
    │
    ▼
Issue closed on merge
```

#### Step by Step

1. **A maintainer creates or identifies a GitHub Issue**

   When an issue is worth working on, the maintainer:
   - Labels it (e.g. `feedback`, `docs`, `enhancement`)
   - Creates a working branch: `feedback/issue-N-topic` (e.g. `feedback/issue-2-site-template`)
   - Comments on the issue with a link to the branch

   Example issue comment:
   ```
   Working branch: `feedback/issue-2-site-template`
   Feedback doc: docs/ops/feedback/2025-01-22-ns-site-template-feedback.md
   
   Contributors: fork/pull this branch, add your notes as .md files
   in docs/ops/feedback/, and push. See CONTRIBUTING.md for the workflow.
   ```

2. **Contributors work on the branch**

   Fork or pull the working branch. Add a feedback doc at:
   ```
   docs/ops/feedback/YYYY-MM-DD-your-topic.md
   ```

   Every feedback doc should include this reference block at the top:
   ```markdown
   > **GitHub Issue:** [#N — title](https://github.com/2cld/netstack/issues/N)
   > **Working Branch:** `feedback/issue-N-topic`
   > **Contributing:** See [CONTRIBUTING.md](../../../CONTRIBUTING.md)
   ```

   This closes the loop — someone reading the doc finds the issue, someone reading the issue finds the doc.

3. **Iterate with your AI assistant**

   The branch is your sandbox. Work with your AI to:
   - Refine the feedback doc
   - Draft actual doc changes based on the feedback
   - Add `.md` notes with analysis, proposals, or research
   - Validate links and references
   - Break large feedback into discrete items

   AI assistants work best when context is structured and self-contained in markdown files. That's why we keep the substance in `.md` files on the branch rather than in issue comment threads.

4. **Open a PR when ready**

   - PR references the issue: `Closes #N` or `Relates to #N`
   - PR description summarizes the feedback doc
   - Maintainers review the reasoning (feedback doc) and the result (doc changes) together
   - Merge closes the issue automatically (if using `Closes #N`)

#### Feedback Doc Template

```markdown
> **GitHub Issue:** [#N — title](https://github.com/2cld/netstack/issues/N)
> **Working Branch:** `feedback/issue-N-topic`
> **Contributing:** See [CONTRIBUTING.md](../../../CONTRIBUTING.md)

# Feedback: [Your Topic]

**Author:** [your GitHub handle]
**Date:** [YYYY-MM-DD]
**Relates to:** [links to relevant netstack docs sections]
**Site context:** [your deployment if applicable, e.g. "3-site residential federation"]

## Summary
Brief description of what this feedback covers.

## Feedback Items

### Item 1: [Title]
- **Section:** [which part of docs]
- **Type:** question | suggestion | correction | new-content
- **Detail:** [your feedback]
- **Proposed change:** [what you'd like to see, if applicable]

### Item 2: [Title]
...

## Proposed Documentation Changes
If you're also submitting doc changes alongside the feedback,
list them here with file paths.

## Discussion
Open questions or things you'd like maintainer input on
before finalizing.
```

#### Why This Pattern?

- GitHub Issues are the discovery layer — people find the conversation
- The branch is the working layer — people and AIs collaborate on actual content
- Feedback docs give full context in one place — no hunting through issue threads
- AI assistants can read the branch and help draft changes that align with existing docs
- Maintainers review reasoning and results together in the PR
- The feedback doc is a permanent record even after the issue closes

#### Naming Conventions

- Branch: `feedback/issue-N-topic` (e.g. `feedback/issue-2-site-template`)
- Feedback doc: `docs/ops/feedback/YYYY-MM-DD-your-topic.md`
- Keep one primary topic per feedback doc; open separate docs for unrelated items

#### Real Example

See [Issue #2](https://github.com/2cld/netstack/issues/2) and its feedback doc at [docs/ops/feedback/2025-01-22-ns-site-template-feedback.md](docs/ops/feedback/2025-01-22-ns-site-template-feedback.md) for a working example of this process.

### 4. Direct Documentation PRs

If you already know exactly what to change, skip the feedback doc and submit a PR with the changes directly. Reference an issue if one exists.

## Working with AI Assistants

We encourage contributors to use AI assistants (Kiro, Copilot, Claude, ChatGPT, etc.) to help with contributions. To make this work well:

- **Keep docs structured** — consistent headings, tables, and formatting help AI parse context
- **Include links** — reference specific netstack doc sections so AI can follow the thread
- **Use the feedback doc pattern** — it gives your AI the full picture in one file
- **Machine-readable config** — if your contribution involves site data, consider including a `.site-config.yml` so AI can validate consistency

## Repository Structure

```
netstack/
├── CONTRIBUTING.md          ← you are here
├── docs/
│   ├── lan/                 # LAN architecture (ng, sg, cg)
│   │   ├── network/         # Network gateway (ng)
│   │   ├── storage/         # Storage gateway (sg)
│   │   └── compute/         # Compute gateway (cg)
│   ├── wan/                 # External access (tunnels, VPN, DNS)
│   ├── ops/                 # Operations
│   │   ├── backup/          # Backup procedures and scripts
│   │   ├── deployments/     # Site-specific deployments
│   │   │   └── site-template/  # Templates for new sites
│   │   ├── feedback/        # Feedback documents (from PRs)
│   │   ├── monitor/         # Monitoring
│   │   └── tools/           # Operational tools
│   └── portals/             # User-facing services
```

## Style Guide

- Use standard markdown (GitHub-flavored)
- Include `[edit]` links at the top of pages pointing to the GitHub editor
- Use tables for structured data (device inventories, IP assignments, etc.)
- Keep one topic per file
- Use relative links between docs
- Name files with lowercase and hyphens: `my-new-doc.md`

## Questions?

Open an issue or start a feedback branch. We'll figure it out together.
