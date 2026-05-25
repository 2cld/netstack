# CLI Helper Pattern: Repo Scripts as System Commands

**Applies to:** Any project repo that has automation scripts users run frequently

## Problem

Typing full paths to scripts is tedious and error-prone:
```bash
NODE_PATH=/home/nsadmin/code/nsgctime/node_modules node /home/nsadmin/code/wip/.local/scripts/morning-checkin.js
```

## Solution

1. Create a dispatcher script in the repo
2. Symlink it into `~/.local/bin/` (already on PATH)
3. Use subcommands for different operations

## Structure

```
repo/
├── .local/scripts/
│   ├── wip              ← dispatcher (bash, executable)
│   ├── morning-checkin.js
│   ├── morning-update.js
│   └── create-task-blocks.js
```

## Dispatcher Template

```bash
#!/bin/bash
# <name> — shortcut for <project> scripts
# Usage: <name> <command> [options]

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

case "${1:-help}" in
  command1|alias1)
    node "$SCRIPTS_DIR/script1.js" "${@:2}" ;;
  command2|alias2)
    node "$SCRIPTS_DIR/script2.js" "${@:2}" ;;
  help|*)
    echo "<name> — <description>"
    echo ""
    echo "  <name> command1  (alias1)  Description"
    echo "  <name> command2  (alias2)  Description"
    echo "  <name> help                This message"
    ;;
esac
```

## Installation (one-time per machine)

```bash
# Make executable
chmod +x /path/to/repo/.local/scripts/<name>

# Symlink into PATH
ln -sf /path/to/repo/.local/scripts/<name> ~/.local/bin/<name>
```

Verify: `which <name>` should return `~/.local/bin/<name>`

## Why Symlinks

- **Edits are live** — change the script in the repo, command updates immediately
- **No install step** — no package manager, no rebuild
- **Git-tracked** — the dispatcher is versioned with the repo
- **Portable** — clone repo on new machine, run `ln -sf`, done

## Prerequisites

`~/.local/bin` must be on PATH. Standard on Ubuntu (set in `.profile` or `.bashrc`):
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Conventions

- Dispatcher name = project name (e.g., `wip`, `ns`, `netstack`)
- Short aliases for frequent commands (e.g., `ci` for `checkin`, `up` for `update`)
- `help` is the default (no args = show usage)
- Pass `--apply` through to scripts that follow the [read→propose→apply pattern](./automation-pattern.md)
- Scripts stay in `.local/scripts/` (not committed secrets, but committed automation)

## Live Example: `wip`

```bash
$ wip help
wip — Wip daily command helper

  wip checkin    (ci)   Morning check-in (calendar, email, issues)
  wip update     (up)   Preview README update (--apply to write+commit)
  wip tasks      (tb)   Preview task blocks (--apply to create events)
  wip cron              Run full daily cron
  wip status            Wip orchestrator status
  wip issues            Open issues across repos
  wip help              This message
```

## Adding to a New Repo

1. Create `.local/scripts/<name>` with the dispatcher template
2. `chmod +x .local/scripts/<name>`
3. `ln -sf $(pwd)/.local/scripts/<name> ~/.local/bin/<name>`
4. Add commands as scripts grow

## Related

- [Automation Pattern](./automation-pattern.md) — read→propose→apply for individual scripts
- [Contributor Setup](./contributor-setup.md) — repo access and cloning
- [Repo Private Data](./repo-private-data.md) — keeping secrets out of git
