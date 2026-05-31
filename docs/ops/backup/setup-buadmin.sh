#!/bin/bash
# setup-buadmin.sh - Create dedicated backup user on Linux nodes
# Run as: root or sudo
# Pattern: https://netstack.org/docs/ops/backup/ssh-rsync-pattern/
#
# Usage: sudo bash setup-buadmin.sh

set -euo pipefail

echo "=== Creating buadmin backup user ==="

# Create user
if id buadmin &>/dev/null; then
  echo "buadmin already exists"
else
  useradd -m -s /bin/bash buadmin
  echo "Created buadmin user"
fi

# Setup .ssh
mkdir -p /home/buadmin/.ssh
chmod 700 /home/buadmin/.ssh

# Generate backup key pair
if [ -f /home/buadmin/.ssh/id_backup ]; then
  echo "Backup key already exists"
else
  ssh-keygen -t ed25519 -f /home/buadmin/.ssh/id_backup -N "" -C "buadmin@$(hostname)"
  echo "Generated backup key"
fi

# Fix ownership
chown -R buadmin:buadmin /home/buadmin/.ssh

# Add to docker group (for backing up Docker volumes)
usermod -aG docker buadmin 2>/dev/null || true

echo ""
echo "=== buadmin setup complete ==="
echo ""
id buadmin
echo ""
echo "Public key (deploy to target nodes):"
cat /home/buadmin/.ssh/id_backup.pub
echo ""
echo "Next steps:"
echo "  1. Deploy public key to sl, wf, cat9fin (see ssh-rsync-pattern.md)"
echo "  2. Test: sudo -u buadmin ssh -i /home/buadmin/.ssh/id_backup buadmin@<target> 'echo ok'"
