#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <env-name>" >&2
  exit 1
fi

ENV_NAME="$1"

ssh preview-vps "cd ~/simple-app/previews/${ENV_NAME} && COMPOSE_PROJECT_NAME='skalemon-${ENV_NAME}' docker compose -f docker-compose.yml run --rm --no-deps seed"
