#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <env-name>" >&2
  exit 1
fi

ENV_NAME="$1"

ssh preview-vps "mkdir -p ~/skaletek-app-v2/${ENV_NAME}"
rsync -az --delete \
  -e "ssh -F $HOME/.ssh/config" \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'frontend/node_modules' \
  --exclude 'traefik/.env' \
  ./ "preview-vps:~/skaletek-app-v2/${ENV_NAME}/"

