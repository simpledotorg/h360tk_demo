#!/usr/bin/env bash
set -e

echo "==> Generating SFTP host keys..."
mkdir -p sftp-keys

if [ ! -f sftp-keys/ssh_host_ed25519_key ]; then
  ssh-keygen -t ed25519 -f sftp-keys/ssh_host_ed25519_key -N ""
else
  echo "    ssh_host_ed25519_key already exists, skipping."
fi

if [ ! -f sftp-keys/ssh_host_rsa_key ]; then
  ssh-keygen -t rsa -b 4096 -f sftp-keys/ssh_host_rsa_key -N ""
else
  echo "    ssh_host_rsa_key already exists, skipping."
fi

chmod 600 sftp-keys/ssh_host_ed25519_key sftp-keys/ssh_host_rsa_key

echo ""
echo "==> Setup complete. You can now run:"
echo "    docker compose up -d"
echo ""
echo "    SFTP access: sftp -P 2222 sftpuser@localhost"
