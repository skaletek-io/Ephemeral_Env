#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <vps-host> <vps-user> <ssh-private-key>" >&2
  exit 1
fi

VPS_HOST="$1"
VPS_USER="$2"
SSH_PRIVATE_KEY="$3"

mkdir -p "$HOME/.ssh"

SSH_KEY="${SSH_PRIVATE_KEY//$'\r'/}"
SSH_KEY="${SSH_KEY//\\n/$'\n'}"
printf '%s\n' "$SSH_KEY" > "$HOME/.ssh/id_rsa"
chmod 600 "$HOME/.ssh/id_rsa"

grep -q "BEGIN .*PRIVATE KEY" "$HOME/.ssh/id_rsa"
ssh-keygen -y -f "$HOME/.ssh/id_rsa" > /dev/null
ssh-keyscan -H "$VPS_HOST" >> "$HOME/.ssh/known_hosts"
chmod 644 "$HOME/.ssh/known_hosts"

cat > "$HOME/.ssh/config" <<EOF
Host preview-vps
  HostName $VPS_HOST
  User $VPS_USER
  IdentityFile $HOME/.ssh/id_rsa
  IdentitiesOnly yes
  BatchMode yes
  PreferredAuthentications publickey
  PasswordAuthentication no
  ConnectTimeout 10
  StrictHostKeyChecking yes
EOF
chmod 600 "$HOME/.ssh/config"

ssh preview-vps "echo SSH auth ok"
